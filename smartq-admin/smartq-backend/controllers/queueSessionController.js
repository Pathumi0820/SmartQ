import mongoose from "mongoose";

import Department from "../models/Department.js";
import QueueSession from "../models/QueueSession.js";

const queueStatuses = [
  "Scheduled",
  "Active",
  "Closed",
  "Cancelled",
];

const getUserId = (req) =>
  req.user?.id ??
  req.user?._id ??
  "";

const getObjectIdString = (value) => {
  if (!value) {
    return "";
  }

  if (value._id) {
    return value._id.toString();
  }

  return value.toString();
};

const isValidObjectId = (value) =>
  mongoose.Types.ObjectId.isValid(value);

const buildAccessFilter = (req) => {
  const filter = {};

  if (req.user?.role === "hospital_admin") {
    filter.hospital = req.user.hospital;
  }

  if (
    req.user?.role === "department_admin"
  ) {
    filter.department =
      req.user.department;
  }

  if (req.user?.role === "receptionist") {
    filter.hospital = req.user.hospital;
  }

  return filter;
};

const canManageDepartment = (
  req,
  department,
) => {
  const role = req.user?.role;

  if (role === "super_admin") {
    return true;
  }

  if (role === "hospital_admin") {
    return (
      getObjectIdString(
        department.hospital,
      ) ===
      getObjectIdString(
        req.user.hospital,
      )
    );
  }

  if (
    role === "department_admin"
  ) {
    return (
      getObjectIdString(
        department._id,
      ) ===
      getObjectIdString(
        req.user.department,
      )
    );
  }

  return false;
};

const populateQueueSession = (query) =>
  query
    .populate(
      "hospital",
      "name city",
    )
    .populate(
      "department",
      "name prefix hospital",
    )
    .populate(
      "createdBy",
      "fullName email role",
    )
    .populate(
      "startedBy",
      "fullName email role",
    )
    .populate(
      "closedBy",
      "fullName email role",
    )
    .populate(
      "cancelledBy",
      "fullName email role",
    );

const closeExpiredQueueSessions =
  async () => {
    const now = new Date();

    await QueueSession.updateMany(
      {
        status: {
          $in: [
            "Scheduled",
            "Active",
          ],
        },
        endAt: {
          $lt: now,
        },
      },
      {
        $set: {
          status: "Closed",
          closedAt: now,
        },
      },
    );
  };

const findOverlappingQueueSession =
  async ({
    departmentId,
    startAt,
    endAt,
    excludeSessionId = null,
  }) => {
    const filter = {
      department: departmentId,
      status: {
        $in: [
          "Scheduled",
          "Active",
        ],
      },
      startAt: {
        $lt: endAt,
      },
      endAt: {
        $gt: startAt,
      },
    };

    if (excludeSessionId) {
      filter._id = {
        $ne: excludeSessionId,
      };
    }

    return QueueSession.findOne(
      filter,
    ).lean();
  };

/*
|--------------------------------------------------------------------------
| Create Queue Session
|--------------------------------------------------------------------------
*/

