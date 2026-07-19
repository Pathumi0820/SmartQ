import express from "express";
import {
  createHospital,
  getHospitals,
  updateHospital,
  deleteHospital,
} from "../controllers/hospitalController.js";

import authMiddleware from "../middleware/authMiddleware.js";
import roleMiddleware from "../middleware/roleMiddleware.js";

const router = express.Router();

router.get(
  "/",
  authMiddleware,
  roleMiddleware("super_admin", "hospital_admin", "department_admin"),
  getHospitals
);

router.post(
  "/",
  authMiddleware,
  roleMiddleware("super_admin"),
  createHospital
);

router.put(
  "/:id",
  authMiddleware,
  roleMiddleware("super_admin"),
  updateHospital
);

router.delete(
  "/:id",
  authMiddleware,
  roleMiddleware("super_admin"),
  deleteHospital
);

export default router;