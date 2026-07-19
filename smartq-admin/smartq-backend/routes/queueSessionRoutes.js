import express from "express";

import {
  cancelQueueSession,
  closeQueueSession,
  createQueueSession,
  getActiveQueueSession,
  getQueueSessionById,
  getQueueSessions,
  startQueueSession,
} from "../controllers/queueSessionController.js";

import authMiddleware from "../middleware/authMiddleware.js";
import roleMiddleware from "../middleware/roleMiddleware.js";

const router = express.Router();

const queueViewRoles = [
  "department_admin",
  "receptionist",
];

const queueManagementRoles = [
  "department_admin",
];

/*
|--------------------------------------------------------------------------
| Get Queue Sessions
|--------------------------------------------------------------------------
*/

router.get(
  "/",
  authMiddleware,
  roleMiddleware(...queueViewRoles),
  getQueueSessions,
);

/*
|--------------------------------------------------------------------------
| Get Active Queue Session for Department
|--------------------------------------------------------------------------
|
| Keep this route before "/:id" so Express does not treat
| "department" as a queue-session ID.
|
*/

router.get(
  "/department/:departmentId/active",
  authMiddleware,
  roleMiddleware(...queueViewRoles),
  getActiveQueueSession,
);

/*
|--------------------------------------------------------------------------
| Get Queue Session by ID
|--------------------------------------------------------------------------
*/

router.get(
  "/:id",
  authMiddleware,
  roleMiddleware(...queueViewRoles),
  getQueueSessionById,
);

/*
|--------------------------------------------------------------------------
| Create Queue Session
|--------------------------------------------------------------------------
*/

router.post(
  "/",
  authMiddleware,
  roleMiddleware(...queueManagementRoles),
  createQueueSession,
);

/*
|--------------------------------------------------------------------------
| Start Queue Session
|--------------------------------------------------------------------------
*/

router.put(
  "/:id/start",
  authMiddleware,
  roleMiddleware(...queueManagementRoles),
  startQueueSession,
);

/*
|--------------------------------------------------------------------------
| Close Queue Session
|--------------------------------------------------------------------------
*/

router.put(
  "/:id/close",
  authMiddleware,
  roleMiddleware(...queueManagementRoles),
  closeQueueSession,
);

/*
|--------------------------------------------------------------------------
| Cancel Queue Session
|--------------------------------------------------------------------------
*/

router.put(
  "/:id/cancel",
  authMiddleware,
  roleMiddleware(...queueManagementRoles),
  cancelQueueSession,
);

export default router;