import express from "express";
import {
  createAppointment,
  getAppointments,
  updateAppointment,
  deleteAppointment,
} from "../controllers/appointmentController.js";

import authMiddleware from "../middleware/authMiddleware.js";
import roleMiddleware from "../middleware/roleMiddleware.js";

const router = express.Router();

router.get(
  "/",
  authMiddleware,
  roleMiddleware(
    "super_admin",
    "hospital_admin",
    "department_admin",
    "receptionist"
  ),
  getAppointments
);

router.post(
  "/",
  authMiddleware,
  roleMiddleware(
    "super_admin",
    "hospital_admin",
    "department_admin",
    "receptionist"
  ),
  createAppointment
);

router.put(
  "/:id",
  authMiddleware,
  roleMiddleware(
    "super_admin",
    "hospital_admin",
    "department_admin",
    "receptionist"
  ),
  updateAppointment
);

router.delete(
  "/:id",
  authMiddleware,
  roleMiddleware("super_admin", "hospital_admin"),
  deleteAppointment
);

export default router;