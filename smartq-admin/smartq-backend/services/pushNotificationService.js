import admin from "firebase-admin";

import MobileUser from "../models/MobileUser.js";

const invalidTokenCodes = new Set([
  "messaging/registration-token-not-registered",
  "messaging/invalid-registration-token",
  "messaging/invalid-argument",
]);

export const sendPushNotificationToUser = async ({
  user,
  title,
  body,
  data = {},
}) => {
  const tokens = Array.isArray(user?.fcmTokens)
    ? [
        ...new Set(
          user.fcmTokens
            .filter(
              (token) =>
                typeof token === "string",
            )
            .map((token) => token.trim())
            .filter(Boolean),
        ),
      ]
    : [];

  if (tokens.length === 0) {
    return {
      successCount: 0,
      failureCount: 0,
      skipped: true,
    };
  }

  const normalizedData = Object.fromEntries(
    Object.entries(data).map(
      ([key, value]) => [
        key,
        value?.toString() ?? "",
      ],
    ),
  );

  const response =
    await admin.messaging().sendEachForMulticast({
      tokens,
      notification: {
        title,
        body,
      },
      data: normalizedData,
      android: {
        priority: "high",
        notification: {
          channelId:
            "smartq_high_importance",
          sound: "default",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
          },
        },
      },
    });

  const invalidTokens = [];

  response.responses.forEach(
    (result, index) => {
      if (
        !result.success &&
        invalidTokenCodes.has(
          result.error?.code,
        )
      ) {
        invalidTokens.push(
          tokens[index],
        );
      }
    },
  );

  if (invalidTokens.length > 0) {
    await MobileUser.updateOne(
      {
        _id: user._id,
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
      },
    );
  }

  return {
    successCount:
      response.successCount,
    failureCount:
      response.failureCount,
    removedInvalidTokens:
      invalidTokens.length,
    skipped: false,
  };
};