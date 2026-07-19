import Hospital from "../models/Hospital.js";
import Department from "../models/Department.js";
import User from "../models/User.js";
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

export const getDashboardStats = async (req, res) => {
  try {
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);

    const todayEnd = new Date();
    todayEnd.setHours(23, 59, 59, 999);

    const accessFilter = getAccessFilter(req);

    const todayFilter = {
      ...accessFilter,
      createdAt: { $gte: todayStart, $lte: todayEnd },
    };

    const waitingTokens = await Token.countDocuments({
      ...accessFilter,
      status: "Waiting",
    });

    const calledTokens = await Token.countDocuments({
      ...accessFilter,
      status: "Called",
    });

    const servingTokens = await Token.countDocuments({
      ...accessFilter,
      status: "Serving",
    });

    const completedTokens = await Token.countDocuments({
      ...accessFilter,
      status: "Completed",
    });

    const cancelledTokens = await Token.countDocuments({
      ...accessFilter,
      status: "Cancelled",
    });

    const stats = {
      totalHospitals:
        req.user.role === "super_admin"
          ? await Hospital.countDocuments()
          : 1,

      totalDepartments: await Department.countDocuments(accessFilter),

      totalUsers:
        req.user.role === "super_admin"
          ? await User.countDocuments()
          : await User.countDocuments(accessFilter),

      totalAppointments: await Appointment.countDocuments(accessFilter),

      todayTokens: await Token.countDocuments(todayFilter),

      waitingTokens,
      calledTokens,
      servingTokens,
      completedTokens,
      cancelledTokens,

      tokenStatusChart: [
        { name: "Waiting", value: waitingTokens },
        { name: "Called", value: calledTokens },
        { name: "Serving", value: servingTokens },
        { name: "Completed", value: completedTokens },
        { name: "Cancelled", value: cancelledTokens },
      ],
    };

    res.json(stats);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};