export const createQueueSession =
  async (req, res) => {
    try {
      const {
        departmentId,
        startAt,
        endAt,
        maximumTokens,
        notes,
      } = req.body;

      if (
        !departmentId ||
        !isValidObjectId(
          departmentId,
        )
      ) {
        return res.status(400).json({
          message:
            "A valid department ID is required",
        });
      }

      const department =
        await Department.findById(
          departmentId,
        );

      if (!department) {
        return res.status(404).json({
          message:
            "Department not found",
        });
      }

      if (
        !canManageDepartment(
          req,
          department,
        )
      ) {
        return res.status(403).json({
          message:
            "You do not have permission to create a queue for this department",
        });
      }

      const parsedStartAt =
        new Date(startAt);

      const parsedEndAt =
        new Date(endAt);

      if (
        Number.isNaN(
          parsedStartAt.getTime(),
        ) ||
        Number.isNaN(
          parsedEndAt.getTime(),
        )
      ) {
        return res.status(400).json({
          message:
            "Valid queue start and end times are required",
        });
      }

      if (
        parsedEndAt <= parsedStartAt
      ) {
        return res.status(400).json({
          message:
            "Queue end time must be later than the start time",
        });
      }

      if (
        parsedEndAt <= new Date()
      ) {
        return res.status(400).json({
          message:
            "Queue end time must be in the future",
        });
      }

      let normalizedMaximumTokens =
        null;

      if (
        maximumTokens !== undefined &&
        maximumTokens !== null &&
        maximumTokens !== ""
      ) {
        normalizedMaximumTokens =
          Number(maximumTokens);

        if (
          !Number.isInteger(
            normalizedMaximumTokens,
          ) ||
          normalizedMaximumTokens < 1
        ) {
          return res.status(400).json({
            message:
              "Maximum tokens must be a positive whole number",
          });
        }
      }

      await closeExpiredQueueSessions();

      const overlappingSession =
        await findOverlappingQueueSession(
          {
            departmentId,
            startAt:
              parsedStartAt,
            endAt:
              parsedEndAt,
          },
        );

      if (overlappingSession) {
        return res.status(409).json({
          message:
            "Another queue session already exists during this time period",
        });
      }

      const queueSession =
        await QueueSession.create({
          hospital:
            department.hospital,
          department:
            department._id,
          startAt:
            parsedStartAt,
          endAt:
            parsedEndAt,
          status:
            "Scheduled",
          maximumTokens:
            normalizedMaximumTokens,
          issuedTokenCount: 0,
          notes:
            typeof notes === "string"
              ? notes.trim()
              : "",
          createdBy:
            getUserId(req),
        });

      const populatedSession =
        await populateQueueSession(
          QueueSession.findById(
            queueSession._id,
          ),
        );

      return res.status(201).json({
        message:
          "Queue session created successfully",
        queueSession:
          populatedSession,
      });
    } catch (error) {
      console.error(
        "Queue session creation error:",
        error,
      );

      return res.status(500).json({
        message:
          error.message ||
          "Failed to create queue session",
      });
    }
  };

/*
|--------------------------------------------------------------------------
| Get Queue Sessions
|--------------------------------------------------------------------------
*/

export const getQueueSessions =
  async (req, res) => {
    try {
      await closeExpiredQueueSessions();

      const filter = {
        ...buildAccessFilter(req),
      };

      const {
        hospitalId,
        departmentId,
        status,
        from,
        to,
      } = req.query;

      if (hospitalId) {
        if (
          !isValidObjectId(
            hospitalId,
          )
        ) {
          return res.status(400).json({
            message:
              "Invalid hospital ID",
          });
        }

        filter.hospital =
          hospitalId;
      }

      if (departmentId) {
        if (
          !isValidObjectId(
            departmentId,
          )
        ) {
          return res.status(400).json({
            message:
              "Invalid department ID",
          });
        }

        filter.department =
          departmentId;
      }

      if (status) {
        if (
          !queueStatuses.includes(
            status,
          )
        ) {
          return res.status(400).json({
            message:
              "Invalid queue status",
          });
        }

        filter.status = status;
      }

      if (from || to) {
        filter.startAt = {};

        if (from) {
          const fromDate =
            new Date(from);

          if (
            Number.isNaN(
              fromDate.getTime(),
            )
          ) {
            return res.status(400).json({
              message:
                "Invalid from date",
            });
          }

          filter.startAt.$gte =
            fromDate;
        }

        if (to) {
          const toDate =
            new Date(to);

          if (
            Number.isNaN(
              toDate.getTime(),
            )
          ) {
            return res.status(400).json({
              message:
                "Invalid to date",
            });
          }

          filter.startAt.$lte =
            toDate;
        }
      }

      const queueSessions =
        await populateQueueSession(
          QueueSession.find(filter)
            .sort({
              startAt: -1,
              createdAt: -1,
            }),
        );

      return res.json(
        queueSessions,
      );
    } catch (error) {
      console.error(
        "Queue session loading error:",
        error,
      );

      return res.status(500).json({
        message:
          error.message ||
          "Failed to load queue sessions",
      });
    }
  };

