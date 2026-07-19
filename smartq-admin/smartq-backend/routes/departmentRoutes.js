import express from "express";

import {
  createDepartment,
  deleteDepartment,
  getDepartmentById,
  getDepartments,
  updateDepartment,
} from "../controllers/departmentController.js";

import authMiddleware from "../middleware/authMiddleware.js";
import roleMiddleware from "../middleware/roleMiddleware.js";

const router = express.Router();

const departmentViewRoles = [
  "super_admin",
  "hospital_admin",
  "department_admin",
  "receptionist",
];

const departmentManagementRoles = [
  "super_admin",
  "hospital_admin",
];

/*
|--------------------------------------------------------------------------
| Get Departments
|--------------------------------------------------------------------------
|
| The controller applies role-based filtering:
|
| super_admin       -> all departments
| hospital_admin    -> departments in assigned hospital
| department_admin  -> assigned department only
| receptionist      -> departments in assigned hospital
|
*/

router.get(
  "/",
  authMiddleware,
  roleMiddleware(...departmentViewRoles),
  getDepartments,
);

/*
|--------------------------------------------------------------------------
| Get Department by ID
|--------------------------------------------------------------------------
*/

router.get(
  "/:id",
  authMiddleware,
  roleMiddleware(...departmentViewRoles),
  getDepartmentById,
);

/*
|--------------------------------------------------------------------------
| Create Department
|--------------------------------------------------------------------------
*/

router.post(
  "/",
  authMiddleware,
  roleMiddleware(...departmentManagementRoles),
  createDepartment,
);

/*
|--------------------------------------------------------------------------
| Update Department
|--------------------------------------------------------------------------
*/

router.put(
  "/:id",
  authMiddleware,
  roleMiddleware(...departmentManagementRoles),
  updateDepartment,
);

/*
|--------------------------------------------------------------------------
| Delete Department
|--------------------------------------------------------------------------
|
| Only the super admin can permanently delete departments.
|
*/

router.delete(
  "/:id",
  authMiddleware,
  roleMiddleware("super_admin"),
  deleteDepartment,
);

export default router;