import mongoose from "mongoose";

import {
  firebaseMessaging,
} from "../config/firebaseAdmin.js";

import Department from "../models/Department.js";
import MobileUser from "../models/MobileUser.js";
import QueueSession from "../models/QueueSession.js";
import Token from "../models/Token.js";

import {
  sendNotification,
} from "../utils/notify.js";

const allowedStatuses = [
  "Waiting",
  "Called",
  "Serving",
  "Completed",
  "Cancelled",
];

const activeStatuses = [
  "Waiting",
  "Called",
  "Serving",
];

const pushNotificationStatuses = [
  "Called",
  "Serving",
  "Completed",
  "Cancelled",
];

const invalidFcmTokenCodes = new Set([
  "messaging/registration-token-not-registered",
  "messaging/invalid-registration-token",
  "messaging/invalid-argument",
]);

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

const getObjectIdString = (value) => {
  if (!value) {
    return "";
  }

  if (value._id) {
    return value._id.toString();
  }

  return value.toString();
};

const getAccessFilter = (req) => {
  const filter = {};

  if (
    req.user.role ===
    "hospital_admin"
  ) {
    filter.hospital =
      req.user.hospital;
  }

  if (
    req.user.role ===
    "department_admin"
  ) {
    filter.department =
      req.user.department;
  }

  if (
    req.user.role ===
    "receptionist"
  ) {
    filter.hospital =
      req.user.hospital;
  }

  return filter;
};

const safeSendNotification = (
  data,
) => {
  try {
    const result =
      sendNotification(data);

    if (
      result &&
      typeof result.catch ===
        "function"
    ) {
      result.catch((error) => {
        console.error(
          "Socket notification error:",
          error,
        );
      });
    }
  } catch (error) {
    console.error(
      "Socket notification error:",
      error,
    );
  }
};

const emitGlobalUpdates = (req) => {
  const io = req.app.get("io");

  if (!io) {
    console.warn(
      "Socket.IO instance not found",
    );
    return;
  }

  io.emit("tokensUpdated");
  io.emit("dashboardUpdated");
  io.emit("reportsUpdated");
};

/*
|--------------------------------------------------------------------------
| Queue Session Helpers
|--------------------------------------------------------------------------
*/

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
    })
      .sort({
        startAt: -1,
        createdAt: -1,
      })
      .lean();
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

/*
 * Safely rolls back only when another reservation has not
 * already increased the session counter.
 */
const releaseQueueTokenSlot =
  async (
    queueSessionId,
    reservedTokenNumber,
  ) => {
    if (
      !queueSessionId ||
      !reservedTokenNumber
    ) {
      return;
    }

    try {
      await QueueSession.updateOne(
        {
          _id: queueSessionId,
          issuedTokenCount:
            reservedTokenNumber,
        },
        {
          $inc: {
            issuedTokenCount: -1,
          },
        },
      );
    } catch (error) {
      console.error(
        "Queue slot rollback error:",
        error,
      );
    }
  };

const getQueueClosedResponse =
  async (departmentId) => {
    const now = new Date();

    const scheduledQueue =
      await QueueSession.findOne({
        department: departmentId,
        status: "Scheduled",
        startAt: {
          $gt: now,
        },
      })
        .sort({
          startAt: 1,
        })
        .lean();

    if (scheduledQueue) {
      return {
        statusCode: 403,
        body: {
          code: "QUEUE_NOT_STARTED",
          message:
            "The queue has not started yet",
          startAt:
            scheduledQueue.startAt,
          endAt:
            scheduledQueue.endAt,
        },
      };
    }

    const activeButFullQueue =
      await QueueSession.findOne({
        department: departmentId,
        status: "Active",
        startAt: {
          $lte: now,
        },
        endAt: {
          $gte: now,
        },
        maximumTokens: {
          $ne: null,
        },
        $expr: {
          $gte: [
            "$issuedTokenCount",
            "$maximumTokens",
          ],
        },
      }).lean();

    if (activeButFullQueue) {
      return {
        statusCode: 409,
        body: {
          code: "QUEUE_FULL",
          message:
            "The maximum token limit has been reached",
          startAt:
            activeButFullQueue.startAt,
          endAt:
            activeButFullQueue.endAt,
          maximumTokens:
            activeButFullQueue.maximumTokens,
          issuedTokenCount:
            activeButFullQueue
              .issuedTokenCount,
        },
      };
    }

    return {
      statusCode: 403,
      body: {
        code: "QUEUE_CLOSED",
        message:
          "Token issuing is currently closed for this department",
      },
    };
  };