/*
|--------------------------------------------------------------------------
| Get Queue Session By ID
|--------------------------------------------------------------------------
*/

export const getQueueSessionById =
  async (req, res) => {
    try {
      const { id } = req.params;

      if (
        !isValidObjectId(id)
      ) {
        return res.status(400).json({
          message:
            "Invalid queue session ID",
        });
      }

      await closeExpiredQueueSessions();

      const queueSession =
        await populateQueueSession(
          QueueSession.findOne({
            _id: id,
            ...buildAccessFilter(req),
          }),
        );

      if (!queueSession) {
        return res.status(404).json({
          message:
            "Queue session not found or access denied",
        });
      }

      return res.json(
        queueSession,
      );
    } catch (error) {
      console.error(
        "Queue session loading error:",
        error,
      );

      return res.status(500).json({
        message:
          error.message ||
          "Failed to load queue session",
      });
    }
  };

/*
|--------------------------------------------------------------------------
| Get Active Queue Session
|--------------------------------------------------------------------------
*/

export const getActiveQueueSession =
  async (req, res) => {
    try {
      const {
        departmentId,
      } = req.params;

      if (
        !isValidObjectId(
          departmentId,
        )
      ) {
        return res.status(400).json({
          message:
            "Invalid department ID",
        });
      }

      await closeExpiredQueueSessions();

      const now = new Date();

      const queueSession =
        await populateQueueSession(
          QueueSession.findOne({
            department:
              departmentId,
            status: "Active",
            startAt: {
              $lte: now,
            },
            endAt: {
              $gte: now,
            },
          }).sort({
            startAt: -1,
          }),
        );

      if (!queueSession) {
        return res.status(404).json({
          message:
            "No active queue session found",
        });
      }

      const tokenLimitReached =
        queueSession.maximumTokens !=
          null &&
        queueSession.issuedTokenCount >=
          queueSession.maximumTokens;

      return res.json({
        ...queueSession.toObject(),
        canIssueToken:
          !tokenLimitReached,
        remainingTokens:
          queueSession.maximumTokens ==
          null
            ? null
            : Math.max(
                queueSession
                  .maximumTokens -
                  queueSession
                    .issuedTokenCount,
                0,
              ),
      });
    } catch (error) {
      console.error(
        "Active queue session loading error:",
        error,
      );

      return res.status(500).json({
        message:
          error.message ||
          "Failed to load active queue session",
      });
    }
  };

/*
|--------------------------------------------------------------------------
| Start Queue Session
|--------------------------------------------------------------------------
*/

export const startQueueSession =
  async (req, res) => {
    try {
      const { id } = req.params;

      if (
        !isValidObjectId(id)
      ) {
        return res.status(400).json({
          message:
            "Invalid queue session ID",
        });
      }

      await closeExpiredQueueSessions();

      const queueSession =
        await QueueSession.findOne({
          _id: id,
          ...buildAccessFilter(req),
        });

      if (!queueSession) {
        return res.status(404).json({
          message:
            "Queue session not found or access denied",
        });
      }

      if (
        queueSession.status ===
        "Active"
      ) {
        return res.status(400).json({
          message:
            "Queue session is already active",
        });
      }

      if (
        queueSession.status ===
          "Closed" ||
        queueSession.status ===
          "Cancelled"
      ) {
        return res.status(400).json({
          message:
            `A ${queueSession.status.toLowerCase()} queue cannot be started`,
        });
      }

      const now = new Date();

      if (
        now < queueSession.startAt
      ) {
        return res.status(400).json({
          message:
            "Queue cannot be started before its scheduled start time",
        });
      }

      if (
        now > queueSession.endAt
      ) {
        queueSession.status =
          "Closed";
        queueSession.closedAt =
          now;

        await queueSession.save();

        return res.status(400).json({
          message:
            "Queue session has already expired",
        });
      }

      const anotherActiveQueue =
        await QueueSession.findOne({
          _id: {
            $ne:
              queueSession._id,
          },
          department:
            queueSession.department,
          status: "Active",
          startAt: {
            $lte: now,
          },
          endAt: {
            $gte: now,
          },
        }).lean();

      if (anotherActiveQueue) {
        return res.status(409).json({
          message:
            "Another queue session is already active for this department",
        });
      }

      queueSession.status =
        "Active";
      queueSession.startedAt =
        now;
      queueSession.startedBy =
        getUserId(req);

      await queueSession.save();

      const populatedSession =
        await populateQueueSession(
          QueueSession.findById(
            queueSession._id,
          ),
        );

      return res.json({
        message:
          "Queue session started successfully",
        queueSession:
          populatedSession,
      });
    } catch (error) {
      console.error(
        "Queue session start error:",
        error,
      );

      return res.status(500).json({
        message:
          error.message ||
          "Failed to start queue session",
      });
    }
  };

