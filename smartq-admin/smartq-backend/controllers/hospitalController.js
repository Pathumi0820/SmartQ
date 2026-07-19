import mongoose from "mongoose";

import Hospital from "../models/Hospital.js";

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

const normalizeHospitalData = (body = {}) => {
  const data = {};

  if (typeof body.name === "string") {
    data.name = body.name.trim();
  }

  if (typeof body.city === "string") {
    data.city = body.city.trim();
  }

  if (typeof body.address === "string") {
    data.address = body.address.trim();
  }

  if (typeof body.phone === "string") {
    data.phone = body.phone.trim();
  }

  if (typeof body.email === "string") {
    data.email = body.email
      .trim()
      .toLowerCase();
  }

  if (typeof body.status === "string") {
    data.status = body.status.trim();
  }

  return data;
};

const getHospitalAccessFilter = (req) => {
  const role = req.user?.role;

  if (
    role === "hospital_admin" ||
    role === "department_admin"
  ) {
    const hospitalId =
      getObjectIdString(
        req.user?.hospital,
      );

    if (!hospitalId) {
      return {
        _id: null,
      };
    }

    return {
      _id: hospitalId,
    };
  }

  return {};
};

/*
|--------------------------------------------------------------------------
| Create Hospital
|--------------------------------------------------------------------------
*/

export const createHospital = async (
  req,
  res,
) => {
  try {
    if (
      req.user?.role !==
      "super_admin"
    ) {
      return res.status(403).json({
        message:
          "Only super administrators can create hospitals",
      });
    }

    const hospitalData =
      normalizeHospitalData(
        req.body,
      );

    if (!hospitalData.name) {
      return res.status(400).json({
        message:
          "Hospital name is required",
      });
    }

    const existingHospital =
      await Hospital.findOne({
        name: {
          $regex:
            `^${escapeRegex(
              hospitalData.name,
            )}$`,
          $options: "i",
        },
      }).lean();

    if (existingHospital) {
      return res.status(409).json({
        message:
          "A hospital with this name already exists",
      });
    }

    const hospital =
      await Hospital.create(
        hospitalData,
      );

    return res.status(201).json({
      message:
        "Hospital created successfully",
      hospital,
    });
  } catch (error) {
    console.error(
      "Hospital creation error:",
      error,
    );

    return res.status(500).json({
      message:
        error.message ||
        "Failed to create hospital",
    });
  }
};

/*
|--------------------------------------------------------------------------
| Get Hospitals
|--------------------------------------------------------------------------
|
| super_admin:
|   Returns all hospitals.
|
| hospital_admin:
|   Returns only the hospital assigned to the logged-in user.
|
| department_admin:
|   Returns only the hospital assigned to the logged-in user.
|
*/

export const getHospitals = async (
  req,
  res,
) => {
  try {
    const filter =
      getHospitalAccessFilter(req);

    const hospitals =
      await Hospital.find(filter)
        .sort({
          createdAt: -1,
          name: 1,
        })
        .lean();

    return res.json(hospitals);
  } catch (error) {
    console.error(
      "Hospital loading error:",
      error,
    );

    return res.status(500).json({
      message:
        error.message ||
        "Failed to load hospitals",
    });
  }
};

/*
|--------------------------------------------------------------------------
| Get Hospital by ID
|--------------------------------------------------------------------------
*/

export const getHospitalById = async (
  req,
  res,
) => {
  try {
    const { id } = req.params;

    if (
      !mongoose.Types.ObjectId
        .isValid(id)
    ) {
      return res.status(400).json({
        message:
          "Invalid hospital ID",
      });
    }

    const accessFilter =
      getHospitalAccessFilter(req);

    const hospital =
      await Hospital.findOne({
        _id: id,
        ...accessFilter,
      }).lean();

    if (!hospital) {
      return res.status(404).json({
        message:
          "Hospital not found or access denied",
      });
    }

    return res.json(hospital);
  } catch (error) {
    console.error(
      "Hospital loading error:",
      error,
    );

    return res.status(500).json({
      message:
        error.message ||
        "Failed to load hospital",
    });
  }
};

/*
|--------------------------------------------------------------------------
| Update Hospital
|--------------------------------------------------------------------------
*/

export const updateHospital = async (
  req,
  res,
) => {
  try {
    const { id } = req.params;

    if (
      req.user?.role !==
      "super_admin"
    ) {
      return res.status(403).json({
        message:
          "Only super administrators can update hospitals",
      });
    }

    if (
      !mongoose.Types.ObjectId
        .isValid(id)
    ) {
      return res.status(400).json({
        message:
          "Invalid hospital ID",
      });
    }

    const updates =
      normalizeHospitalData(
        req.body,
      );

    if (
      Object.keys(updates).length ===
      0
    ) {
      return res.status(400).json({
        message:
          "No valid hospital fields were provided",
      });
    }

    if (
      Object.prototype.hasOwnProperty.call(
        updates,
        "name",
      ) &&
      !updates.name
    ) {
      return res.status(400).json({
        message:
          "Hospital name cannot be empty",
      });
    }

    if (updates.name) {
      const duplicateHospital =
        await Hospital.findOne({
          _id: {
            $ne: id,
          },
          name: {
            $regex:
              `^${escapeRegex(
                updates.name,
              )}$`,
            $options: "i",
          },
        }).lean();

      if (duplicateHospital) {
        return res.status(409).json({
          message:
            "A hospital with this name already exists",
        });
      }
    }

    const hospital =
      await Hospital.findByIdAndUpdate(
        id,
        {
          $set: updates,
        },
        {
          returnDocument: "after",
          runValidators: true,
        },
      );

    if (!hospital) {
      return res.status(404).json({
        message:
          "Hospital not found",
      });
    }

    return res.json({
      message:
        "Hospital updated successfully",
      hospital,
    });
  } catch (error) {
    console.error(
      "Hospital update error:",
      error,
    );

    return res.status(500).json({
      message:
        error.message ||
        "Failed to update hospital",
    });
  }
};

/*
|--------------------------------------------------------------------------
| Delete Hospital
|--------------------------------------------------------------------------
*/

export const deleteHospital = async (
  req,
  res,
) => {
  try {
    const { id } = req.params;

    if (
      req.user?.role !==
      "super_admin"
    ) {
      return res.status(403).json({
        message:
          "Only super administrators can delete hospitals",
      });
    }

    if (
      !mongoose.Types.ObjectId
        .isValid(id)
    ) {
      return res.status(400).json({
        message:
          "Invalid hospital ID",
      });
    }

    const hospital =
      await Hospital.findByIdAndDelete(
        id,
      );

    if (!hospital) {
      return res.status(404).json({
        message:
          "Hospital not found",
      });
    }

    return res.json({
      message:
        "Hospital deleted successfully",
    });
  } catch (error) {
    console.error(
      "Hospital deletion error:",
      error,
    );

    return res.status(500).json({
      message:
        error.message ||
        "Failed to delete hospital",
    });
  }
};

/*
|--------------------------------------------------------------------------
| Utility
|--------------------------------------------------------------------------
*/

function escapeRegex(value) {
  return value.replace(
    /[.*+?^${}()|[\]\\]/g,
    "\\$&",
  );
}