/*
|--------------------------------------------------------------------------
| Queue Calculation
|--------------------------------------------------------------------------
*/

const getCurrentQueueToken = async (
  departmentId,
  queueSessionId = null,
) => {
  const filter = {
    department: departmentId,
  };

  if (queueSessionId) {
    filter.queueSession =
      queueSessionId;
  } else {
    const {
      startOfDay,
      endOfDay,
    } = getTodayRange();

    filter.createdAt = {
      $gte: startOfDay,
      $lte: endOfDay,
    };
  }

  let currentToken =
    await Token.findOne({
      ...filter,
      status: "Serving",
    })
      .sort({
        tokenNumber: 1,
        createdAt: 1,
      })
      .select(
        "tokenNumber status createdAt",
      )
      .lean();

  if (!currentToken) {
    currentToken =
      await Token.findOne({
        ...filter,
        status: "Called",
      })
        .sort({
          tokenNumber: 1,
          createdAt: 1,
        })
        .select(
          "tokenNumber status createdAt",
        )
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

    const queueSessionId =
      getObjectIdString(
        token.queueSession,
      );

    if (!departmentId) {
      return {
        currentQueue: 0,
        peopleAhead: 0,
        estimatedMinutes: 0,
        estimatedTime: "--",
      };
    }

    const currentQueueToken =
      await getCurrentQueueToken(
        departmentId,
        queueSessionId,
      );

    const currentQueue =
      currentQueueToken?.tokenNumber ??
      0;

    let peopleAhead = 0;

    if (
      token.status === "Waiting"
    ) {
      const filter = {
        department: departmentId,
        _id: {
          $ne: token._id,
        },
        tokenNumber: {
          $lt: token.tokenNumber,
        },
        status: {
          $in: activeStatuses,
        },
      };

      if (queueSessionId) {
        filter.queueSession =
          queueSessionId;
      } else {
        const {
          startOfDay,
          endOfDay,
        } = getTodayRange();

        filter.createdAt = {
          $gte: startOfDay,
          $lte: endOfDay,
        };
      }

      peopleAhead =
        await Token.countDocuments(
          filter,
        );
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
      estimatedTime = "Completed";
    } else if (
      token.status === "Cancelled"
    ) {
      estimatedTime = "Cancelled";
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

const buildSocketPayload = async (
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
| Firebase Push Notifications
|--------------------------------------------------------------------------
*/

const getPushNotificationContent = (
  token,
) => {
  const tokenCode =
    buildTokenCode(token);

  switch (token.status) {
    case "Called":
      return {
        title:
          "Your token has been called",
        body:
          `Token ${tokenCode} has been called. Please proceed to the department.`,
      };

    case "Serving":
      return {
        title:
          "Your service has started",
        body:
          `Token ${tokenCode} is now being served.`,
      };

    case "Completed":
      return {
        title:
          "Token completed",
        body:
          `Token ${tokenCode} has been completed.`,
      };

    case "Cancelled":
      return {
        title:
          "Token cancelled",
        body:
          `Token ${tokenCode} has been cancelled.`,
      };

    default:
      return null;
  }
};

const normalizeFcmTokens = (
  tokens,
) => {
  if (!Array.isArray(tokens)) {
    return [];
  }

  return [
    ...new Set(
      tokens
        .filter(
          (token) =>
            typeof token ===
            "string",
        )
        .map(
          (token) =>
            token.trim(),
        )
        .filter(Boolean),
    ),
  ];
};

const removeInvalidFcmTokens =
  async (
    mobileUserId,
    invalidTokens,
  ) => {
    if (
      !mobileUserId ||
      !Array.isArray(
        invalidTokens,
      ) ||
      invalidTokens.length === 0
    ) {
      return;
    }

    try {
      await MobileUser.updateOne(
        {
          _id: mobileUserId,
        },
        {
          $pull: {
            fcmTokens: {
              $in: invalidTokens,
            },
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
      );

      console.warn(
        `${invalidTokens.length} invalid FCM token(s) removed for mobile user ${mobileUserId}`,
      );
    } catch (error) {
      console.error(
        "Failed to remove invalid FCM tokens:",
        error,
      );
    }
  };

const sendTokenPushNotification =
  async (token) => {
    if (
      !token ||
      !pushNotificationStatuses
        .includes(token.status)
    ) {
      return;
    }

    const tokenCode =
      buildTokenCode(token);

    try {
      const patientPhone =
        token.patientPhone
          ?.trim() ?? "";

      if (!patientPhone) {
        console.warn(
          `FCM skipped for ${tokenCode}: patient phone is missing`,
        );
        return;
      }

      const mobileUser =
        await MobileUser.findOne({
          phone: patientPhone,
          status: "Active",
          fcmTokens: {
            $exists: true,
            $type: "array",
            $ne: [],
          },
        })
          .select(
            "_id firebaseUid fcmTokens",
          )
          .lean();

      if (!mobileUser) {
        console.warn(
          `FCM skipped for ${tokenCode}: no registered device found`,
        );
        return;
      }

      const fcmTokens =
        normalizeFcmTokens(
          mobileUser.fcmTokens,
        );

      if (
        fcmTokens.length === 0
      ) {
        console.warn(
          `FCM skipped for ${tokenCode}: no valid device tokens found`,
        );
        return;
      }

      const content =
        getPushNotificationContent(
          token,
        );

      if (!content) {
        return;
      }

      const payload =
        await buildSocketPayload(
          token,
        );

      const response =
        await firebaseMessaging
          .sendEachForMulticast({
            tokens:
              fcmTokens,

            notification: {
              title:
                content.title,
              body:
                content.body,
            },

            data: {
              type:
                "token_status",
              tokenId:
                payload.tokenId,
              tokenCode:
                payload.tokenCode,
              status:
                payload.status,
              hospitalId:
                payload.hospitalId,
              departmentId:
                payload.departmentId,
              queueSessionId:
                payload.queueSessionId,
              currentQueue:
                String(
                  payload.currentQueue,
                ),
              peopleAhead:
                String(
                  payload.peopleAhead,
                ),
              estimatedMinutes:
                String(
                  payload
                    .estimatedMinutes,
                ),
              estimatedTime:
                payload.estimatedTime,
            },

            android: {
              priority: "high",
              notification: {
                channelId:
                  "smartq_high_importance",
                sound: "default",
              },
            },

            apns: {
              headers: {
                "apns-priority": "10",
              },
              payload: {
                aps: {
                  sound: "default",
                  contentAvailable:
                    true,
                },
              },
            },
          });

      const invalidTokens = [];

      response.responses.forEach(
        (
          result,
          index,
        ) => {
          if (result.success) {
            return;
          }

          const errorCode =
            result.error?.code
              ?.toString() ?? "";

          console.error(
            `FCM delivery failed for device ${index + 1}:`,
            errorCode ||
              result.error,
          );

          if (
            invalidFcmTokenCodes.has(
              errorCode,
            )
          ) {
            invalidTokens.push(
              fcmTokens[index],
            );
          }
        },
      );

      if (
        invalidTokens.length > 0
      ) {
        await removeInvalidFcmTokens(
          mobileUser._id,
          invalidTokens,
        );
      }

      console.log(
        `FCM multicast completed for ${payload.tokenCode}: ` +
        `success=${response.successCount}, ` +
        `failed=${response.failureCount}, ` +
        `devices=${fcmTokens.length}, ` +
        `invalidRemoved=${invalidTokens.length}`,
      );
    } catch (error) {
      console.error(
        `FCM notification error for ${tokenCode}:`,
        error,
      );
    }
  };

/*
|--------------------------------------------------------------------------
| Socket.IO Updates
|--------------------------------------------------------------------------
*/

const emitTokenUpdate = async (
  req,
  token,
) => {
  const io = req.app.get("io");

  if (!io || !token) {
    return;
  }

  const payload =
    await buildSocketPayload(
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
    "Emitting tokenUpdated:",
    payload,
  );
};

const emitDepartmentQueueUpdates =
  async (
    req,
    departmentId,
    queueSessionId = null,
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

    const filter = {
      department:
        normalizedDepartmentId,
      status: {
        $in: activeStatuses,
      },
    };

    if (queueSessionId) {
      filter.queueSession =
        queueSessionId;
    } else {
      const {
        startOfDay,
        endOfDay,
      } = getTodayRange();

      filter.createdAt = {
        $gte: startOfDay,
        $lte: endOfDay,
      };
    }

    const tokens =
      await Token.find(filter)
        .sort({
          tokenNumber: 1,
          createdAt: 1,
        });

    const queuePayloads = [];

    for (
      const queueToken of tokens
    ) {
      const payload =
        await buildSocketPayload(
          queueToken,
        );

      queuePayloads.push(
        payload,
      );

      io.to(
        `token:${payload.tokenId}`,
      ).emit(
        "tokenUpdated",
        payload,
      );
    }

    const currentlyServing =
      queuePayloads.find(
        (item) =>
          item.status ===
          "Serving",
      ) ??
      queuePayloads.find(
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
        queueSessionId:
          queueSessionId
            ?.toString() ?? "",
        currentQueue:
          currentlyServing
            ?.currentQueue ?? 0,
        activeTokenCount:
          queuePayloads.length,
        updatedAt:
          new Date(),
      },
    );
  };

/*
|--------------------------------------------------------------------------
| Create Token
|--------------------------------------------------------------------------
*/

export const createToken = async (
  req,
  res,
) => {
  let reservedQueueSessionId =
    null;

  let reservedTokenNumber =
    null;

  try {
    let {
      patientName,
      patientPhone,
      hospital,
      department,
    } = req.body;

    patientName =
      typeof patientName ===
      "string"
        ? patientName.trim()
        : "";

    patientPhone =
      typeof patientPhone ===
      "string"
        ? patientPhone.trim()
        : "";

    if (
      !patientName ||
      !patientPhone ||
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

    const dep =
      await Department.findById(
        department,
      );

    if (!dep) {
      return res.status(404).json({
        message:
          "Department not found",
      });
    }

    if (
      !dep.prefix?.trim()
    ) {
      return res.status(400).json({
        message:
          "The selected department does not have a token prefix",
      });
    }

    if (
      String(dep.hospital) !==
      String(hospital)
    ) {
      return res.status(400).json({
        message:
          "Department does not belong to the selected hospital",
      });
    }

    if (
      req.user.role ===
      "hospital_admin"
    ) {
      if (
        String(dep.hospital) !==
        String(
          req.user.hospital,
        )
      ) {
        return res.status(403).json({
          message:
            "Access denied",
        });
      }

      hospital =
        req.user.hospital;
    }

    if (
      req.user.role ===
      "department_admin"
    ) {
      if (
        String(department) !==
        String(
          req.user.department,
        )
      ) {
        return res.status(403).json({
          message:
            "Access denied",
        });
      }

      hospital =
        req.user.hospital;

      department =
        req.user.department;
    }

    if (
      req.user.role ===
      "receptionist"
    ) {
      if (
        String(dep.hospital) !==
        String(
          req.user.hospital,
        )
      ) {
        return res.status(403).json({
          message:
            "Access denied",
        });
      }

      hospital =
        req.user.hospital;
    }

    /*
    |--------------------------------------------------------------------------
    | Require Active Queue Session
    |--------------------------------------------------------------------------
    */

    const activeQueue =
      await findAvailableActiveQueueSession(
        department,
      );

    if (!activeQueue) {
      const queueResponse =
        await getQueueClosedResponse(
          department,
        );

      return res
        .status(
          queueResponse.statusCode,
        )
        .json(
          queueResponse.body,
        );
    }

    const reservedQueue =
      await reserveQueueTokenSlot(
        activeQueue._id,
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
     * The atomic issued count is used as the token number.
     * This prevents duplicate numbers during simultaneous requests.
     */
    reservedTokenNumber =
      reservedQueue
        .issuedTokenCount;

    const token =
      await Token.create({
        tokenNumber:
          reservedTokenNumber,
        prefix:
          dep.prefix.trim(),
        patientName,
        patientPhone,
        hospital,
        department,
        queueSession:
          reservedQueue._id,
        status:
          "Waiting",
        createdBy:
          req.user.id,
      });

    reservedQueueSessionId =
      null;

    reservedTokenNumber =
      null;

    const payload =
      await buildSocketPayload(
        token,
      );

    emitGlobalUpdates(req);

    await emitDepartmentQueueUpdates(
      req,
      getObjectIdString(
        token.department,
      ),
      getObjectIdString(
        token.queueSession,
      ),
    );

    safeSendNotification({
      message:
        `New token created for ${patientName}`,
      type: "token",
    });

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
      reservedQueueSessionId &&
      reservedTokenNumber
    ) {
      await releaseQueueTokenSlot(
        reservedQueueSessionId,
        reservedTokenNumber,
      );
    }

    console.error(
      "Token creation error:",
      error,
    );

    if (
      error?.code === 11000
    ) {
      return res.status(409).json({
        message:
          "A token number conflict occurred. Please try again.",
      });
    }

    return res.status(500).json({
      message:
        error.message ||
        "Failed to create token",
    });
  }
};

/*
|--------------------------------------------------------------------------
| Get Tokens
|--------------------------------------------------------------------------
*/

export const getTokens = async (
  req,
  res,
) => {
  try {
    const tokens =
      await Token.find(
        getAccessFilter(req),
      )
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
        .populate(
          "createdBy",
          "fullName email role",
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
              ...token.toObject(),
              tokenCode:
                buildTokenCode(
                  token,
                ),
              ...queueInformation,
            };
          },
        ),
      );

    return res.json(
      formattedTokens,
    );
  } catch (error) {
    console.error(
      "Token loading error:",
      error,
    );

    return res.status(500).json({
      message:
        error.message ||
        "Failed to load tokens",
    });
  }
};

/*
|--------------------------------------------------------------------------
| Update Token
|--------------------------------------------------------------------------
*/

export const updateToken = async (
  req,
  res,
) => {
  try {
    const {
      id,
    } = req.params;

    if (
      !mongoose.Types.ObjectId
        .isValid(id)
    ) {
      return res.status(400).json({
        message:
          "Invalid token ID",
      });
    }

    const updates = {
      ...req.body,
    };

    if (
      updates.status &&
      !allowedStatuses.includes(
        updates.status,
      )
    ) {
      return res.status(400).json({
        message:
          "Invalid token status",
      });
    }

    delete updates._id;
    delete updates.createdBy;
    delete updates.tokenNumber;
    delete updates.queueSession;

    const previousToken =
      await Token.findOne({
        _id: id,
        ...getAccessFilter(req),
      });

    if (!previousToken) {
      return res.status(404).json({
        message:
          "Token not found or access denied",
      });
    }

    const previousStatus =
      previousToken.status;

    const previousDepartmentId =
      getObjectIdString(
        previousToken.department,
      );

    const token =
      await Token.findOneAndUpdate(
        {
          _id: id,
          ...getAccessFilter(req),
        },
        {
          $set:
            updates,
        },
        {
          returnDocument:
            "after",
          runValidators:
            true,
        },
      )
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
        );

    if (!token) {
      return res.status(404).json({
        message:
          "Token not found or access denied",
      });
    }

    const currentDepartmentId =
      getObjectIdString(
        token.department,
      );

    const queueSessionId =
      getObjectIdString(
        token.queueSession,
      );

    emitGlobalUpdates(req);

    await emitTokenUpdate(
      req,
      token,
    );

    await emitDepartmentQueueUpdates(
      req,
      currentDepartmentId,
      queueSessionId,
    );

    if (
      previousDepartmentId &&
      previousDepartmentId !==
        currentDepartmentId
    ) {
      await emitDepartmentQueueUpdates(
        req,
        previousDepartmentId,
      );
    }

    if (
      token.status !==
      previousStatus
    ) {
      await sendTokenPushNotification(
        token,
      );
    }

    const queueInformation =
      await calculateQueueInformation(
        token,
      );

    return res.json({
      message:
        "Token updated successfully",
      token,
      ...queueInformation,
    });
  } catch (error) {
    console.error(
      "Token update error:",
      error,
    );

    return res.status(500).json({
      message:
        error.message ||
        "Failed to update token",
    });
  }
};

/*
|--------------------------------------------------------------------------
| Delete Token
|--------------------------------------------------------------------------
*/

export const deleteToken = async (
  req,
  res,
) => {
  try {
    const {
      id,
    } = req.params;

    if (
      !mongoose.Types.ObjectId
        .isValid(id)
    ) {
      return res.status(400).json({
        message:
          "Invalid token ID",
      });
    }

    const token =
      await Token.findOneAndDelete({
        _id: id,
        ...getAccessFilter(req),
      });

    if (!token) {
      return res.status(404).json({
        message:
          "Token not found or access denied",
      });
    }

    const io =
      req.app.get("io");

    const tokenId =
      token._id.toString();

    const departmentId =
      getObjectIdString(
        token.department,
      );

    const queueSessionId =
      getObjectIdString(
        token.queueSession,
      );

    const payload = {
      tokenId,
      tokenCode:
        buildTokenCode(token),
      departmentId,
      queueSessionId,
      deletedAt:
        new Date(),
    };

    if (io) {
      io.to(
        `token:${tokenId}`,
      ).emit(
        "tokenDeleted",
        payload,
      );
    }

    emitGlobalUpdates(req);

    await emitDepartmentQueueUpdates(
      req,
      departmentId,
      queueSessionId,
    );

    return res.json({
      message:
        "Token deleted successfully",
    });
  } catch (error) {
    console.error(
      "Token deletion error:",
      error,
    );

    return res.status(500).json({
      message:
        error.message ||
        "Failed to delete token",
    });
  }
};

/*
|--------------------------------------------------------------------------
| Update Token Status
|--------------------------------------------------------------------------
*/

export const updateTokenStatus =
  async (req, res) => {
    try {
      const {
        id,
      } = req.params;

      const status =
        typeof req.body.status ===
        "string"
          ? req.body.status.trim()
          : "";

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
        !allowedStatuses.includes(
          status,
        )
      ) {
        return res.status(400).json({
          message:
            "Status must be Waiting, Called, Serving, Completed or Cancelled",
        });
      }

      const previousToken =
        await Token.findOne({
          _id: id,
          ...getAccessFilter(req),
        });

      if (!previousToken) {
        return res.status(404).json({
          message:
            "Token not found or access denied",
        });
      }

      const previousStatus =
        previousToken.status;

      const token =
        await Token.findOneAndUpdate(
          {
            _id: id,
            ...getAccessFilter(req),
          },
          {
            $set: {
              status,
            },
          },
          {
            returnDocument:
              "after",
            runValidators:
              true,
          },
        )
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
          );

      if (!token) {
        return res.status(404).json({
          message:
            "Token not found or access denied",
        });
      }

      const departmentId =
        getObjectIdString(
          token.department,
        );

      const queueSessionId =
        getObjectIdString(
          token.queueSession,
        );

      emitGlobalUpdates(req);

      await emitTokenUpdate(
        req,
        token,
      );

      await emitDepartmentQueueUpdates(
        req,
        departmentId,
        queueSessionId,
      );

      if (
        token.status !==
        previousStatus
      ) {
        await sendTokenPushNotification(
          token,
        );
      }

      safeSendNotification({
        message:
          `Token ${buildTokenCode(
            token,
          )} status changed to ${token.status}`,
        type: "status",
      });

      const queueInformation =
        await calculateQueueInformation(
          token,
        );

      return res.json({
        message:
          "Token status updated successfully",
        token,
        ...queueInformation,
      });
    } catch (error) {
      console.error(
        "Token status update error:",
        error,
      );

      return res.status(500).json({
        message:
          error.message ||
          "Failed to update token status",
      });
    }
  };

