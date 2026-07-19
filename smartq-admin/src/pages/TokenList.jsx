import {
  useCallback,
  useEffect,
  useMemo,
  useState,
} from "react";

import api from "../services/api";
import socket from "../services/socket";

function TokenList() {
  const [tokens, setTokens] =
    useState([]);

  const [hospitals, setHospitals] =
    useState([]);

  const [departments, setDepartments] =
    useState([]);

  const [patientName, setPatientName] =
    useState("");

  const [patientPhone, setPatientPhone] =
    useState("");

  const [hospital, setHospital] =
    useState("");

  const [department, setDepartment] =
    useState("");

  const [search, setSearch] =
    useState("");

  const [statusFilter, setStatusFilter] =
    useState("");

  const [
    departmentFilter,
    setDepartmentFilter,
  ] = useState("");

  const [currentPage, setCurrentPage] =
    useState(1);

  const [loading, setLoading] =
    useState(true);

  const [creating, setCreating] =
    useState(false);

  const [actionTokenId, setActionTokenId] =
    useState("");

  const [errorMessage, setErrorMessage] =
    useState("");

  const [successMessage, setSuccessMessage] =
    useState("");

  const recordsPerPage = 5;

  const role =
    localStorage.getItem(
      "userRole",
    ) || "";

  const storedUser =
    getStoredUser();

  const isDepartmentAdmin =
    role === "department_admin";

  const storedHospitalId =
    getObjectId(
      storedUser.hospital,
    );

  const storedDepartmentId =
    getObjectId(
      storedUser.department,
    );

  const assignedHospitalId =
    storedHospitalId ||
    hospitals[0]?._id ||
    "";

  const assignedDepartmentId =
    storedDepartmentId ||
    departments[0]?._id ||
    "";

  /*
  |--------------------------------------------------------------------------
  | Load Tokens, Hospitals and Departments
  |--------------------------------------------------------------------------
  */

  const loadData =
    useCallback(async () => {
      try {
        setLoading(true);
        setErrorMessage("");

        const [
          tokenResponse,
          hospitalResponse,
          departmentResponse,
        ] = await Promise.all([
          api.get("/tokens"),
          api.get("/hospitals"),
          api.get("/departments"),
        ]);

        const loadedTokens =
          getArrayResponse(
            tokenResponse.data,
            "tokens",
          );

        const loadedHospitals =
          getArrayResponse(
            hospitalResponse.data,
            "hospitals",
          );

        const loadedDepartments =
          getArrayResponse(
            departmentResponse.data,
            "departments",
          );

        setTokens(loadedTokens);
        setHospitals(loadedHospitals);
        setDepartments(
          loadedDepartments,
        );
      } catch (error) {
        console.error(
          "Token page loading error:",
          error,
        );

        setErrorMessage(
          getErrorMessage(
            error,
            "Failed to load token information.",
          ),
        );
      } finally {
        setLoading(false);
      }
    }, []);

  useEffect(() => {
    loadData();

    socket.on(
      "tokensUpdated",
      loadData,
    );

    socket.on(
      "dashboardUpdated",
      loadData,
    );

    return () => {
      socket.off(
        "tokensUpdated",
        loadData,
      );

      socket.off(
        "dashboardUpdated",
        loadData,
      );
    };
  }, [loadData]);

  /*
  |--------------------------------------------------------------------------
  | Automatically Select Assigned Hospital and Department
  |--------------------------------------------------------------------------
  */

  useEffect(() => {
    if (!isDepartmentAdmin) {
      return;
    }

    if (assignedHospitalId) {
      setHospital(
        assignedHospitalId,
      );
    }

    if (assignedDepartmentId) {
      setDepartment(
        assignedDepartmentId,
      );

      setDepartmentFilter(
        assignedDepartmentId,
      );
    }
  }, [
    assignedDepartmentId,
    assignedHospitalId,
    isDepartmentAdmin,
  ]);

  /*
  |--------------------------------------------------------------------------
  | Visible Hospital and Department Lists
  |--------------------------------------------------------------------------
  */

  const visibleHospitals =
    useMemo(() => {
      if (!isDepartmentAdmin) {
        return hospitals;
      }

      return hospitals.filter(
        (hospitalItem) =>
          hospitalItem._id ===
          assignedHospitalId,
      );
    }, [
      assignedHospitalId,
      hospitals,
      isDepartmentAdmin,
    ]);

  const visibleDepartments =
    useMemo(() => {
      if (!isDepartmentAdmin) {
        return departments;
      }

      return departments.filter(
        (departmentItem) =>
          departmentItem._id ===
          assignedDepartmentId,
      );
    }, [
      assignedDepartmentId,
      departments,
      isDepartmentAdmin,
    ]);

  const selectedHospital =
    useMemo(
      () =>
        visibleHospitals.find(
          (hospitalItem) =>
            hospitalItem._id ===
            hospital,
        ) ?? null,
      [
        hospital,
        visibleHospitals,
      ],
    );

  const selectedDepartment =
    useMemo(
      () =>
        visibleDepartments.find(
          (departmentItem) =>
            departmentItem._id ===
            department,
        ) ?? null,
      [
        department,
        visibleDepartments,
      ],
    );

  const formDepartments =
    useMemo(() => {
      if (isDepartmentAdmin) {
        return visibleDepartments;
      }

      if (!hospital) {
        return [];
      }

      return departments.filter(
        (departmentItem) =>
          getObjectId(
            departmentItem.hospital,
          ) === hospital,
      );
    }, [
      departments,
      hospital,
      isDepartmentAdmin,
      visibleDepartments,
    ]);

  /*
  |--------------------------------------------------------------------------
  | Create Token
  |--------------------------------------------------------------------------
  */

  const createToken = async (
    event,
  ) => {
    event.preventDefault();

    const normalizedName =
      patientName.trim();

    const normalizedPhone =
      patientPhone.trim();

    const selectedHospitalId =
      isDepartmentAdmin
        ? assignedHospitalId
        : hospital;

    const selectedDepartmentId =
      isDepartmentAdmin
        ? assignedDepartmentId
        : department;

    if (
      !normalizedName ||
      !normalizedPhone ||
      !selectedHospitalId ||
      !selectedDepartmentId
    ) {
      setErrorMessage(
        "Patient name, phone number, hospital and department are required.",
      );

      return;
    }

    try {
      setCreating(true);
      setErrorMessage("");
      setSuccessMessage("");

      const response =
        await api.post(
          "/tokens",
          {
            patientName:
              normalizedName,
            patientPhone:
              normalizedPhone,
            hospital:
              selectedHospitalId,
            department:
              selectedDepartmentId,
          },
        );

      setSuccessMessage(
        response.data?.message ??
        "Token created successfully.",
      );

      setPatientName("");
      setPatientPhone("");

      if (!isDepartmentAdmin) {
        setHospital("");
        setDepartment("");
      }

      setCurrentPage(1);

      await loadData();
    } catch (error) {
      console.error(
        "Token creation error:",
        error,
      );

      setErrorMessage(
        getErrorMessage(
          error,
          "Failed to create token.",
        ),
      );
    } finally {
      setCreating(false);
    }
  };

  /*
  |--------------------------------------------------------------------------
  | Update Token Status
  |--------------------------------------------------------------------------
  */

  const updateStatus = async (
    id,
    status,
  ) => {
    if (!id) {
      return;
    }

    try {
      setActionTokenId(id);
      setErrorMessage("");
      setSuccessMessage("");

      const response =
        await api.put(
          `/tokens/${id}/status`,
          {
            status,
          },
        );

      setSuccessMessage(
        response.data?.message ??
        `Token updated to ${status}.`,
      );

      await loadData();
    } catch (error) {
      console.error(
        "Token status update error:",
        error,
      );

      setErrorMessage(
        getErrorMessage(
          error,
          "Failed to update token status.",
        ),
      );
    } finally {
      setActionTokenId("");
    }
  };

  /*
  |--------------------------------------------------------------------------
  | Call Next Patient
  |--------------------------------------------------------------------------
  */

  const callNextPatient =
    async () => {
      const waitingTokens =
        filteredTokens
          .filter(
            (token) =>
              token.status ===
              "Waiting",
          )
          .sort(
            (first, second) =>
              first.tokenNumber -
              second.tokenNumber,
          );

      const nextPatient =
        waitingTokens[0];

      if (!nextPatient) {
        setErrorMessage(
          "No waiting patients are available in this queue.",
        );

        return;
      }

      await updateStatus(
        nextPatient._id,
        "Called",
      );
    };

  /*
  |--------------------------------------------------------------------------
  | Filter Tokens
  |--------------------------------------------------------------------------
  */

  const filteredTokens =
    useMemo(() => {
      const normalizedSearch =
        search
          .trim()
          .toLowerCase();

      return tokens.filter(
        (token) => {
          const tokenCode =
            buildTokenCode(token)
              .toLowerCase();

          const tokenHospitalId =
            getObjectId(
              token.hospital,
            );

          const tokenDepartmentId =
            getObjectId(
              token.department,
            );

          const matchesAssignedHospital =
            !isDepartmentAdmin ||
            !assignedHospitalId ||
            tokenHospitalId ===
              assignedHospitalId;

          const matchesAssignedDepartment =
            !isDepartmentAdmin ||
            !assignedDepartmentId ||
            tokenDepartmentId ===
              assignedDepartmentId;

          const matchesSearch =
            !normalizedSearch ||
            token.patientName
              ?.toLowerCase()
              .includes(
                normalizedSearch,
              ) ||
            token.patientPhone
              ?.toLowerCase()
              .includes(
                normalizedSearch,
              ) ||
            tokenCode.includes(
              normalizedSearch,
            );

          const matchesStatus =
            !statusFilter ||
            token.status ===
              statusFilter;

          const matchesDepartment =
            !departmentFilter ||
            tokenDepartmentId ===
              departmentFilter;

          return (
            matchesAssignedHospital &&
            matchesAssignedDepartment &&
            matchesSearch &&
            matchesStatus &&
            matchesDepartment
          );
        },
      );
    }, [
      assignedDepartmentId,
      assignedHospitalId,
      departmentFilter,
      isDepartmentAdmin,
      search,
      statusFilter,
      tokens,
    ]);

  const totalPages =
    Math.max(
      Math.ceil(
        filteredTokens.length /
        recordsPerPage,
      ),
      1,
    );

  useEffect(() => {
    if (
      currentPage >
      totalPages
    ) {
      setCurrentPage(
        totalPages,
      );
    }
  }, [
    currentPage,
    totalPages,
  ]);

  const paginatedTokens =
    filteredTokens.slice(
      (currentPage - 1) *
        recordsPerPage,
      currentPage *
        recordsPerPage,
    );

  return (
    <div>
      <h1>
        Token Management
      </h1>

      <p style={subtitle}>
        Create and manage patient tokens
      </p>

      {errorMessage && (
        <MessageBox
          type="error"
          message={errorMessage}
          onClose={() =>
            setErrorMessage("")
          }
        />
      )}

      {successMessage && (
        <MessageBox
          type="success"
          message={successMessage}
          onClose={() =>
            setSuccessMessage("")
          }
        />
      )}

      <form
        style={formBox}
        onSubmit={createToken}
      >
        <input
          style={input}
          placeholder="Patient Name"
          value={patientName}
          disabled={creating}
          onChange={(event) =>
            setPatientName(
              event.target.value,
            )
          }
        />

        <input
          style={input}
          type="tel"
          placeholder="Phone Number"
          value={patientPhone}
          disabled={creating}
          onChange={(event) =>
            setPatientPhone(
              event.target.value,
            )
          }
        />

        {isDepartmentAdmin ? (
          <input
            style={disabledInput}
            value={
              selectedHospital
                ?.name ??
              "Assigned Hospital"
            }
            disabled
          />
        ) : (
          <select
            style={input}
            value={hospital}
            disabled={creating}
            onChange={(event) => {
              setHospital(
                event.target.value,
              );

              setDepartment("");
            }}
          >
            <option value="">
              Select Hospital
            </option>

            {visibleHospitals.map(
              (hospitalItem) => (
                <option
                  key={
                    hospitalItem._id
                  }
                  value={
                    hospitalItem._id
                  }
                >
                  {hospitalItem.name}
                </option>
              ),
            )}
          </select>
        )}

        {isDepartmentAdmin ? (
          <input
            style={disabledInput}
            value={
              selectedDepartment
                ?.name ??
              "Assigned Department"
            }
            disabled
          />
        ) : (
          <select
            style={input}
            value={department}
            disabled={
              creating ||
              !hospital
            }
            onChange={(event) =>
              setDepartment(
                event.target.value,
              )
            }
          >
            <option value="">
              Select Department
            </option>

            {formDepartments.map(
              (departmentItem) => (
                <option
                  key={
                    departmentItem._id
                  }
                  value={
                    departmentItem._id
                  }
                >
                  {departmentItem.name}
                </option>
              ),
            )}
          </select>
        )}

        <button
          type="submit"
          style={{
            ...button,
            opacity:
              creating
                ? 0.65
                : 1,
          }}
          disabled={creating}
        >
          {creating
            ? "Creating..."
            : "Add Token"}
        </button>
      </form>

      <button
        type="button"
        style={nextBtn}
        disabled={
          loading ||
          Boolean(
            actionTokenId,
          )
        }
        onClick={
          callNextPatient
        }
      >
        Call Next Patient
      </button>

      <div style={filterBox}>
        <input
          style={input}
          placeholder="Search token, patient or phone"
          value={search}
          onChange={(event) => {
            setSearch(
              event.target.value,
            );

            setCurrentPage(1);
          }}
        />

        <select
          style={input}
          value={statusFilter}
          onChange={(event) => {
            setStatusFilter(
              event.target.value,
            );

            setCurrentPage(1);
          }}
        >
          <option value="">
            All Status
          </option>

          <option value="Waiting">
            Waiting
          </option>

          <option value="Called">
            Called
          </option>

          <option value="Serving">
            Serving
          </option>

          <option value="Completed">
            Completed
          </option>

          <option value="Cancelled">
            Cancelled
          </option>
        </select>

        {isDepartmentAdmin ? (
          <input
            style={disabledInput}
            value={
              selectedDepartment
                ?.name ??
              "Assigned Department"
            }
            disabled
          />
        ) : (
          <select
            style={input}
            value={
              departmentFilter
            }
            onChange={(event) => {
              setDepartmentFilter(
                event.target.value,
              );

              setCurrentPage(1);
            }}
          >
            <option value="">
              All Departments
            </option>

            {visibleDepartments.map(
              (departmentItem) => (
                <option
                  key={
                    departmentItem._id
                  }
                  value={
                    departmentItem._id
                  }
                >
                  {departmentItem.name}
                </option>
              ),
            )}
          </select>
        )}
      </div>

      <div style={tableBox}>
        {loading ? (
          <p style={emptyText}>
            Loading tokens...
          </p>
        ) : (
          <>
            <div style={tableContainer}>
              <table style={table}>
                <thead>
                  <tr>
                    <th style={th}>
                      Token
                    </th>

                    <th style={th}>
                      Patient
                    </th>

                    <th style={th}>
                      Phone
                    </th>

                    <th style={th}>
                      Hospital
                    </th>

                    <th style={th}>
                      Department
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
                  {paginatedTokens.map(
                    (token) => {
                      const isUpdating =
                        actionTokenId ===
                        token._id;

                      return (
                        <tr
                          key={
                            token._id
                          }
                        >
                          <td style={td}>
                            {buildTokenCode(
                              token,
                            )}
                          </td>

                          <td style={td}>
                            {
                              token.patientName
                            }
                          </td>

                          <td style={td}>
                            {token.patientPhone ||
                              "-"}
                          </td>

                          <td style={td}>
                            {token.hospital
                              ?.name ??
                              "-"}
                          </td>

                          <td style={td}>
                            {token.department
                              ?.name ??
                              "-"}
                          </td>

                          <td style={td}>
                            <span
                              style={
                                getStatusBadgeStyle(
                                  token.status,
                                )
                              }
                            >
                              {
                                token.status
                              }
                            </span>
                          </td>

                          <td style={td}>
                            <button
                              type="button"
                              style={callBtn}
                              disabled={
                                isUpdating ||
                                token.status !==
                                  "Waiting"
                              }
                              onClick={() =>
                                updateStatus(
                                  token._id,
                                  "Called",
                                )
                              }
                            >
                              Call
                            </button>

                            <button
                              type="button"
                              style={completeBtn}
                              disabled={
                                isUpdating ||
                                [
                                  "Completed",
                                  "Cancelled",
                                ].includes(
                                  token.status,
                                )
                              }
                              onClick={() =>
                                updateStatus(
                                  token._id,
                                  "Completed",
                                )
                              }
                            >
                              Complete
                            </button>

                            <button
                              type="button"
                              style={cancelBtn}
                              disabled={
                                isUpdating ||
                                [
                                  "Completed",
                                  "Cancelled",
                                ].includes(
                                  token.status,
                                )
                              }
                              onClick={() =>
                                updateStatus(
                                  token._id,
                                  "Cancelled",
                                )
                              }
                            >
                              Cancel
                            </button>
                          </td>
                        </tr>
                      );
                    },
                  )}
                </tbody>
              </table>
            </div>

            {filteredTokens.length ===
              0 && (
              <p style={emptyText}>
                No tokens found
              </p>
            )}

            {filteredTokens.length >
              0 && (
              <div style={pagination}>
                <button
                  type="button"
                  style={{
                    ...pageBtn,
                    opacity:
                      currentPage === 1
                        ? 0.5
                        : 1,
                  }}
                  disabled={
                    currentPage === 1
                  }
                  onClick={() =>
                    setCurrentPage(
                      (page) =>
                        page - 1,
                    )
                  }
                >
                  Previous
                </button>

                <span>
                  Page {currentPage} of{" "}
                  {totalPages}
                </span>

                <button
                  type="button"
                  style={{
                    ...pageBtn,
                    opacity:
                      currentPage ===
                      totalPages
                        ? 0.5
                        : 1,
                  }}
                  disabled={
                    currentPage ===
                    totalPages
                  }
                  onClick={() =>
                    setCurrentPage(
                      (page) =>
                        page + 1,
                    )
                  }
                >
                  Next
                </button>
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
}

function MessageBox({
  type,
  message,
  onClose,
}) {
  const isSuccess =
    type === "success";

  return (
    <div
      style={{
        ...messageBox,
        background:
          isSuccess
            ? "#f0fdf4"
            : "#fef2f2",
        borderColor:
          isSuccess
            ? "#bbf7d0"
            : "#fecaca",
        color:
          isSuccess
            ? "#166534"
            : "#991b1b",
      }}
    >
      <span>{message}</span>

      <button
        type="button"
        style={messageClose}
        onClick={onClose}
      >
        ×
      </button>
    </div>
  );
}

function getStoredUser() {
  try {
    return JSON.parse(
      localStorage.getItem(
        "user",
      ) || "{}",
    );
  } catch {
    return {};
  }
}

function getObjectId(value) {
  if (!value) {
    return "";
  }

  if (
    typeof value === "string"
  ) {
    return value;
  }

  return (
    value._id?.toString() ??
    value.id?.toString() ??
    ""
  );
}

function getArrayResponse(
  value,
  propertyName,
) {
  if (Array.isArray(value)) {
    return value;
  }

  if (
    Array.isArray(
      value?.[propertyName],
    )
  ) {
    return value[propertyName];
  }

  return [];
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

function buildTokenCode(token) {
  return `${token.prefix}${String(
    token.tokenNumber,
  ).padStart(3, "0")}`;
}

function getStatusBadgeStyle(
  status,
) {
  const baseStyle = {
    display: "inline-block",
    padding: "6px 11px",
    borderRadius: "999px",
    fontSize: "12px",
    fontWeight: 700,
  };

  switch (status) {
    case "Waiting":
      return {
        ...baseStyle,
        background: "#fef3c7",
        color: "#92400e",
      };

    case "Called":
      return {
        ...baseStyle,
        background: "#dbeafe",
        color: "#1d4ed8",
      };

    case "Serving":
      return {
        ...baseStyle,
        background: "#e0e7ff",
        color: "#4338ca",
      };

    case "Completed":
      return {
        ...baseStyle,
        background: "#dcfce7",
        color: "#15803d",
      };

    case "Cancelled":
      return {
        ...baseStyle,
        background: "#fee2e2",
        color: "#b91c1c",
      };

    default:
      return {
        ...baseStyle,
        background: "#f3f4f6",
        color: "#4b5563",
      };
  }
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
    "repeat(5, minmax(0, 1fr))",
  gap: "12px",
  marginBottom: "20px",
};

const filterBox = {
  background: "#ffffff",
  padding: "20px",
  borderRadius: "16px",
  display: "grid",
  gridTemplateColumns:
    "2fr 1fr 1fr",
  gap: "12px",
  marginBottom: "20px",
};

const input = {
  width: "100%",
  boxSizing: "border-box",
  padding: "12px",
  border:
    "1px solid #e5e7eb",
  borderRadius: "10px",
  background: "#ffffff",
};

const disabledInput = {
  ...input,
  background: "#f3f4f6",
  color: "#374151",
  cursor: "not-allowed",
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

const nextBtn = {
  background: "#16a34a",
  color: "#ffffff",
  border: "none",
  padding: "12px 18px",
  borderRadius: "10px",
  cursor: "pointer",
  marginBottom: "20px",
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
  minWidth: "980px",
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

const callBtn = {
  marginRight: "8px",
  padding: "7px 12px",
  border: "none",
  borderRadius: "8px",
  background: "#e0f2fe",
  color: "#0369a1",
  cursor: "pointer",
};

const completeBtn = {
  marginRight: "8px",
  padding: "7px 12px",
  border: "none",
  borderRadius: "8px",
  background: "#dcfce7",
  color: "#15803d",
  cursor: "pointer",
};

const cancelBtn = {
  padding: "7px 12px",
  border: "none",
  borderRadius: "8px",
  background: "#fee2e2",
  color: "#b91c1c",
  cursor: "pointer",
};

const pagination = {
  display: "flex",
  justifyContent: "center",
  alignItems: "center",
  gap: "16px",
  marginTop: "20px",
};

const pageBtn = {
  padding: "8px 14px",
  border: "none",
  borderRadius: "8px",
  background: "#2563eb",
  color: "#ffffff",
  cursor: "pointer",
};

const emptyText = {
  textAlign: "center",
  color: "#6b7280",
};

const messageBox = {
  display: "flex",
  justifyContent: "space-between",
  alignItems: "center",
  gap: "12px",
  border: "1px solid",
  borderRadius: "12px",
  padding: "14px 16px",
  marginBottom: "18px",
};

const messageClose = {
  border: "none",
  background: "transparent",
  color: "inherit",
  cursor: "pointer",
  fontSize: "21px",
};

export default TokenList;