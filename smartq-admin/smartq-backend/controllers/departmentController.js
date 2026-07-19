import mongoose from "mongoose";

import Department from "../models/Department.js";

/*
|--------------------------------------------------------------------------
| Helper Functions
|--------------------------------------------------------------------------
*/

const getObjectIdString = (value) => {
  if (!value) {
    return "";
  }

  if (value._id) {
    return value._id.toString();
  }

  return value.toString();
};

const normalizeDepartmentData = (body = {}) => {
  const data = {};

  if (typeof body.name === "string") {
    data.name = body.name.trim();
  }

  if (typeof body.prefix === "string") {
    data.prefix = body.prefix.trim().toUpperCase();
  }

  if (body.hospital) {
    data.hospital = body.hospital;
  }

  return data;
};

const getAccessFilter = (req) => {
  const role = req.user?.role;

  if (role === "hospital_admin") {
    return {
      hospital: req.user.hospital,
    };
  }

  if (role === "department_admin") {
    return {
      _id: req.user.department,
    };
  }

  if (role === "receptionist") {
    return {
      hospital: req.user.hospital,
    };
  }

  return {};
};

/*
|--------------------------------------------------------------------------
| Create Department
|--------------------------------------------------------------------------
*/

export const createDepartment = async (
  req,
  res,
) => {
  try {
    const data = normalizeDepartmentData(
      req.body,
    );

    if (!data.name) {
      return res.status(400).json({
        message: "Department name is required",
      });
    }

    if (!data.prefix) {
      return res.status(400).json({
        message: "Department prefix is required",
      });
    }

    if (
      req.user.role ===
      "hospital_admin"
    ) {
      data.hospital = req.user.hospital;
    }

    if (!data.hospital) {
      return res.status(400).json({
        message: "Hospital is required",
      });
    }

    const duplicate =
      await Department.findOne({
        hospital: data.hospital,
        name: {
          $regex: `^${data.name}$`,
          $options: "i",
        },
      });

    if (duplicate) {
      return res.status(409).json({
        message:
          "Department already exists in this hospital",
      });
    }

    const department =
      await Department.create(data);

    const populated =
      await Department.findById(
        department._id,
      ).populate(
        "hospital",
        "name city",
      );

    return res.status(201).json({
      message:
        "Department created successfully",
      department: populated,
    });
  } catch (error) {
    console.error(
      "Department creation error:",
      error,
    );

    return res.status(500).json({
      message:
        error.message ||
        "Failed to create department",
    });
  }
};

/*
|--------------------------------------------------------------------------
| Get Departments
|--------------------------------------------------------------------------
*/

export const getDepartments = async (
  req,
  res,
) => {
  try {
    const departments =
      await Department.find(
        getAccessFilter(req),
      )
        .populate(
          "hospital",
          "name city",
        )
        .sort({
          createdAt: -1,
          name: 1,
        });

    return res.json(departments);
  } catch (error) {
    console.error(
      "Department loading error:",
      error,
    );

    return res.status(500).json({
      message:
        error.message ||
        "Failed to load departments",
    });
  }
};

/*
|--------------------------------------------------------------------------
| Get Department By ID
|--------------------------------------------------------------------------
*/

export const getDepartmentById =
  async (req, res) => {
    try {
      if (
        !mongoose.Types.ObjectId.isValid(
          req.params.id,
        )
      ) {
        return res.status(400).json({
          message:
            "Invalid department ID",
        });
      }

      const department =
        await Department.findOne({
          _id: req.params.id,
          ...getAccessFilter(req),
        }).populate(
          "hospital",
          "name city",
        );

      if (!department) {
        return res.status(404).json({
          message:
            "Department not found or access denied",
        });
      }

      return res.json(department);
    } catch (error) {
      console.error(error);

      return res.status(500).json({
        message:
          error.message ||
          "Failed to load department",
      });
    }
  };

/*
|--------------------------------------------------------------------------
| Update Department
|--------------------------------------------------------------------------
*/

export const updateDepartment =
  async (req, res) => {
    try {
      if (
        !mongoose.Types.ObjectId.isValid(
          req.params.id,
        )
      ) {
        return res.status(400).json({
          message:
            "Invalid department ID",
        });
      }

      const updates =
        normalizeDepartmentData(
          req.body,
        );

      if (
        req.user.role !==
        "super_admin"
      ) {
        delete updates.hospital;
      }

      const department =
        await Department.findOneAndUpdate(
          {
            _id: req.params.id,
            ...getAccessFilter(req),
          },
          {
            $set: updates,
          },
          {
            new: true,
            runValidators: true,
          },
        ).populate(
          "hospital",
          "name city",
        );

      if (!department) {
        return res.status(404).json({
          message:
            "Department not found or access denied",
        });
      }

      return res.json({
        message:
          "Department updated successfully",
        department,
      });
    } catch (error) {
      console.error(
        "Department update error:",
        error,
      );

      return res.status(500).json({
        message:
          error.message ||
          "Failed to update department",
      });
    }
  };

/*
|--------------------------------------------------------------------------
| Delete Department
|--------------------------------------------------------------------------
*/

export const deleteDepartment =
  async (req, res) => {
    try {
      if (
        !mongoose.Types.ObjectId.isValid(
          req.params.id,
        )
      ) {
        return res.status(400).json({
          message:
            "Invalid department ID",
        });
      }

      const filter = {
        _id: req.params.id,
      };

      if (
        req.user.role ===
        "hospital_admin"
      ) {
        filter.hospital =
          req.user.hospital;
      }

      const department =
        await Department.findOneAndDelete(
          filter,
        );

      if (!department) {
        return res.status(404).json({
          message:
            "Department not found or access denied",
        });
      }

      return res.json({
        message:
          "Department deleted successfully",
      });
    } catch (error) {
      console.error(
        "Department deletion error:",
        error,
      );

      return res.status(500).json({
        message:
          error.message ||
          "Failed to delete department",
      });
    }
  };