/*
|--------------------------------------------------------------------------
| Verify Token
|--------------------------------------------------------------------------
*/

export const verifyToken = async (
  req,
  res,
) => {
  try {
    const tokenCode =
      req.params.tokenCode
        ?.toUpperCase()
        .trim() ?? "";

    if (!tokenCode) {
      return res.status(400).json({
        verified: false,
        message:
          "Token number is required",
      });
    }

    const prefix =
      tokenCode.replace(
        /[0-9]/g,
        "",
      );

    const number = Number(
      tokenCode.replace(
        /\D/g,
        "",
      ),
    );

    if (
      !prefix ||
      !Number.isInteger(number) ||
      number < 1
    ) {
      return res.status(400).json({
        verified: false,
        message:
          "Invalid token format",
      });
    }

    await closeExpiredQueueSessions();

    const now = new Date();

    let token =
      await Token.findOne({
        prefix,
        tokenNumber:
          number,
        queueSession: {
          $ne: null,
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

    /*
     * Prefer a token belonging to today's/current queue session.
     * Fall back to today's legacy token when queueSession is absent.
     */
    if (
      token?.queueSession &&
      token.queueSession.endAt <
        now
    ) {
      token = null;
    }

    if (!token) {
      const {
        startOfDay,
        endOfDay,
      } = getTodayRange();

      token =
        await Token.findOne({
          prefix,
          tokenNumber:
            number,
          createdAt: {
            $gte: startOfDay,
            $lte: endOfDay,
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
    }

    if (!token) {
      return res.status(404).json({
        verified: false,
        message:
          "Invalid token number",
      });
    }

    const queueInformation =
      await calculateQueueInformation(
        token,
      );

    return res.json({
      verified: true,
      tokenId:
        token._id,
      tokenCode:
        buildTokenCode(token),
      patientName:
        token.patientName,
      patientPhone:
        token.patientPhone,
      hospital:
        token.hospital?.name ?? "",
      hospitalId:
        getObjectIdString(
          token.hospital,
        ),
      department:
        token.department?.name ?? "",
      departmentId:
        getObjectIdString(
          token.department,
        ),
      queueSessionId:
        token.queueSession?._id ?? "",
      queueStartAt:
        token.queueSession
          ?.startAt ?? null,
      queueEndAt:
        token.queueSession
          ?.endAt ?? null,
      queueSessionStatus:
        token.queueSession
          ?.status ?? "",
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
      "Token verification error:",
      error,
    );

    return res.status(500).json({
      verified: false,
      message:
        error.message ||
        "Failed to verify token",
    });
  }
};