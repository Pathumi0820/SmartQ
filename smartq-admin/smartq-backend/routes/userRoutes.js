import express from "express";

import {
  createUser,
  getUsers,
  updateUser,
  deleteUser,
} from "../controllers/userController.js";

import authMiddleware from "../middleware/authMiddleware.js";
import roleMiddleware from "../middleware/roleMiddleware.js";

const router = express.Router();

/*
|--------------------------------------------------------------------------
| View Users
|--------------------------------------------------------------------------
*/

router.get(
  "/",
  authMiddleware,
  roleMiddleware(
    "super_admin",
    "hospital_admin",
  ),
  getUsers,
);

/*
|--------------------------------------------------------------------------
| Create User
|--------------------------------------------------------------------------
*/

router.post(
  "/",
  authMiddleware,
  roleMiddleware("super_admin"),
  createUser,
);

/*
|--------------------------------------------------------------------------
| Update User
|--------------------------------------------------------------------------
*/

router.put(
  "/:id",
  authMiddleware,
  roleMiddleware("super_admin"),
  updateUser,
);

/*
|--------------------------------------------------------------------------
| Delete User
|--------------------------------------------------------------------------
*/

router.delete(
  "/:id",
  authMiddleware,
  roleMiddleware("super_admin"),
  deleteUser,
);

export default router;