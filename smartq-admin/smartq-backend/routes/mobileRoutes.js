import express from "express";
import mongoose from "mongoose";

import Department from "../models/Department.js";
import Hospital from "../models/Hospital.js";
import MobileUser from "../models/MobileUser.js";
import QueueSession from "../models/QueueSession.js";
import Token from "../models/Token.js";

import {
  verifyFirebaseToken,
} from "../middleware/firebaseAuth.js";

const router = express.Router();

const activeStatuses = [
  "Waiting",
  "Called",
  "Serving",
];

const averageServiceMinutes = 10;

/*
|--------------------------------------------------------------------------
| General Helpers
|--------------------------------------------------------------------------
*/

const buildTokenCode = (token) =>
  `${token.prefix}${String(
    token.tokenNumber,
  ).padStart(3, "0")}`;

const getObjectIdString = (value) => {
  if (!value) {
    return "";
  }

  if (value._id) {
    return value._id.toString();
  }

  return value.toString();
};

const getTodayRange = () => {
  const startOfDay = new Date();
  startOfDay.setHours(0, 0, 0, 0);

  const endOfDay = new Date();
  endOfDay.setHours(23, 59, 59, 999);

  return {
    startOfDay,
    endOfDay,
  };
};

const getAuthenticatedProfile = async (
  req,
) =>
  MobileUser.findOne({
    firebaseUid:
      req.firebaseUser.uid,
  });

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

const findAvailableActiveQueueSession =
  async (departmentId) => {
    await closeExpiredQueueSessions();

    const now = new Date();

    return QueueSession.findOne({
      department: departmentId,
      status: "Active",
      startAt: {
        $lte: now,
      },
      endAt: {
        $gte: now,
      },
      $expr: {
        $or: [
          {
            $eq: [
              "$maximumTokens",
              null,
            ],
          },
          {
            $lt: [
              "$issuedTokenCount",
              "$maximumTokens",
            ],
          },
        ],
      },
    }).sort({
      startAt: -1,
      createdAt: -1,
    });
  };

const reserveQueueTokenSlot =
  async (queueSessionId) => {
    const now = new Date();

    return QueueSession.findOneAndUpdate(
      {
        _id: queueSessionId,
        status: "Active",
        startAt: {
          $lte: now,
        },
        endAt: {
          $gte: now,
        },
        $expr: {
          $or: [
            {
              $eq: [
                "$maximumTokens",
                null,
              ],
            },
            {
              $lt: [
                "$issuedTokenCount",
                "$maximumTokens",
              ],
            },
          ],
        },
      },
      {
        $inc: {
          issuedTokenCount: 1,
        },
      },
      {
        returnDocument: "after",
        runValidators: true,
      },
    );
  };

const releaseQueueTokenSlot =
  async (queueSessionId) => {
    if (!queueSessionId) {
      return;
    }

    try {
      await QueueSession.updateOne(
        {
          _id: queueSessionId,
          issuedTokenCount: {
            $gt: 0,
          },
        },
        {
          $inc: {
            issuedTokenCount: -1,
          },
        },
      );
    } catch (error) {
      console.error(
        "Failed to release queue token slot:",
        error,
      );
    }
  };

/*
|--------------------------------------------------------------------------
| Queue Calculation
|--------------------------------------------------------------------------
*/

const getCurrentQueueToken = async (
  departmentId,
) => {
  const {
    startOfDay,
    endOfDay,
  } = getTodayRange();

  let currentToken =
    await Token.findOne({
      department: departmentId,
      status: "Serving",
      createdAt: {
        $gte: startOfDay,
        $lte: endOfDay,
      },
    })
      .sort({
        tokenNumber: 1,
        createdAt: 1,
      })
      .lean();

  if (!currentToken) {
    currentToken =
      await Token.findOne({
        department: departmentId,
        status: "Called",
        createdAt: {
          $gte: startOfDay,
          $lte: endOfDay,
        },
      })
        .sort({
          tokenNumber: 1,
          createdAt: 1,
        })
        .lean();
  }

  return currentToken;
};

