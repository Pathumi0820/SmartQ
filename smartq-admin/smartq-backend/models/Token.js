import mongoose from "mongoose";

const tokenSchema = new mongoose.Schema(
  {
    tokenNumber: {
      type: Number,
      required: true,
      min: 1,
    },

    prefix: {
      type: String,
      required: true,
      trim: true,
      uppercase: true,
    },

    patientName: {
      type: String,
      required: true,
      trim: true,
    },

    patientPhone: {
      type: String,
      required: true,
      trim: true,
      index: true,
    },

    hospital: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Hospital",
      required: true,
      index: true,
    },

    department: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Department",
      required: true,
      index: true,
    },

    /*
    |--------------------------------------------------------------------------
    | Queue Session
    |--------------------------------------------------------------------------
    |
    | Identifies the queue period in which this token was issued.
    | Existing tokens may not have a queue session, so this is optional.
    |
    */

    queueSession: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "QueueSession",
      default: null,
      index: true,
    },

    status: {
      type: String,
      enum: [
        "Waiting",
        "Called",
        "Serving",
        "Completed",
        "Cancelled",
      ],
      default: "Waiting",
      index: true,
    },

    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      default: null,
    },
  },
  {
    timestamps: true,
  },
);

/*
|--------------------------------------------------------------------------
| Normalize Token Data
|--------------------------------------------------------------------------
*/

tokenSchema.pre(
  "validate",
  function normalizeTokenData() {
    if (typeof this.prefix === "string") {
      this.prefix =
        this.prefix.trim().toUpperCase();
    }

    if (
      typeof this.patientName ===
      "string"
    ) {
      this.patientName =
        this.patientName.trim();
    }

    if (
      typeof this.patientPhone ===
      "string"
    ) {
      this.patientPhone =
        this.patientPhone.trim();
    }
  },
);

/*
|--------------------------------------------------------------------------
| Indexes
|--------------------------------------------------------------------------
*/

/*
 * Supports queue loading and token ordering for a department.
 */
tokenSchema.index({
  department: 1,
  status: 1,
  createdAt: 1,
});

/*
 * Supports finding a patient's active token.
 */
tokenSchema.index({
  patientPhone: 1,
  status: 1,
  createdAt: -1,
});

/*
 * Prevents duplicate token numbers inside the same queue session.
 *
 * The partial filter means older tokens without queueSession are not
 * affected by this unique constraint.
 */
tokenSchema.index(
  {
    queueSession: 1,
    tokenNumber: 1,
  },
  {
    unique: true,
    partialFilterExpression: {
      queueSession: {
        $type: "objectId",
      },
    },
  },
);

/*
 * Supports queue-session history and ordered token retrieval.
 */
tokenSchema.index({
  queueSession: 1,
  createdAt: 1,
});

/*
|--------------------------------------------------------------------------
| Virtual Token Code
|--------------------------------------------------------------------------
*/

tokenSchema.virtual("tokenCode").get(
  function getTokenCode() {
    return `${this.prefix}${String(
      this.tokenNumber,
    ).padStart(3, "0")}`;
  },
);

tokenSchema.set("toJSON", {
  virtuals: true,
});

tokenSchema.set("toObject", {
  virtuals: true,
});

const Token = mongoose.model(
  "Token",
  tokenSchema,
);

export default Token;