import {
  useCallback,
  useEffect,
  useMemo,
  useState,
} from "react";

import api from "../services/api";

function UserManagement() {
  const [users, setUsers] = useState([]);
  const [hospitals, setHospitals] =
    useState([]);
  const [departments, setDepartments] =
    useState([]);

  const [fullName, setFullName] =
    useState("");
  const [email, setEmail] =
    useState("");
  const [password, setPassword] =
    useState("");
  const [role, setRole] =
    useState("hospital_admin");
  const [hospital, setHospital] =
    useState("");
  const [department, setDepartment] =
    useState("");

  const [loading, setLoading] =
    useState(true);
  const [submitting, setSubmitting] =
    useState(false);
  const [actionUserId, setActionUserId] =
    useState("");

  const [errorMessage, setErrorMessage] =
    useState("");
  const [successMessage, setSuccessMessage] =
    useState("");

  const loadData = useCallback(async () => {
    try {
      setLoading(true);
      setErrorMessage("");

      const [
        userResponse,
        hospitalResponse,
        departmentResponse,
      ] = await Promise.all([
        api.get("/users"),
        api.get("/hospitals"),
        api.get("/departments"),
      ]);

      setUsers(
        Array.isArray(userResponse.data)
          ? userResponse.data
          : [],
      );

      setHospitals(
        Array.isArray(hospitalResponse.data)
          ? hospitalResponse.data
          : [],
      );

      setDepartments(
        Array.isArray(departmentResponse.data)
          ? departmentResponse.data
          : [],
      );
    } catch (error) {
      console.error(
        "User management loading error:",
        error,
      );

      setErrorMessage(
        getErrorMessage(
          error,
          "Failed to load user management data.",
        ),
      );
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadData();
  }, [loadData]);

  const selectedDepartment = useMemo(
    () =>
      departments.find(
        (item) => item._id === department,
      ) ?? null,
    [department, departments],
  );

  const resetForm = () => {
    setFullName("");
    setEmail("");
    setPassword("");
    setRole("hospital_admin");
    setHospital("");
    setDepartment("");
  };

  const handleRoleChange = (event) => {
    const selectedRole =
      event.target.value;

    setRole(selectedRole);
    setHospital("");
    setDepartment("");
    setErrorMessage("");
    setSuccessMessage("");
  };

  const addUser = async (event) => {
    event.preventDefault();

    const normalizedName =
      fullName.trim();

    const normalizedEmail =
      email.trim().toLowerCase();

    if (
      !normalizedName ||
      !normalizedEmail ||
      !password ||
      !role
    ) {
      setErrorMessage(
        "Please fill in all required fields.",
      );
      return;
    }

    if (password.length < 6) {
      setErrorMessage(
        "Temporary password must contain at least 6 characters.",
      );
      return;
    }

    let selectedHospitalId = null;
    let selectedDepartmentId = null;

    if (role === "hospital_admin") {
      if (!hospital) {
        setErrorMessage(
          "Please select a hospital.",
        );
        return;
      }

      selectedHospitalId = hospital;
    }

    if (role === "department_admin") {
      if (!department) {
        setErrorMessage(
          "Please select a department.",
        );
        return;
      }

      selectedDepartmentId =
        department;

      selectedHospitalId =
        getHospitalId(
          selectedDepartment?.hospital,
        );

      if (!selectedHospitalId) {
        setErrorMessage(
          "The selected department does not have a valid hospital assignment.",
        );
        return;
      }
    }

    try {
      setSubmitting(true);
      setErrorMessage("");
      setSuccessMessage("");

      const response = await api.post(
        "/users",
        {
          fullName: normalizedName,
          email: normalizedEmail,
          password,
          role,
          hospital:
            selectedHospitalId,
          department:
            selectedDepartmentId,
          status: "Active",
        },
      );

      setSuccessMessage(
        response.data?.message ??
          `Admin created successfully. Email: ${normalizedEmail}`,
      );

      resetForm();

      await loadData();
    } catch (error) {
      console.error(
        "Admin creation error:",
        error,
      );

      setErrorMessage(
        getErrorMessage(
          error,
          "Failed to create the admin account.",
        ),
      );
    } finally {
      setSubmitting(false);
    }
  };

  const toggleStatus = async (user) => {
    if (!user?._id) {
      return;
    }

    const nextStatus =
      user.status === "Active"
        ? "Inactive"
        : "Active";

    try {
      setActionUserId(user._id);
      setErrorMessage("");
      setSuccessMessage("");

      await api.put(
        `/users/${user._id}`,
        {
          status: nextStatus,
        },
      );

      setSuccessMessage(
        `User ${nextStatus === "Active"
          ? "activated"
          : "disabled"} successfully.`,
      );

      await loadData();
    } catch (error) {
      console.error(
        "User status update error:",
        error,
      );

      setErrorMessage(
        getErrorMessage(
          error,
          "Failed to update user status.",
        ),
      );
    } finally {
      setActionUserId("");
    }
  };

  const deleteUser = async (id) => {
    if (!id) {
      return;
    }

    const confirmed =
      window.confirm(
        "Are you sure you want to delete this user?",
      );

    if (!confirmed) {
      return;
    }

    try {
      setActionUserId(id);
      setErrorMessage("");
      setSuccessMessage("");

      await api.delete(
        `/users/${id}`,
      );

      setSuccessMessage(
        "User deleted successfully.",
      );

      await loadData();
    } catch (error) {
      console.error(
        "User deletion error:",
        error,
      );

      setErrorMessage(
        getErrorMessage(
          error,
          "Failed to delete the user.",
        ),
      );
    } finally {
      setActionUserId("");
    }
  };

  return (
    <div>
      <h1>User Management</h1>

      <p style={subtitle}>
        Create and manage admin accounts
      </p>

      {errorMessage && (
        <div style={errorBox}>
          <span>{errorMessage}</span>

          <button
            type="button"
            style={messageCloseButton}
            onClick={() =>
              setErrorMessage("")
            }
          >
            ×
          </button>
        </div>
      )}

      {successMessage && (
        <div style={successBox}>
          <span>{successMessage}</span>

          <button
            type="button"
            style={messageCloseButton}
            onClick={() =>
              setSuccessMessage("")
            }
          >
            ×
          </button>
        </div>
      )}

      <form
        style={formBox}
        onSubmit={addUser}
      >
        <input
          style={input}
          placeholder="Full Name"
          value={fullName}
          disabled={submitting}
          onChange={(event) =>
            setFullName(
              event.target.value,
            )
          }
        />

        <input
          style={input}
          type="email"
          placeholder="Email Address"
          value={email}
          disabled={submitting}
          onChange={(event) =>
            setEmail(
              event.target.value,
            )
          }
        />

        <input
          style={input}
          type="password"
          placeholder="Temporary Password"
          value={password}
          disabled={submitting}
          onChange={(event) =>
            setPassword(
              event.target.value,
            )
          }
        />

        <select
          style={input}
          value={role}
          disabled={submitting}
          onChange={handleRoleChange}
        >
          <option value="super_admin">
            Super Admin
          </option>

          <option value="hospital_admin">
            Hospital Admin
          </option>

          <option value="department_admin">
            Department Admin
          </option>
        </select>

        {role === "hospital_admin" && (
          <select
            style={input}
            value={hospital}
            disabled={submitting}
            onChange={(event) =>
              setHospital(
                event.target.value,
              )
            }
          >
            <option value="">
              Select Hospital
            </option>

            {hospitals.map(
              (hospitalItem) => (
                <option
                  key={hospitalItem._id}
                  value={hospitalItem._id}
                >
                  {hospitalItem.name}
                </option>
              ),
            )}
          </select>
        )}

        {role === "department_admin" && (
          <select
            style={input}
            value={department}
            disabled={submitting}
            onChange={(event) =>
              setDepartment(
                event.target.value,
              )
            }
          >
            <option value="">
              Select Department
            </option>

            {departments.map(
              (departmentItem) => (
                <option
                  key={departmentItem._id}
                  value={departmentItem._id}
                >
                  {getDepartmentLabel(
                    departmentItem,
                  )}
                </option>
              ),
            )}
          </select>
        )}

        <button
          type="submit"
          style={{
            ...button,
            opacity: submitting
              ? 0.65
              : 1,
          }}
          disabled={submitting}
        >
          {submitting
            ? "Creating..."
            : "Add Admin"}
        </button>
      </form>

      <div style={tableBox}>
        {loading ? (
          <p style={emptyText}>
            Loading users...
          </p>
        ) : (
          <div style={tableContainer}>
            <table style={table}>
              <thead>
                <tr>
                  <th style={th}>
                    Name
                  </th>
                  <th style={th}>
                    Email
                  </th>
                  <th style={th}>
                    Role
                  </th>
                  <th style={th}>
                    Assigned
                  </th>
                  <th style={th}>
                    Status
                  </th>
                  <th style={th}>
                    Actions
                  </th>
                </tr>
              </thead>

              <tbody>
                {users.map((user) => {
                  const isActionLoading =
                    actionUserId ===
                    user._id;

                  return (
                    <tr key={user._id}>
                      <td style={td}>
                        {user.fullName}
                      </td>

                      <td style={td}>
                        {user.email}
                      </td>

                      <td style={td}>
                        {user.role}
                      </td>

                      <td style={td}>
                        {user.department?.name ??
                          user.hospital?.name ??
                          "-"}
                      </td>

                      <td style={td}>
                        <span
                          style={
                            user.status ===
                            "Active"
                              ? activeBadge
                              : disabledBadge
                          }
                        >
                          {user.status}
                        </span>
                      </td>

                      <td style={td}>
                        <button
                          type="button"
                          style={editBtn}
                          disabled={
                            isActionLoading
                          }
                          onClick={() =>
                            toggleStatus(
                              user,
                            )
                          }
                        >
                          {isActionLoading
                            ? "Please wait..."
                            : user.status ===
                              "Active"
                            ? "Disable"
                            : "Activate"}
                        </button>

                        <button
                          type="button"
                          style={deleteBtn}
                          disabled={
                            isActionLoading
                          }
                          onClick={() =>
                            deleteUser(
                              user._id,
                            )
                          }
                        >
                          Delete
                        </button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>

            {users.length === 0 && (
              <p style={emptyText}>
                No users found
              </p>
            )}
          </div>
        )}
      </div>
    </div>
  );
}

function getHospitalId(value) {
  if (!value) {
    return "";
  }

  if (typeof value === "string") {
    return value;
  }

  return value._id?.toString() ?? "";
}

function getDepartmentLabel(
  department,
) {
  const departmentName =
    department?.name ??
    "Unnamed Department";

  const hospitalName =
    typeof department?.hospital ===
    "object"
      ? department.hospital?.name
      : "";

  return hospitalName
    ? `${departmentName} - ${hospitalName}`
    : departmentName;
}

function getErrorMessage(
  error,
  fallback,
) {
  return (
    error?.response?.data?.message ??
    error?.message ??
    fallback
  );
}

const subtitle = {
  color: "#6b7280",
  marginBottom: "20px",
};

const formBox = {
  background: "#ffffff",
  padding: "20px",
  borderRadius: "16px",
  display: "grid",
  gridTemplateColumns:
    "repeat(3, minmax(0, 1fr))",
  gap: "12px",
  marginBottom: "24px",
};

const input = {
  width: "100%",
  boxSizing: "border-box",
  padding: "12px",
  border: "1px solid #e5e7eb",
  borderRadius: "10px",
};

const button = {
  minHeight: "42px",
  background: "#2563eb",
  color: "#ffffff",
  border: "none",
  borderRadius: "10px",
  cursor: "pointer",
  fontWeight: 700,
};

const tableBox = {
  background: "#ffffff",
  padding: "20px",
  borderRadius: "16px",
};

const tableContainer = {
  width: "100%",
  overflowX: "auto",
};

const table = {
  width: "100%",
  borderCollapse: "collapse",
  minWidth: "850px",
};

const th = {
  textAlign: "left",
  padding: "14px",
  borderBottom:
    "1px solid #e5e7eb",
};

const td = {
  padding: "14px",
  borderBottom:
    "1px solid #f1f5f9",
};

const activeBadge = {
  display: "inline-block",
  background: "#dcfce7",
  color: "#15803d",
  padding: "6px 12px",
  borderRadius: "20px",
};

const disabledBadge = {
  display: "inline-block",
  background: "#fee2e2",
  color: "#b91c1c",
  padding: "6px 12px",
  borderRadius: "20px",
};

const editBtn = {
  marginRight: "8px",
  padding: "7px 12px",
  border: "none",
  borderRadius: "8px",
  background: "#e0f2fe",
  color: "#0369a1",
  cursor: "pointer",
};

const deleteBtn = {
  padding: "7px 12px",
  border: "none",
  borderRadius: "8px",
  background: "#fee2e2",
  color: "#b91c1c",
  cursor: "pointer",
};

const errorBox = {
  display: "flex",
  justifyContent: "space-between",
  alignItems: "center",
  gap: "12px",
  background: "#fef2f2",
  color: "#991b1b",
  border: "1px solid #fecaca",
  padding: "14px 16px",
  borderRadius: "12px",
  marginBottom: "16px",
};

const successBox = {
  display: "flex",
  justifyContent: "space-between",
  alignItems: "center",
  gap: "12px",
  background: "#f0fdf4",
  color: "#166534",
  border: "1px solid #bbf7d0",
  padding: "14px 16px",
  borderRadius: "12px",
  marginBottom: "16px",
};

const messageCloseButton = {
  border: "none",
  background: "transparent",
  color: "inherit",
  cursor: "pointer",
  fontSize: "20px",
};

const emptyText = {
  textAlign: "center",
  color: "#6b7280",
};

export default UserManagement;