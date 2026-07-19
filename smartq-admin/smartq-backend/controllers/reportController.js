import Token from "../models/Token.js";
import Appointment from "../models/Appointment.js";

const getAccessFilter = (req) => {
  const filter = {};

  if (req.user.role === "hospital_admin") {
    filter.hospital = req.user.hospital;
  }

  if (req.user.role === "department_admin") {
    filter.department = req.user.department;
  }

  if (req.user.role === "receptionist") {
    filter.hospital = req.user.hospital;
  }

  return filter;
};

export const getReports = async (req, res) => {
  try {
    const { from, to, hospital, department } = req.query;

    const filter = {
      ...getAccessFilter(req),
    };

    if (from && to) {
      filter.createdAt = {
        $gte: new Date(from),
        $lte: new Date(to),
      };
    }

    if (req.user.role === "super_admin") {
      if (hospital) filter.hospital = hospital;
      if (department) filter.department = department;
    }

    const tokens = await Token.find(filter)
      .populate("hospital", "name")
      .populate("department", "name prefix")
      .sort({ createdAt: -1 });

    const appointments = await Appointment.find(filter)
      .populate("hospital", "name")
      .populate("department", "name")
      .sort({ createdAt: -1 });

    res.json({
      summary: {
        totalTokens: tokens.length,
        waitingTokens: tokens.filter((t) => t.status === "Waiting").length,
        completedTokens: tokens.filter((t) => t.status === "Completed").length,
        cancelledTokens: tokens.filter((t) => t.status === "Cancelled").length,
        totalAppointments: appointments.length,
      },
      tokens,
      appointments,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};