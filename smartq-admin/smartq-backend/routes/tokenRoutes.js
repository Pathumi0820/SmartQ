import express from "express";

import {
  createToken,
  deleteToken,
  getTokens,
  updateToken,
  updateTokenStatus,
  verifyToken,
} from "../controllers/tokenController.js";

import authMiddleware from "../middleware/authMiddleware.js";
import roleMiddleware from "../middleware/roleMiddleware.js";

const router = express.Router();

const tokenManagementRoles = [
  "super_admin",
  "hospital_admin",
  "department_admin",
  "receptionist",
];

const tokenDeletionRoles = [
  "super_admin",
  "hospital_admin",
];

/*
|--------------------------------------------------------------------------
| Public Token Verification
|--------------------------------------------------------------------------
*/

router.get(
  "/verify/:tokenCode",
  verifyToken,
);

/*
|--------------------------------------------------------------------------
| Get Tokens
|--------------------------------------------------------------------------
*/

router.get(
  "/",
  authMiddleware,
  roleMiddleware(...tokenManagementRoles),
  getTokens,
);

/*
|--------------------------------------------------------------------------
| Create Token
|--------------------------------------------------------------------------
*/

router.post(
  "/",
  authMiddleware,
  roleMiddleware(...tokenManagementRoles),
  createToken,
);

/*
|--------------------------------------------------------------------------
| Update Token Status
|--------------------------------------------------------------------------
|
| Keep this route before "/:id" routes that could conflict with it.
|
*/

router.put(
  "/:id/status",
  authMiddleware,
  roleMiddleware(...tokenManagementRoles),
  updateTokenStatus,
);

/*
|--------------------------------------------------------------------------
| Update Token
|--------------------------------------------------------------------------
*/

router.put(
  "/:id",
  authMiddleware,
  roleMiddleware(...tokenManagementRoles),
  updateToken,
);

/*
|--------------------------------------------------------------------------
| Delete Token
|--------------------------------------------------------------------------
*/

router.delete(
  "/:id",
  authMiddleware,
  roleMiddleware(...tokenDeletionRoles),
  deleteToken,
);

export default router;