const calculateQueueInformation =
  async (token) => {
    const departmentId =
      getObjectIdString(
        token.department,
      );

    if (!departmentId) {
      return {
        currentQueue: 0,
        peopleAhead: 0,
        estimatedMinutes: 0,
        estimatedTime: "--",
      };
    }

    const {
      startOfDay,
      endOfDay,
    } = getTodayRange();

    const currentQueueToken =
      await getCurrentQueueToken(
        departmentId,
      );

    const currentQueue =
      currentQueueToken?.tokenNumber ??
      0;

    let peopleAhead = 0;

    if (
      token.status === "Waiting"
    ) {
      peopleAhead =
        await Token.countDocuments({
          department:
            departmentId,
          _id: {
            $ne: token._id,
          },
          tokenNumber: {
            $lt:
              token.tokenNumber,
          },
          status: {
            $in: activeStatuses,
          },
          createdAt: {
            $gte: startOfDay,
            $lte: endOfDay,
          },
        });
    }

    if (
      token.status === "Called" ||
      token.status === "Serving" ||
      token.status === "Completed" ||
      token.status === "Cancelled"
    ) {
      peopleAhead = 0;
    }

    const estimatedMinutes =
      peopleAhead *
      averageServiceMinutes;

    let estimatedTime =
      `${estimatedMinutes} min`;

    if (
      token.status === "Serving"
    ) {
      estimatedTime = "Now";
    } else if (
      token.status === "Called"
    ) {
      estimatedTime =
        "Please proceed";
    } else if (
      token.status === "Completed"
    ) {
      estimatedTime =
        "Completed";
    } else if (
      token.status === "Cancelled"
    ) {
      estimatedTime =
        "Cancelled";
    } else if (
      peopleAhead === 0
    ) {
      estimatedTime = "Next";
    }

    return {
      currentQueue,
      peopleAhead,
      estimatedMinutes,
      estimatedTime,
    };
  };

const buildTokenPayload = async (
  token,
) => {
  const queueInformation =
    await calculateQueueInformation(
      token,
    );

  return {
    tokenId:
      token._id.toString(),
    tokenCode:
      buildTokenCode(token),
    patientName:
      token.patientName,
    patientPhone:
      token.patientPhone,
    hospitalId:
      getObjectIdString(
        token.hospital,
      ),
    departmentId:
      getObjectIdString(
        token.department,
      ),
    queueSessionId:
      getObjectIdString(
        token.queueSession,
      ),
    status:
      token.status,
    currentQueue:
      queueInformation.currentQueue,
    peopleAhead:
      queueInformation.peopleAhead,
    estimatedMinutes:
      queueInformation
        .estimatedMinutes,
    estimatedTime:
      queueInformation.estimatedTime,
    createdAt:
      token.createdAt,
    updatedAt:
      token.updatedAt,
  };
};

/*
|--------------------------------------------------------------------------
| Socket.IO Helpers
|--------------------------------------------------------------------------
*/

const emitTokenUpdate = async (
  req,
  token,
) => {
  const io =
    req.app.get("io");

  if (!io || !token) {
    return;
  }

  const payload =
    await buildTokenPayload(
      token,
    );

  io.to(
    `token:${payload.tokenId}`,
  ).emit(
    "tokenUpdated",
    payload,
  );

  if (
    payload.departmentId
  ) {
    io.to(
      `department:${payload.departmentId}`,
    ).emit(
      "queueUpdated",
      payload,
    );
  }

  console.log(
    "Mobile token update emitted:",
    payload,
  );
};

const emitDepartmentQueueUpdates =
  async (
    req,
    departmentId,
  ) => {
    const io =
      req.app.get("io");

    if (
      !io ||
      !departmentId
    ) {
      return;
    }

    const normalizedDepartmentId =
      departmentId.toString();

    const {
      startOfDay,
      endOfDay,
    } = getTodayRange();

    const tokens =
      await Token.find({
        department:
          normalizedDepartmentId,
        status: {
          $in: activeStatuses,
        },
        createdAt: {
          $gte: startOfDay,
          $lte: endOfDay,
        },
      }).sort({
        tokenNumber: 1,
        createdAt: 1,
      });

    const tokenPayloads = [];

    for (
      const queueToken of tokens
    ) {
      const payload =
        await buildTokenPayload(
          queueToken,
        );

      tokenPayloads.push(
        payload,
      );

      io.to(
        `token:${payload.tokenId}`,
      ).emit(
        "tokenUpdated",
        payload,
      );
    }

    const servingToken =
      tokenPayloads.find(
        (item) =>
          item.status ===
          "Serving",
      ) ??
      tokenPayloads.find(
        (item) =>
          item.status ===
          "Called",
      );

    io.to(
      `department:${normalizedDepartmentId}`,
    ).emit(
      "queueUpdated",
      {
        departmentId:
          normalizedDepartmentId,
        currentQueue:
          servingToken
            ?.currentQueue ?? 0,
        activeTokenCount:
          tokenPayloads.length,
        updatedAt:
          new Date(),
      },
    );

    console.log(
      `Mobile department queue updated: ${normalizedDepartmentId}`,
    );
  };

