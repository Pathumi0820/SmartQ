import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";

import User from "../models/User.js";

export const loginUser = async (req, res) => {
  try {
    const email = req.body.email?.trim().toLowerCase();
    const password = req.body.password?.toString() ?? "";

    if (!email || !password) {
      return res.status(400).json({
        message: "Email and password are required",
      });
    }

    const user = await User.findOne({ email })
      .populate("hospital", "name hospitalName")
      .populate("department", "name departmentName");

    if (!user) {
      return res.status(400).json({
        message: "Invalid email or password",
      });
    }

    if (user.status !== "Active") {
      return res.status(403).json({
        message: "Your account is inactive",
      });
    }

    const isPasswordValid = await bcrypt.compare(
      password,
      user.password,
    );

    if (!isPasswordValid) {
      return res.status(400).json({
        message: "Invalid email or password",
      });
    }

    if (!process.env.JWT_SECRET) {
      return res.status(500).json({
        message: "JWT secret is not configured",
      });
    }

    const hospitalId =
      user.hospital?._id?.toString() || "";

    const hospitalName =
      user.hospital?.name?.trim() ||
      user.hospital?.hospitalName?.trim() ||
      "";

    const departmentId =
      user.department?._id?.toString() || "";

    const departmentName =
      user.department?.name?.trim() ||
      user.department?.departmentName?.trim() ||
      "";

    const token = jwt.sign(
      {
        id: user._id,
        role: user.role,
        hospitalId,
        departmentId,
      },
      process.env.JWT_SECRET,
      {
        expiresIn: "7d",
      },
    );

    return res.status(200).json({
      message: "Login successful",
      token,
      user: {
        id: user._id,
        fullName: user.fullName,
        email: user.email,
        role: user.role,
        status: user.status,
        isFirstLogin: user.isFirstLogin,

        hospitalId,
        hospitalName,
        hospital: user.hospital
          ? {
              id: hospitalId,
              name: hospitalName,
            }
          : null,

        departmentId,
        departmentName,
        department: user.department
          ? {
              id: departmentId,
              name: departmentName,
            }
          : null,
      },
    });
  } catch (error) {
    console.error("Login error:", error);

    return res.status(500).json({
      message: "Unable to log in",
      error:
        process.env.NODE_ENV === "development"
          ? error.message
          : undefined,
    });
  }
};