/*
|--------------------------------------------------------------------------
| Close Queue Session
|--------------------------------------------------------------------------
*/

export const closeQueueSession =
  async (req, res) => {
    try {
      const { id } = req.params;

      if (
        !isValidObjectId(id)
      ) {
        return res.status(400).json({
          message:
            "Invalid queue session ID",
        });
      }

      const queueSession =
        await QueueSession.findOne({
          _id: id,
          ...buildAccessFilter(req),
        });

      if (!queueSession) {
        return res.status(404).json({
          message:
            "Queue session not found or access denied",
        });
      }

      if (
        queueSession.status ===
        "Closed"
      ) {
        return res.status(400).json({
          message:
            "Queue session is already closed",
        });
      }

      if (
        queueSession.status ===
        "Cancelled"
      ) {
        return res.status(400).json({
          message:
            "A cancelled queue cannot be closed",
        });
      }

      queueSession.status =
        "Closed";
      queueSession.closedAt =
        new Date();
      queueSession.closedBy =
        getUserId(req);

      await queueSession.save();

      const populatedSession =
        await populateQueueSession(
          QueueSession.findById(
            queueSession._id,
          ),
        );

      return res.json({
        message:
          "Queue session closed successfully",
        queueSession:
          populatedSession,
      });
    } catch (error) {
      console.error(
        "Queue session close error:",
        error,
      );

      return res.status(500).json({
        message:
          error.message ||
          "Failed to close queue session",
      });
    }
  };

/*
|--------------------------------------------------------------------------
| Cancel Queue Session
|--------------------------------------------------------------------------
*/

export const cancelQueueSession =
  async (req, res) => {
    try {
      const { id } = req.params;

      if (
        !isValidObjectId(id)
      ) {
        return res.status(400).json({
          message:
            "Invalid queue session ID",
        });
      }

      const queueSession =
        await QueueSession.findOne({
          _id: id,
          ...buildAccessFilter(req),
        });

      if (!queueSession) {
        return res.status(404).json({
          message:
            "Queue session not found or access denied",
        });
      }

      if (
        queueSession.status ===
        "Cancelled"
      ) {
        return res.status(400).json({
          message:
            "Queue session is already cancelled",
        });
      }

      if (
        queueSession.status ===
        "Closed"
      ) {
        return res.status(400).json({
          message:
            "A closed queue cannot be cancelled",
        });
      }

      queueSession.status =
        "Cancelled";
      queueSession.cancelledAt =
        new Date();
      queueSession.cancelledBy =
        getUserId(req);

      await queueSession.save();

      const populatedSession =
        await populateQueueSession(
          QueueSession.findById(
            queueSession._id,
          ),
        );

      return res.json({
        message:
          "Queue session cancelled successfully",
        queueSession:
          populatedSession,
      });
    } catch (error) {
      console.error(
        "Queue session cancellation error:",
        error,
      );

      return res.status(500).json({
        message:
          error.message ||
          "Failed to cancel queue session",
      });
    }
  };