/*
|--------------------------------------------------------------------------
| Hospitals
|--------------------------------------------------------------------------
*/

router.get(
  "/hospitals",
  async (req, res) => {
    try {
      const hospitals =
        await Hospital.find()
          .sort({
            name: 1,
          })
          .lean();

      return res.json(
        hospitals,
      );
    } catch (error) {
      console.error(
        "Hospital loading error:",
        error,
      );

      return res.status(500).json({
        message:
          error.message ||
          "Failed to load hospitals",
      });
    }
  },
);

/*
|--------------------------------------------------------------------------
| Departments
|--------------------------------------------------------------------------
*/

router.get(
  "/departments/:hospitalId",
  async (req, res) => {
    try {
      const {
        hospitalId,
      } = req.params;

      if (
        !mongoose.Types.ObjectId
          .isValid(hospitalId)
      ) {
        return res.status(400).json({
          message:
            "Invalid hospital ID",
        });
      }

      const hospital =
        await Hospital.findById(
          hospitalId,
        ).lean();

      if (!hospital) {
        return res.status(404).json({
          message:
            "Hospital not found",
        });
      }

      const departments =
        await Department.find({
          hospital: hospitalId,
        })
          .sort({
            name: 1,
          })
          .lean();

      return res.json(
        departments,
      );
    } catch (error) {
      console.error(
        "Department loading error:",
        error,
      );

      return res.status(500).json({
        message:
          error.message ||
          "Failed to load departments",
      });
    }
  },
);

/*
|--------------------------------------------------------------------------
| Get Department Queue Availability
|--------------------------------------------------------------------------
*/

router.get(
  "/departments/:departmentId/queue",
  async (req, res) => {
    try {
      const {
        departmentId,
      } = req.params;

      if (
        !mongoose.Types.ObjectId
          .isValid(departmentId)
      ) {
        return res.status(400).json({
          message:
            "Invalid department ID",
        });
      }

      const department =
        await Department.findById(
          departmentId,
        )
          .populate(
            "hospital",
            "name city",
          )
          .lean();

      if (!department) {
        return res.status(404).json({
          message:
            "Department not found",
        });
      }

      await closeExpiredQueueSessions();

      const now = new Date();

      const activeQueue =
        await QueueSession.findOne({
          department:
            departmentId,
          status: "Active",
          startAt: {
            $lte: now,
          },
          endAt: {
            $gte: now,
          },
        })
          .sort({
            startAt: -1,
          })
          .lean();

      if (!activeQueue) {
        const upcomingQueue =
          await QueueSession.findOne({
            department:
              departmentId,
            status: "Scheduled",
            startAt: {
              $gt: now,
            },
          })
            .sort({
              startAt: 1,
            })
            .lean();

        return res.json({
          isOpen: false,
          canIssueToken: false,
          status:
            upcomingQueue
              ? "Scheduled"
              : "Closed",
          message:
            upcomingQueue
              ? "The queue has not started yet"
              : "Token issuing is currently closed for this department",
          departmentId,
          departmentName:
            department.name ?? "",
          hospitalId:
            getObjectIdString(
              department.hospital,
            ),
          hospitalName:
            department.hospital
              ?.name ?? "",
          startAt:
            upcomingQueue
              ?.startAt ?? null,
          endAt:
            upcomingQueue
              ?.endAt ?? null,
          maximumTokens:
            upcomingQueue
              ?.maximumTokens ??
            null,
          issuedTokenCount:
            upcomingQueue
              ?.issuedTokenCount ??
            0,
          remainingTokens:
            upcomingQueue
              ?.maximumTokens ==
            null
              ? null
              : Math.max(
                  upcomingQueue
                    .maximumTokens -
                    upcomingQueue
                      .issuedTokenCount,
                  0,
                ),
        });
      }

      const tokenLimitReached =
        activeQueue.maximumTokens !=
          null &&
        activeQueue.issuedTokenCount >=
          activeQueue.maximumTokens;

      return res.json({
        isOpen:
          !tokenLimitReached,
        canIssueToken:
          !tokenLimitReached,
        status:
          tokenLimitReached
            ? "Full"
            : activeQueue.status,
        message:
          tokenLimitReached
            ? "The maximum token limit has been reached"
            : "The queue is currently accepting tokens",
        queueSessionId:
          activeQueue._id,
        departmentId,
        departmentName:
          department.name ?? "",
        hospitalId:
          getObjectIdString(
            department.hospital,
          ),
        hospitalName:
          department.hospital
            ?.name ?? "",
        startAt:
          activeQueue.startAt,
        endAt:
          activeQueue.endAt,
        maximumTokens:
          activeQueue.maximumTokens,
        issuedTokenCount:
          activeQueue
            .issuedTokenCount,
        remainingTokens:
          activeQueue
            .maximumTokens == null
            ? null
            : Math.max(
                activeQueue
                  .maximumTokens -
                  activeQueue
                    .issuedTokenCount,
                0,
              ),
      });
    } catch (error) {
      console.error(
        "Queue availability error:",
        error,
      );

      return res.status(500).json({
        message:
          error.message ||
          "Failed to load queue availability",
      });
    }
  },
);

