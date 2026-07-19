import express from "express";
import { getReports } from "../controllers/reportController.js";
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
  getReports
);

export default router;