import mongoose from "mongoose";

const appointmentSchema = new mongoose.Schema(
  {
    patientName: { type: String, required: true, trim: true },
    patientPhone: { type: String, default: "" },

    hospital: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Hospital",
      required: true,
    },

    department: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Department",
      required: true,
    },

    doctorName: { type: String, default: "" },

    appointmentDate: { type: String, required: true },
    appointmentTime: { type: String, required: true },

    status: {
      type: String,
      enum: ["Scheduled", "Completed", "Cancelled"],
      default: "Scheduled",
    },

    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },
  },
  { timestamps: true }
);

export default mongoose.model("Appointment", appointmentSchema);