/*
|--------------------------------------------------------------------------
| Create Mobile Token
|--------------------------------------------------------------------------
*/

router.post(
  "/tokens",
  verifyFirebaseToken,
  async (req, res) => {
    let reservedQueueSessionId =
      null;

    try {
      const {
        patientName,
        patientPhone,
        hospital,
        department,
      } = req.body;

      const normalizedName =
        typeof patientName ===
        "string"
          ? patientName.trim()
          : "";

      const normalizedPhone =
        typeof patientPhone ===
        "string"
          ? patientPhone.trim()
          : "";

      if (
        !normalizedName ||
        !normalizedPhone ||
        !hospital ||
        !department
      ) {
        return res.status(400).json({
          message:
            "Patient name, phone, hospital and department are required",
        });
      }

      if (
        !mongoose.Types.ObjectId
          .isValid(hospital) ||
        !mongoose.Types.ObjectId
          .isValid(department)
      ) {
        return res.status(400).json({
          message:
            "Invalid hospital or department ID",
        });
      }

      const profile =
        await getAuthenticatedProfile(
          req,
        );

      if (!profile) {
        return res.status(404).json({
          message:
            "MongoDB profile not found",
        });
      }

      if (
        profile.phone?.trim() !==
        normalizedPhone
      ) {
        return res.status(403).json({
          message:
            "The token phone number must match your profile",
        });
      }

      const existingActiveToken =
        await Token.findOne({
          patientPhone:
            normalizedPhone,
          status: {
            $in: activeStatuses,
          },
        })
          .select(
            "_id tokenNumber prefix status",
          )
          .lean();

      if (existingActiveToken) {
        return res.status(409).json({
          message:
            "You already have an active queue token",
          tokenId:
            existingActiveToken._id,
          tokenCode:
            buildTokenCode(
              existingActiveToken,
            ),
          status:
            existingActiveToken.status,
        });
      }

      const selectedHospital =
        await Hospital.findById(
          hospital,
        );

      if (!selectedHospital) {
        return res.status(404).json({
          message:
            "Hospital not found",
        });
      }

      const selectedDepartment =
        await Department.findOne({
          _id: department,
          hospital,
        });

      if (!selectedDepartment) {
        return res.status(404).json({
          message:
            "Department not found for the selected hospital",
        });
      }

      if (
        !selectedDepartment.prefix
          ?.trim()
      ) {
        return res.status(400).json({
          message:
            "The selected department does not have a token prefix",
        });
      }

      /*
      |--------------------------------------------------------------------------
      | Check Queue Session
      |--------------------------------------------------------------------------
      */

      const availableQueue =
        await findAvailableActiveQueueSession(
          department,
        );

      if (!availableQueue) {
        const now = new Date();

        const scheduledQueue =
          await QueueSession.findOne({
            department,
            status: "Scheduled",
            startAt: {
              $gt: now,
            },
          })
            .sort({
              startAt: 1,
            })
            .lean();

        return res.status(403).json({
          code:
            scheduledQueue
              ? "QUEUE_NOT_STARTED"
              : "QUEUE_CLOSED",
          message:
            scheduledQueue
              ? "The queue has not started yet"
              : "Token issuing is currently closed for this department",
          startAt:
            scheduledQueue
              ?.startAt ?? null,
          endAt:
            scheduledQueue
              ?.endAt ?? null,
        });
      }

      const reservedQueue =
        await reserveQueueTokenSlot(
          availableQueue._id,
        );

      if (!reservedQueue) {
        return res.status(409).json({
          code:
            "QUEUE_FULL_OR_CLOSED",
          message:
            "The queue is closed or the maximum token limit has been reached",
        });
      }

      reservedQueueSessionId =
        reservedQueue._id;

      /*
      |--------------------------------------------------------------------------
      | Generate Token Number
      |--------------------------------------------------------------------------
      */

      const lastToken =
        await Token.findOne({
          queueSession:
            reservedQueue._id,
          department,
        })
          .sort({
            tokenNumber: -1,
          })
          .select(
            "tokenNumber",
          )
          .lean();

      const nextTokenNumber =
        (lastToken?.tokenNumber ??
          0) + 1;

      /*
      |--------------------------------------------------------------------------
      | Create Token
      |--------------------------------------------------------------------------
      */

      const token =
        await Token.create({
          tokenNumber:
            nextTokenNumber,
          prefix:
            selectedDepartment
              .prefix
              .trim(),
          patientName:
            normalizedName,
          patientPhone:
            normalizedPhone,
          hospital,
          department,
          queueSession:
            reservedQueue._id,
          status:
            "Waiting",
        });

      reservedQueueSessionId =
        null;

      const payload =
        await buildTokenPayload(
          token,
        );

      await emitDepartmentQueueUpdates(
        req,
        department,
      );

      return res.status(201).json({
        message:
          "Token created successfully",
        tokenCode:
          buildTokenCode(token),
        token,
        queueSession: {
          id:
            reservedQueue._id,
          startAt:
            reservedQueue.startAt,
          endAt:
            reservedQueue.endAt,
          maximumTokens:
            reservedQueue
              .maximumTokens,
          issuedTokenCount:
            reservedQueue
              .issuedTokenCount,
          remainingTokens:
            reservedQueue
              .maximumTokens == null
              ? null
              : Math.max(
                  reservedQueue
                    .maximumTokens -
                    reservedQueue
                      .issuedTokenCount,
                  0,
                ),
        },
        currentQueue:
          payload.currentQueue,
        peopleAhead:
          payload.peopleAhead,
        estimatedMinutes:
          payload.estimatedMinutes,
        estimatedTime:
          payload.estimatedTime,
      });
    } catch (error) {
      if (
        reservedQueueSessionId
      ) {
        await releaseQueueTokenSlot(
          reservedQueueSessionId,
        );
      }

      console.error(
        "Token creation error:",
        error,
      );

      return res.status(500).json({
        message:
          error.message ||
          "Failed to create token",
      });
    }
  },
);

