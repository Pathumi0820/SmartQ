import mongoose from "mongoose";

const mobileUserSchema = new mongoose.Schema(
  {
    firebaseUid: {
      type: String,
      required: true,
      unique: true,
      index: true,
      trim: true,
    },

    name: {
      type: String,
      default: "Patient",
      trim: true,
    },

    email: {
      type: String,
      default: "",
      lowercase: true,
      trim: true,
    },

    phone: {
      type: String,
      default: "",
      trim: true,
      index: true,
    },

    photoUrl: {
      type: String,
      default: "",
      trim: true,
    },

    /*
    |--------------------------------------------------------------------------
    | Firebase Cloud Messaging Device Tokens
    |--------------------------------------------------------------------------
    |
    | One user can sign in on multiple phones or tablets.
    | Each device stores its own FCM token in this array.
    |
    */

    fcmTokens: {
      type: [
        {
          type: String,
          trim: true,
        },
      ],
      default: [],
    },

    // Records when the FCM token list was last changed.
    fcmTokensUpdatedAt: {
      type: Date,
      default: null,
    },

    status: {
      type: String,
      enum: [
        "Active",
        "Inactive",
      ],
      default: "Active",
    },
  },
  {
    timestamps: true,
  },
);

/*
|--------------------------------------------------------------------------
| Clean FCM Tokens Before Saving
|--------------------------------------------------------------------------
|
| Removes empty values, trims tokens, and prevents duplicates.
|
*/

mobileUserSchema.pre(
  "save",
  function cleanFcmTokens(next) {
    if (Array.isArray(this.fcmTokens)) {
      this.fcmTokens = [
        ...new Set(
          this.fcmTokens
            .filter(
              (token) =>
                typeof token === "string",
            )
            .map((token) => token.trim())
            .filter(Boolean),
        ),
      ];
    }

    next();
  },
);

const MobileUser = mongoose.model(
  "MobileUser",
  mobileUserSchema,
);

export default MobileUser;