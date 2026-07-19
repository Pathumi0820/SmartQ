import Appointment from "../models/Appointment.js";
import Department from "../models/Department.js";
import { getIO } from "../socket.js";

const emitAppointmentUpdates = () => {
  const io = getIO();
  io.emit("appointmentsUpdated");
  io.emit("dashboardUpdated");
  io.emit("reportsUpdated");
};

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

export const createAppointment = async (req, res) => {
  try {
    let data = { ...req.body };

    const dep = await Department.findById(data.department);

    if (!dep) {
      return res.status(404).json({ message: "Department not found" });
    }

    if (req.user.role === "hospital_admin") {
      if (String(dep.hospital) !== String(req.user.hospital)) {
        return res.status(403).json({ message: "Access denied" });
      }

      data.hospital = req.user.hospital;
    }

    if (req.user.role === "department_admin") {
      if (String(data.department) !== String(req.user.department)) {
        return res.status(403).json({ message: "Access denied" });
      }

      data.hospital = req.user.hospital;
      data.department = req.user.department;
    }

    if (req.user.role === "receptionist") {
      data.hospital = req.user.hospital;
    }

    const appointment = await Appointment.create({
      ...data,
      createdBy: req.user.id,
    });

    emitUpdates();

    res.status(201).json(appointment);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

export const getAppointments = async (req, res) => {
  try {
    const appointments = await Appointment.find(getAccessFilter(req))
      .populate("hospital", "name city")
      .populate("department", "name prefix")
      .populate("createdBy", "fullName email role")
      .sort({ createdAt: -1 });

    res.json(appointments);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

export const updateAppointment = async (req, res) => {
  try {
    const filter = { _id: req.params.id, ...getAccessFilter(req) };

    const appointment = await Appointment.findOneAndUpdate(filter, req.body, {
      new: true,
    });

    if (!appointment) {
      return res
        .status(404)
        .json({ message: "Appointment not found or access denied" });
    }

    emitUpdates();

    res.json(appointment);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

export const deleteAppointment = async (req, res) => {
  try {
    const filter = { _id: req.params.id, ...getAccessFilter(req) };

    const appointment = await Appointment.findOneAndDelete(filter);

    if (!appointment) {
      return res
        .status(404)
        .json({ message: "Appointment not found or access denied" });
    }

    emitUpdates();

    res.json({ message: "Appointment deleted successfully" });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};