/*
|--------------------------------------------------------------------------
| Get Active Token
|--------------------------------------------------------------------------
*/

router.get(
  "/tokens/active",
  verifyFirebaseToken,
  async (req, res) => {
    try {
      const profile =
        await getAuthenticatedProfile(
          req,
        );

      if (!profile) {
        return res.status(404).json({
          message:
            "MongoDB profile not found",
        });
      }

      const phone =
        profile.phone?.trim() ?? "";

      if (!phone) {
        return res.status(400).json({
          message:
            "Phone number is missing from profile",
        });
      }

      const token =
        await Token.findOne({
          patientPhone: phone,
          status: {
            $in: activeStatuses,
          },
        })
          .populate(
            "hospital",
            "name city",
          )
          .populate(
            "department",
            "name prefix",
          )
          .populate(
            "queueSession",
            "startAt endAt status maximumTokens issuedTokenCount",
          )
          .sort({
            createdAt: -1,
          });

      if (!token) {
        return res.status(404).json({
          message:
            "No active token found",
        });
      }

      const queueInformation =
        await calculateQueueInformation(
          token,
        );

      return res.json({
        id:
          token._id,
        tokenCode:
          buildTokenCode(token),
        patientName:
          token.patientName,
        patientPhone:
          token.patientPhone,
        hospitalId:
          token.hospital?._id ?? "",
        hospitalName:
          token.hospital?.name ?? "",
        departmentId:
          token.department?._id ?? "",
        departmentName:
          token.department?.name ?? "",
        queueSessionId:
          token.queueSession?._id ??
          "",
        queueStartAt:
          token.queueSession
            ?.startAt ?? null,
        queueEndAt:
          token.queueSession
            ?.endAt ?? null,
        status:
          token.status,
        currentQueue:
          queueInformation.currentQueue,
        peopleAhead:
          queueInformation.peopleAhead,
        estimatedMinutes:
          queueInformation
            .estimatedMinutes,
        estimatedTime:
          queueInformation.estimatedTime,
        createdAt:
          token.createdAt,
        updatedAt:
          token.updatedAt,
      });
    } catch (error) {
      console.error(
        "Active token loading error:",
        error,
      );

      return res.status(500).json({
        message:
          error.message ||
          "Failed to load active token",
      });
    }
  },
);

