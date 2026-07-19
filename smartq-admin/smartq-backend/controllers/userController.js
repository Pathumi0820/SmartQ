import bcrypt from "bcryptjs";

import User from "../models/User.js";

const allowedRoles = [
  "super_admin",
  "hospital_admin",
  "department_admin",
  "receptionist",
];

const allowedStatuses = [
  "Active",
  "Inactive",
];

/*
|--------------------------------------------------------------------------
| Create User
|--------------------------------------------------------------------------
*/

export const createUser = async (req, res) => {
  try {
    const {
      fullName,
      email,
      password,
      role,
      hospital,
      department,
      status,
    } = req.body;

    const normalizedName =
        typeof fullName === "string"
            ? fullName.trim()
            : "";

    const normalizedEmail =
        typeof email === "string"
            ? email.trim().toLowerCase()
            : "";

    const normalizedPassword =
        typeof password === "string"
            ? password
            : "";

    const normalizedRole =
        typeof role === "string"
            ? role.trim()
            : "";

    const normalizedStatus =
        typeof status === "string" &&
        status.trim().isNotEmpty
            ? status.trim()
            : "Active";

    if (
      !normalizedName ||
      !normalizedEmail ||
      !normalizedPassword ||
      !normalizedRole
    ) {
      return res.status(400).json({
        message:
            "Full name, email, password and role are required",
      });
    }

    if (
      !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(
        normalizedEmail,
      )
    ) {
      return res.status(400).json({
        message: "Please enter a valid email address",
      });
    }

    if (normalizedPassword.length < 6) {
      return res.status(400).json({
        message:
            "Password must contain at least 6 characters",
      });
    }

    if (
      !allowedRoles.includes(
        normalizedRole,
      )
    ) {
      return res.status(400).json({
        message: "Invalid user role",
      });
    }

    if (
      !allowedStatuses.includes(
        normalizedStatus,
      )
    ) {
      return res.status(400).json({
        message: "Invalid user status",
      });
    }

    const existingUser = await User.findOne({
      email: normalizedEmail,
    }).lean();

    if (existingUser) {
      return res.status(409).json({
        message: "User already exists",
      });
    }

    const hashedPassword = await bcrypt.hash(
      normalizedPassword,
      10,
    );

    const user = await User.create({
      fullName: normalizedName,
      email: normalizedEmail,
      password: hashedPassword,
      role: normalizedRole,
      hospital: hospital || null,
      department: department || null,
      status: normalizedStatus,
      isFirstLogin: true,
    });

    const safeUser = await User.findById(
      user._id,
    )
      .select("-password")
      .populate("hospital", "name city")
      .populate(
        "department",
        "name prefix",
      );

    return res.status(201).json({
      message: "User created successfully",
      user: safeUser,
    });
  } catch (error) {
    console.error(
      "User creation error:",
      error,
    );

    return res.status(500).json({
      message:
          error.message ||
          "Failed to create user",
    });
  }
};

/*
|--------------------------------------------------------------------------
| Get Users
|--------------------------------------------------------------------------
*/

export const getUsers = async (req, res) => {
  try {
    const filter = {};

    if (
      req.user?.role ===
      "hospital_admin"
    ) {
      filter.hospital = req.user.hospital;
    }

    const users = await User.find(filter)
      .select("-password")
      .populate("hospital", "name city")
      .populate(
        "department",
        "name prefix",
      )
      .sort({
        createdAt: -1,
      });

    return res.json(users);
  } catch (error) {
    console.error(
      "User loading error:",
      error,
    );

    return res.status(500).json({
      message:
          error.message ||
          "Failed to load users",
    });
  }
};

/*
|--------------------------------------------------------------------------
| Update User
|--------------------------------------------------------------------------
*/

export const updateUser = async (req, res) => {
  try {
    const { id } = req.params;

    const existingUser =
        await User.findById(id);

    if (!existingUser) {
      return res.status(404).json({
        message: "User not found",
      });
    }

    const updates = {};

    if (
      typeof req.body.fullName ===
      "string"
    ) {
      const fullName =
          req.body.fullName.trim();

      if (!fullName) {
        return res.status(400).json({
          message:
              "Full name cannot be empty",
        });
      }

      updates.fullName = fullName;
    }

    if (
      typeof req.body.email === "string"
    ) {
      const email =
          req.body.email
              .trim()
              .toLowerCase();

      if (
        !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(
          email,
        )
      ) {
        return res.status(400).json({
          message:
              "Please enter a valid email address",
        });
      }

      const duplicateUser =
          await User.findOne({
            email,
            _id: {
              $ne: id,
            },
          }).lean();

      if (duplicateUser) {
        return res.status(409).json({
          message:
              "Another user already uses this email",
        });
      }

      updates.email = email;
    }

    if (
      typeof req.body.password ===
        "string" &&
      req.body.password.isNotEmpty
    ) {
      if (
        req.body.password.length < 6
      ) {
        return res.status(400).json({
          message:
              "Password must contain at least 6 characters",
        });
      }

      updates.password =
          await bcrypt.hash(
        req.body.password,
        10,
      );

      updates.isFirstLogin = true;
    }

    if (
      typeof req.body.role === "string"
    ) {
      const role =
          req.body.role.trim();

      if (
        !allowedRoles.includes(role)
      ) {
        return res.status(400).json({
          message: "Invalid user role",
        });
      }

      updates.role = role;
    }

    if (
      typeof req.body.status ===
      "string"
    ) {
      const status =
          req.body.status.trim();

      if (
        !allowedStatuses.includes(
          status,
        )
      ) {
        return res.status(400).json({
          message:
              "Invalid user status",
        });
      }

      updates.status = status;
    }

    if (
      Object.prototype.hasOwnProperty.call(
        req.body,
        "hospital",
      )
    ) {
      updates.hospital =
          req.body.hospital || null;
    }

    if (
      Object.prototype.hasOwnProperty.call(
        req.body,
        "department",
      )
    ) {
      updates.department =
          req.body.department || null;
    }

    if (
      Object.keys(updates).length === 0
    ) {
      return res.status(400).json({
        message:
            "No valid user fields provided",
      });
    }

    const user =
        await User.findByIdAndUpdate(
      id,
      {
        $set: updates,
      },
      {
        returnDocument: "after",
        runValidators: true,
      },
    )
      .select("-password")
      .populate("hospital", "name city")
      .populate(
        "department",
        "name prefix",
      );

    return res.json({
      message: "User updated successfully",
      user,
    });
  } catch (error) {
    console.error(
      "User update error:",
      error,
    );

    return res.status(500).json({
      message:
          error.message ||
          "Failed to update user",
    });
  }
};

/*
|--------------------------------------------------------------------------
| Delete User
|--------------------------------------------------------------------------
*/

export const deleteUser = async (req, res) => {
  try {
    const user =
        await User.findByIdAndDelete(
          req.params.id,
        );

    if (!user) {
      return res.status(404).json({
        message: "User not found",
      });
    }

    return res.json({
      message: "User deleted successfully",
    });
  } catch (error) {
    console.error(
      "User deletion error:",
      error,
    );

    return res.status(500).json({
      message:
          error.message ||
          "Failed to delete user",
    });
  }
};