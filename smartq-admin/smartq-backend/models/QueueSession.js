import mongoose from "mongoose";

const queueSessionSchema = new mongoose.Schema(
  {
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
    | Queue Opening Period
    |--------------------------------------------------------------------------
    |
    | Store complete Date values instead of separate date/time strings.
    |
    | Example:
    | startAt: 2026-07-16T06:00:00
    | endAt:   2026-07-16T08:00:00
    |
    */

    startAt: {
      type: Date,
      required: true,
      index: true,
    },

    endAt: {
      type: Date,
      required: true,
      index: true,
    },

    status: {
      type: String,
      enum: [
        "Scheduled",
        "Active",
        "Closed",
        "Cancelled",
      ],
      default: "Scheduled",
      index: true,
    },

    /*
    |--------------------------------------------------------------------------
    | Token Limits
    |--------------------------------------------------------------------------
    |
    | null means there is no maximum-token limit.
    |
    */

    maximumTokens: {
      type: Number,
      default: null,
      min: 1,
    },

    issuedTokenCount: {
      type: Number,
      default: 0,
      min: 0,
    },

    /*
    |--------------------------------------------------------------------------
    | Queue Lifecycle
    |--------------------------------------------------------------------------
    */

    startedAt: {
      type: Date,
      default: null,
    },

    closedAt: {
      type: Date,
      default: null,
    },

    cancelledAt: {
      type: Date,
      default: null,
    },

    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    startedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      default: null,
    },

    closedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      default: null,
    },

    cancelledBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      default: null,
    },

    notes: {
      type: String,
      default: "",
      trim: true,
      maxlength: 500,
    },
  },
  {
    timestamps: true,
  },
);

/*
|--------------------------------------------------------------------------
| Validation
|--------------------------------------------------------------------------
*/

queueSessionSchema.pre(
  "validate",
  function validateQueueSession() {
    if (
      this.startAt &&
      this.endAt &&
      this.endAt <= this.startAt
    ) {
      throw new Error(
        "Queue end time must be later than the start time",
      );
    }

    if (
      this.maximumTokens != null &&
      this.issuedTokenCount >
        this.maximumTokens
    ) {
      throw new Error(
        "Issued token count cannot exceed maximum tokens",
      );
    }
  },
);

/*
|--------------------------------------------------------------------------
| Indexes
|--------------------------------------------------------------------------
|
| Helps quickly find the currently active queue for a department.
|
*/

queueSessionSchema.index({
  department: 1,
  status: 1,
  startAt: 1,
  endAt: 1,
});

queueSessionSchema.index({
  hospital: 1,
  department: 1,
  createdAt: -1,
});

/*
|--------------------------------------------------------------------------
| Instance Helpers
|--------------------------------------------------------------------------
*/

queueSessionSchema.methods.isWithinOpeningPeriod =
  function isWithinOpeningPeriod(
    currentTime = new Date(),
  ) {
    return (
      currentTime >= this.startAt &&
      currentTime <= this.endAt
    );
  };

queueSessionSchema.methods.hasAvailableTokenSpace =
  function hasAvailableTokenSpace() {
    if (this.maximumTokens == null) {
      return true;
    }

    return (
      this.issuedTokenCount <
      this.maximumTokens
    );
  };

queueSessionSchema.methods.canIssueToken =
  function canIssueToken(
    currentTime = new Date(),
  ) {
    return (
      this.status === "Active" &&
      this.isWithinOpeningPeriod(
        currentTime,
      ) &&
      this.hasAvailableTokenSpace()
    );
  };

/*
|--------------------------------------------------------------------------
| Model
|--------------------------------------------------------------------------
*/

const QueueSession = mongoose.model(
  "QueueSession",
  queueSessionSchema,
);

export default QueueSession;