/*
|--------------------------------------------------------------------------
| Token History
|--------------------------------------------------------------------------
*/

router.get(
  "/tokens/phone/:phone",
  verifyFirebaseToken,
  async (req, res) => {
    try {
      const phone =
        decodeURIComponent(
          req.params.phone,
        ).trim();

      if (!phone) {
        return res.status(400).json({
          message:
            "Phone number is required",
        });
      }

      const profile =
        await getAuthenticatedProfile(
          req,
        );

      if (!profile) {
        return res.status(404).json({
          message:
            "MongoDB profile not found",
        });
      }

      if (
        !profile.phone ||
        profile.phone.trim() !==
          phone
      ) {
        return res.status(403).json({
          message:
            "You can only access your own token history",
        });
      }

      const tokens =
        await Token.find({
          patientPhone:
            phone,
        })
          .populate(
            "hospital",
            "name city",
          )
          .populate(
            "department",
            "name prefix",
          )
          .populate(
            "queueSession",
            "startAt endAt status",
          )
          .sort({
            createdAt: -1,
          });

      const formattedTokens =
        await Promise.all(
          tokens.map(
            async (token) => {
              const queueInformation =
                await calculateQueueInformation(
                  token,
                );

              return {
                id:
                  token._id,
                tokenCode:
                  buildTokenCode(
                    token,
                  ),
                patientName:
                  token.patientName,
                patientPhone:
                  token.patientPhone,
                hospital:
                  token.hospital
                    ?.name ?? "",
                hospitalId:
                  token.hospital
                    ?._id ?? "",
                department:
                  token.department
                    ?.name ?? "",
                departmentId:
                  token.department
                    ?._id ?? "",
                queueSessionId:
                  token.queueSession
                    ?._id ?? "",
                queueStartAt:
                  token.queueSession
                    ?.startAt ?? null,
                queueEndAt:
                  token.queueSession
                    ?.endAt ?? null,
                status:
                  token.status,
                currentQueue:
                  queueInformation
                    .currentQueue,
                peopleAhead:
                  queueInformation
                    .peopleAhead,
                estimatedMinutes:
                  queueInformation
                    .estimatedMinutes,
                estimatedTime:
                  queueInformation
                    .estimatedTime,
                createdAt:
                  token.createdAt,
                updatedAt:
                  token.updatedAt,
              };
            },
          ),
        );

      return res.json(
        formattedTokens,
      );
    } catch (error) {
      console.error(
        "Token history error:",
        error,
      );

      return res.status(500).json({
        message:
          error.message ||
          "Failed to load token history",
      });
    }
  },
);

/*
|--------------------------------------------------------------------------
| Cancel Mobile Token
|--------------------------------------------------------------------------
*/

router.put(
  "/tokens/:id/status",
  verifyFirebaseToken,
  async (req, res) => {
    try {
      const {
        id,
      } = req.params;

      const requestedStatus =
        req.body.status
          ?.toString()
          .trim() ?? "";

      if (
        !mongoose.Types.ObjectId
          .isValid(id)
      ) {
        return res.status(400).json({
          message:
            "Invalid token ID",
        });
      }

      if (
        requestedStatus !==
        "Cancelled"
      ) {
        return res.status(400).json({
          message:
            "Mobile users can only cancel a token",
        });
      }

      const profile =
        await getAuthenticatedProfile(
          req,
        );

      if (!profile) {
        return res.status(404).json({
          message:
            "MongoDB profile not found",
        });
      }

      const token =
        await Token.findOne({
          _id: id,
          patientPhone:
            profile.phone
              ?.trim() ?? "",
        });

      if (!token) {
        return res.status(404).json({
          message:
            "Token not found or access denied",
        });
      }

      if (
        token.status ===
          "Completed" ||
        token.status ===
          "Cancelled"
      ) {
        return res.status(400).json({
          message:
            `Token is already ${token.status.toLowerCase()}`,
        });
      }

      token.status =
        "Cancelled";

      await token.save();

      await emitTokenUpdate(
        req,
        token,
      );

      await emitDepartmentQueueUpdates(
        req,
        getObjectIdString(
          token.department,
        ),
      );

      const queueInformation =
        await calculateQueueInformation(
          token,
        );

      return res.json({
        message:
          "Token cancelled successfully",
        token,
        ...queueInformation,
      });
    } catch (error) {
      console.error(
        "Token cancellation error:",
        error,
      );

      return res.status(500).json({
        message:
          error.message ||
          "Failed to cancel token",
      });
    }
  },
);

/*
|--------------------------------------------------------------------------
| Synchronize Firebase User with MongoDB
|--------------------------------------------------------------------------
*/

router.post(
  "/profile/sync",
  verifyFirebaseToken,
  async (req, res) => {
    try {
      const firebaseUser =
        req.firebaseUser;

      const existingUser =
        await MobileUser.findOne({
          firebaseUid:
            firebaseUser.uid,
        });

      const requestName =
        typeof req.body.name ===
        "string"
          ? req.body.name.trim()
          : "";

      const requestEmail =
        typeof req.body.email ===
        "string"
          ? req.body.email
              .trim()
              .toLowerCase()
          : "";

      const requestPhone =
        typeof req.body.phone ===
        "string"
          ? req.body.phone.trim()
          : "";

      const requestPhotoUrl =
        typeof req.body.photoUrl ===
        "string"
          ? req.body.photoUrl.trim()
          : "";

      const name =
        requestName ||
        firebaseUser.name ||
        existingUser?.name ||
        "Patient";

      const email =
        requestEmail ||
        firebaseUser.email ||
        existingUser?.email ||
        "";

      const phone =
        requestPhone ||
        firebaseUser.phone_number ||
        existingUser?.phone ||
        "";

      const photoUrl =
        requestPhotoUrl ||
        firebaseUser.picture ||
        existingUser?.photoUrl ||
        "";

      const user =
        await MobileUser.findOneAndUpdate(
          {
            firebaseUid:
              firebaseUser.uid,
          },
          {
            $set: {
              name,
              email,
              phone,
              photoUrl,
              status:
                "Active",
            },
            $setOnInsert: {
              fcmTokens: [],
              fcmTokensUpdatedAt:
                null,
            },
          },
          {
            returnDocument:
              "after",
            upsert:
              true,
            runValidators:
              true,
            setDefaultsOnInsert:
              true,
          },
        );

      return res.json({
        message:
          "Profile synchronized successfully",
        user,
      });
    } catch (error) {
      console.error(
        "Profile synchronization error:",
        error,
      );

      return res.status(500).json({
        message:
          error.message ||
          "Failed to synchronize profile",
      });
    }
  },
);

/*
|--------------------------------------------------------------------------
| Get Logged-In User Profile
|--------------------------------------------------------------------------
*/

router.get(
  "/profile",
  verifyFirebaseToken,
  async (req, res) => {
    try {
      const user =
        await getAuthenticatedProfile(
          req,
        );

      if (!user) {
        return res.status(404).json({
          message:
            "MongoDB profile not found",
        });
      }

      return res.json(
        user,
      );
    } catch (error) {
      console.error(
        "Profile loading error:",
        error,
      );

      return res.status(500).json({
        message:
          error.message ||
          "Failed to load profile",
      });
    }
  },
);

/*
|--------------------------------------------------------------------------
| Update Logged-In User Profile
|--------------------------------------------------------------------------
*/

router.put(
  "/profile",
  verifyFirebaseToken,
  async (req, res) => {
    try {
      const allowedUpdates = {};

      if (
        typeof req.body.name ===
        "string"
      ) {
        const name =
          req.body.name.trim();

        if (!name) {
          return res.status(400).json({
            message:
              "Name cannot be empty",
          });
        }

        allowedUpdates.name =
          name;
      }

      if (
        typeof req.body.phone ===
        "string"
      ) {
        const phone =
          req.body.phone.trim();

        if (!phone) {
          return res.status(400).json({
            message:
              "Phone number cannot be empty",
          });
        }

        const normalizedPhone =
          phone.replace(
            /[\s\-()]/g,
            "",
          );

        if (
          !/^\+?[0-9]{9,15}$/.test(
            normalizedPhone,
          )
        ) {
          return res.status(400).json({
            message:
              "Please enter a valid phone number",
          });
        }

        allowedUpdates.phone =
          normalizedPhone;
      }

      if (
        typeof req.body.photoUrl ===
        "string"
      ) {
        allowedUpdates.photoUrl =
          req.body.photoUrl.trim();
      }

      if (
        Object.keys(
          allowedUpdates,
        ).length === 0
      ) {
        return res.status(400).json({
          message:
            "No valid profile fields provided",
        });
      }

      const user =
        await MobileUser.findOneAndUpdate(
          {
            firebaseUid:
              req.firebaseUser.uid,
          },
          {
            $set:
              allowedUpdates,
          },
          {
            returnDocument:
              "after",
            runValidators:
              true,
          },
        );

      if (!user) {
        return res.status(404).json({
          message:
            "MongoDB profile not found",
        });
      }

      return res.json({
        message:
          "Profile updated successfully",
        user,
      });
    } catch (error) {
      console.error(
        "Profile update error:",
        error,
      );

      return res.status(500).json({
        message:
          error.message ||
          "Failed to update profile",
      });
    }
  },
);

/*
|--------------------------------------------------------------------------
| Save Device FCM Token
|--------------------------------------------------------------------------
*/

router.put(
  "/profile/fcm-token",
  verifyFirebaseToken,
  async (req, res) => {
    try {
      const fcmToken =
        typeof req.body.fcmToken ===
        "string"
          ? req.body.fcmToken.trim()
          : "";

      if (!fcmToken) {
        return res.status(400).json({
          message:
            "FCM token is required",
        });
      }

      const user =
        await MobileUser.findOneAndUpdate(
          {
            firebaseUid:
              req.firebaseUser.uid,
          },
          {
            $addToSet: {
              fcmTokens:
                fcmToken,
            },
            $set: {
              fcmTokensUpdatedAt:
                new Date(),
            },
            $unset: {
              fcmToken: "",
              fcmTokenUpdatedAt: "",
            },
          },
          {
            returnDocument:
              "after",
            runValidators:
              true,
          },
        );

      if (!user) {
        return res.status(404).json({
          message:
            "MongoDB profile not found",
        });
      }

      console.log(
        `FCM device registered for mobile user: ${user._id}`,
      );

      return res.json({
        message:
          "FCM device registered successfully",
        deviceCount:
          user.fcmTokens.length,
      });
    } catch (error) {
      console.error(
        "FCM token update error:",
        error,
      );

      return res.status(500).json({
        message:
          error.message ||
          "Failed to save FCM token",
      });
    }
  },
);

/*
|--------------------------------------------------------------------------
| Remove Current Device FCM Token
|--------------------------------------------------------------------------
*/

router.delete(
  "/profile/fcm-token",
  verifyFirebaseToken,
  async (req, res) => {
    try {
      const fcmToken =
        typeof req.body.fcmToken ===
        "string"
          ? req.body.fcmToken.trim()
          : "";

      if (!fcmToken) {
        return res.status(400).json({
          message:
            "FCM token is required",
        });
      }

      const user =
        await MobileUser.findOneAndUpdate(
          {
            firebaseUid:
              req.firebaseUser.uid,
          },
          {
            $pull: {
              fcmTokens:
                fcmToken,
            },
            $set: {
              fcmTokensUpdatedAt:
                new Date(),
            },
            $unset: {
              fcmToken: "",
              fcmTokenUpdatedAt: "",
            },
          },
          {
            returnDocument:
              "after",
            runValidators:
              true,
          },
        );

      if (!user) {
        return res.status(404).json({
          message:
            "MongoDB profile not found",
        });
      }

      console.log(
        `FCM device removed for mobile user: ${user._id}`,
      );

      return res.json({
        message:
          "FCM device removed successfully",
        deviceCount:
          user.fcmTokens.length,
      });
    } catch (error) {
      console.error(
        "FCM token removal error:",
        error,
      );

      return res.status(500).json({
        message:
          error.message ||
          "Failed to remove FCM token",
      });
    }
  },
);

export default router;