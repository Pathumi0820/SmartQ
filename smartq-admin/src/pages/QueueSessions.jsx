import {
  useCallback,
  useEffect,
  useMemo,
  useState,
} from "react";

import api from "../services/api";

const queueStatuses = [
  "All",
  "Scheduled",
  "Active",
  "Closed",
  "Cancelled",
];

function getStoredUser() {
  try {
    const storedUser =
      localStorage.getItem("user");

    return storedUser
      ? JSON.parse(storedUser)
      : {};
  } catch (error) {
    console.error(
      "Failed to read stored user:",
      error,
    );

    return {};
  }
}

function getAssignedDepartment() {
  const user = getStoredUser();

  const departmentId =
    user.departmentId ||
    user.department?.id ||
    user.department?._id ||
    localStorage.getItem("departmentId") ||
    "";

  const departmentName =
    user.departmentName ||
    user.department?.name ||
    localStorage.getItem("departmentName") ||
    "";

  const hospitalName =
    user.hospitalName ||
    user.hospital?.name ||
    localStorage.getItem("hospitalName") ||
    "";

  return {
    id: String(departmentId).trim(),
    name:
      String(departmentName).trim() ||
      "Assigned Department",
    hospitalName:
      String(hospitalName).trim(),
  };
}

function getSessionDepartmentId(session) {
  return String(
    session?.department?._id ||
      session?.department?.id ||
      session?.departmentId ||
      session?.department ||
      "",
  ).trim();
}

function QueueSessions() {
  const assignedDepartment =
    useMemo(
      () => getAssignedDepartment(),
      [],
    );

  const [sessions, setSessions] =
    useState([]);

  const [selectedStatus, setSelectedStatus] =
    useState("All");

  const [formData, setFormData] =
    useState({
      startAt: "",
      endAt: "",
      maximumTokens: "",
      notes: "",
    });

  const [loading, setLoading] =
    useState(true);

  const [submitting, setSubmitting] =
    useState(false);

  const [actionId, setActionId] =
    useState("");

  const [errorMessage, setErrorMessage] =
    useState("");

  const [successMessage, setSuccessMessage] =
    useState("");

  const loadQueueSessions =
    useCallback(async () => {
      try {
        setLoading(true);
        setErrorMessage("");

        const response = await api.get(
          "/queue-sessions",
        );

        const responseData =
          response.data;

        const sessionList =
          Array.isArray(responseData)
            ? responseData
            : Array.isArray(
                responseData?.sessions,
              )
            ? responseData.sessions
            : [];

        /*
         * The backend should already restrict department
         * admins to their assigned department.
         *
         * This frontend filter adds another display-level
         * safety check.
         */
        const departmentSessions =
          assignedDepartment.id
            ? sessionList.filter(
                (session) => {
                  const sessionDepartmentId =
                    getSessionDepartmentId(
                      session,
                    );

                  return (
                    !sessionDepartmentId ||
                    sessionDepartmentId ===
                      assignedDepartment.id
                  );
                },
              )
            : sessionList;

        setSessions(
          departmentSessions,
        );
      } catch (error) {
        console.error(
          "Queue session loading error:",
          error,
        );

        setErrorMessage(
          getErrorMessage(
            error,
            "Failed to load queue sessions.",
          ),
        );
      } finally {
        setLoading(false);
      }
    }, [assignedDepartment.id]);

  useEffect(() => {
    loadQueueSessions();
  }, [loadQueueSessions]);

  const filteredSessions =
    useMemo(() => {
      if (
        selectedStatus === "All"
      ) {
        return sessions;
      }

      return sessions.filter(
        (session) =>
          session.status ===
          selectedStatus,
      );
    }, [
      selectedStatus,
      sessions,
    ]);

  const handleInputChange = (
    event,
  ) => {
    const {
      name,
      value,
    } = event.target;

    setFormData(
      (previous) => ({
        ...previous,
        [name]: value,
      }),
    );

    setErrorMessage("");
    setSuccessMessage("");
  };

  const handleCreateQueue =
    async (event) => {
      event.preventDefault();

      const departmentId =
        assignedDepartment.id;

      const startAt =
        formData.startAt.trim();

      const endAt =
        formData.endAt.trim();

      if (!departmentId) {
        setErrorMessage(
          "No department is assigned to this account. Please contact the super administrator.",
        );

        return;
      }

      if (
        !startAt ||
        !endAt
      ) {
        setErrorMessage(
          "Start time and end time are required.",
        );

        return;
      }

      const startDate =
        new Date(startAt);

      const endDate =
        new Date(endAt);

      if (
        Number.isNaN(
          startDate.getTime(),
        ) ||
        Number.isNaN(
          endDate.getTime(),
        )
      ) {
        setErrorMessage(
          "Please enter valid queue times.",
        );

        return;
      }

      if (
        endDate <= startDate
      ) {
        setErrorMessage(
          "End time must be later than start time.",
        );

        return;
      }

      let maximumTokens =
        null;

      if (
        formData.maximumTokens
          .trim() !== ""
      ) {
        maximumTokens = Number(
          formData.maximumTokens,
        );

        if (
          !Number.isInteger(
            maximumTokens,
          ) ||
          maximumTokens < 1
        ) {
          setErrorMessage(
            "Maximum tokens must be a positive whole number.",
          );

          return;
        }
      }

      try {
        setSubmitting(true);
        setErrorMessage("");
        setSuccessMessage("");

        await api.post(
          "/queue-sessions",
          {
            departmentId,
            startAt:
              startDate.toISOString(),
            endAt:
              endDate.toISOString(),
            maximumTokens,
            notes:
              formData.notes.trim(),
          },
        );

        setSuccessMessage(
          `Queue session created successfully for ${assignedDepartment.name}.`,
        );

        setFormData({
          startAt: "",
          endAt: "",
          maximumTokens: "",
          notes: "",
        });

        await loadQueueSessions();
      } catch (error) {
        console.error(
          "Queue session creation error:",
          error,
        );

        setErrorMessage(
          getErrorMessage(
            error,
            "Failed to create queue session.",
          ),
        );
      } finally {
        setSubmitting(false);
      }
    };

  const performQueueAction =
    async (
      session,
      action,
    ) => {
      const labels = {
        start: "start",
        close: "close",
        cancel: "cancel",
      };

      const actionLabel =
        labels[action];

      if (!actionLabel) {
        return;
      }

      const confirmed =
        window.confirm(
          `Are you sure you want to ${actionLabel} this queue session?`,
        );

      if (!confirmed) {
        return;
      }

      try {
        setActionId(
          `${session._id}:${action}`,
        );

        setErrorMessage("");
        setSuccessMessage("");

        await api.put(
          `/queue-sessions/${session._id}/${action}`,
        );

        setSuccessMessage(
          `Queue session ${getPastTense(
            action,
          )} successfully.`,
        );

        await loadQueueSessions();
      } catch (error) {
        console.error(
          `Queue ${action} error:`,
          error,
        );

        setErrorMessage(
          getErrorMessage(
            error,
            `Failed to ${action} queue session.`,
          ),
        );
      } finally {
        setActionId("");
      }
    };

  const hasAssignedDepartment =
    Boolean(
      assignedDepartment.id,
    );

  return (
    <div style={styles.page}>
      <div style={styles.header}>
        <div>
          <h1 style={styles.title}>
            Queue Management
          </h1>

          <p style={styles.subtitle}>
            Create and manage queue
            sessions.
          </p>
        </div>

        <button
          type="button"
          style={styles.refreshButton}
          onClick={loadQueueSessions}
          disabled={loading}
        >
          {loading
            ? "Refreshing..."
            : "Refresh"}
        </button>
      </div>

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

      <div style={styles.layout}>
        <section style={styles.formCard}>
          <div style={styles.cardHeader}>
            <h2 style={styles.cardTitle}>
              Create Queue Session
            </h2>

            <p style={styles.cardSubtitle}>
              Set the period in which
              patients can request tokens.
            </p>
          </div>

          <form
            onSubmit={handleCreateQueue}
            style={styles.form}
          >
            <div
              style={{
                ...styles.assignedDepartmentBox,
                ...(!hasAssignedDepartment
                  ? styles.missingDepartmentBox
                  : {}),
              }}
            >
              <span
                style={
                  styles.assignedDepartmentLabel
                }
              ></span>

              <strong
                style={{
                  ...styles.assignedDepartmentName,
                  ...(!hasAssignedDepartment
                    ? styles.missingDepartmentName
                    : {}),
                }}
              >
                {hasAssignedDepartment
                  ? assignedDepartment.name
                  : "No department assigned"}
              </strong>

              {assignedDepartment
                .hospitalName && (
                <span
                  style={
                    styles.assignedHospitalName
                  }
                >
                  {
                    assignedDepartment
                      .hospitalName
                  }
                </span>
              )}
            </div>

            <div style={styles.twoColumn}>
              <Field
                label="Start date and time"
                required
              >
                <input
                  type="datetime-local"
                  name="startAt"
                  value={
                    formData.startAt
                  }
                  onChange={
                    handleInputChange
                  }
                  disabled={submitting}
                  style={styles.input}
                />
              </Field>

              <Field
                label="End date and time"
                required
              >
                <input
                  type="datetime-local"
                  name="endAt"
                  value={
                    formData.endAt
                  }
                  onChange={
                    handleInputChange
                  }
                  disabled={submitting}
                  style={styles.input}
                />
              </Field>
            </div>

            <Field label="Maximum tokens">
              <input
                type="number"
                min="1"
                step="1"
                name="maximumTokens"
                placeholder="Leave empty for no limit"
                value={
                  formData.maximumTokens
                }
                onChange={
                  handleInputChange
                }
                disabled={submitting}
                style={styles.input}
              />
            </Field>

            <Field label="Notes">
              <textarea
                name="notes"
                rows="4"
                maxLength="500"
                placeholder="Optional notes about this queue session"
                value={
                  formData.notes
                }
                onChange={
                  handleInputChange
                }
                disabled={submitting}
                style={{
                  ...styles.input,
                  resize: "vertical",
                }}
              />
            </Field>

            <button
              type="submit"
              disabled={
                submitting ||
                !hasAssignedDepartment
              }
              style={{
                ...styles.primaryButton,
                opacity:
                  submitting ||
                  !hasAssignedDepartment
                    ? 0.6
                    : 1,
                cursor:
                  submitting ||
                  !hasAssignedDepartment
                    ? "not-allowed"
                    : "pointer",
              }}
            >
              {submitting
                ? "Creating..."
                : "Create Queue"}
            </button>
          </form>
        </section>

        <section style={styles.listSection}>
          <div style={styles.listHeader}>
            <div>
              <h2 style={styles.cardTitle}>
                Queue Sessions
              </h2>

              <p style={styles.cardSubtitle}>
                View and control scheduled
                and active queues for{" "}
                {assignedDepartment.name}.
              </p>
            </div>

            <select
              value={selectedStatus}
              onChange={(event) =>
                setSelectedStatus(
                  event.target.value,
                )
              }
              style={styles.statusFilter}
            >
              {queueStatuses.map(
                (status) => (
                  <option
                    key={status}
                    value={status}
                  >
                    {status}
                  </option>
                ),
              )}
            </select>
          </div>

          {loading ? (
            <div style={styles.emptyBox}>
              Loading queue sessions...
            </div>
          ) : filteredSessions.length ===
            0 ? (
            <div style={styles.emptyBox}>
              No queue sessions found.
            </div>
          ) : (
            <div style={styles.sessionList}>
              {filteredSessions.map(
                (session) => (
                  <QueueSessionCard
                    key={session._id}
                    session={session}
                    actionId={actionId}
                    onAction={
                      performQueueAction
                    }
                  />
                ),
              )}
            </div>
          )}
        </section>
      </div>
    </div>
  );
}

function QueueSessionCard({
  session,
  actionId,
  onAction,
}) {
  const statusStyle =
    getStatusStyle(
      session.status,
    );

  const departmentName =
    session.department?.name ??
    "Unknown department";

  const hospitalName =
    session.hospital?.name ??
    session.department?.hospital?.name ??
    "";

  const remainingTokens =
    session.maximumTokens == null
      ? null
      : Math.max(
          session.maximumTokens -
            (session.issuedTokenCount ??
              0),
          0,
        );

  const startLoading =
    actionId ===
    `${session._id}:start`;

  const closeLoading =
    actionId ===
    `${session._id}:close`;

  const cancelLoading =
    actionId ===
    `${session._id}:cancel`;

  const hasRunningAction =
    actionId.startsWith(
      `${session._id}:`,
    );

  return (
    <article style={styles.sessionCard}>
      <div style={styles.sessionTop}>
        <div>
          <h3 style={styles.sessionTitle}>
            {departmentName}
          </h3>

          {hospitalName && (
            <p style={styles.sessionHospital}>
              {hospitalName}
            </p>
          )}
        </div>

        <span
          style={{
            ...styles.statusBadge,
            ...statusStyle,
          }}
        >
          {session.status}
        </span>
      </div>

      <div style={styles.detailsGrid}>
        <DetailItem
          label="Start"
          value={formatDateTime(
            session.startAt,
          )}
        />

        <DetailItem
          label="End"
          value={formatDateTime(
            session.endAt,
          )}
        />

        <DetailItem
          label="Maximum Tokens"
          value={
            session.maximumTokens ??
            "No limit"
          }
        />

        <DetailItem
          label="Issued Tokens"
          value={
            session.issuedTokenCount ??
            0
          }
        />

        <DetailItem
          label="Remaining Tokens"
          value={
            remainingTokens ??
            "No limit"
          }
        />

        <DetailItem
          label="Created By"
          value={
            session.createdBy
              ?.fullName ??
            "-"
          }
        />
      </div>

      {session.notes && (
        <div style={styles.notesBox}>
          <strong>Notes:</strong>{" "}
          {session.notes}
        </div>
      )}

      <div style={styles.actionRow}>
        {session.status ===
          "Scheduled" && (
          <button
            type="button"
            disabled={hasRunningAction}
            onClick={() =>
              onAction(
                session,
                "start",
              )
            }
            style={styles.startButton}
          >
            {startLoading
              ? "Starting..."
              : "Start Queue"}
          </button>
        )}

        {session.status ===
          "Active" && (
          <button
            type="button"
            disabled={hasRunningAction}
            onClick={() =>
              onAction(
                session,
                "close",
              )
            }
            style={styles.closeQueueButton}
          >
            {closeLoading
              ? "Closing..."
              : "Close Queue"}
          </button>
        )}

        {[
          "Scheduled",
          "Active",
        ].includes(
          session.status,
        ) && (
          <button
            type="button"
            disabled={hasRunningAction}
            onClick={() =>
              onAction(
                session,
                "cancel",
              )
            }
            style={styles.cancelButton}
          >
            {cancelLoading
              ? "Cancelling..."
              : "Cancel"}
          </button>
        )}

        {[
          "Closed",
          "Cancelled",
        ].includes(
          session.status,
        ) && (
          <span style={styles.finishedText}>
            No actions available
          </span>
        )}
      </div>
    </article>
  );
}

function Field({
  label,
  required = false,
  children,
}) {
  return (
    <label style={styles.field}>
      <span style={styles.label}>
        {label}

        {required && (
          <span style={styles.required}>
            {" "}
            *
          </span>
        )}
      </span>

      {children}
    </label>
  );
}

function DetailItem({
  label,
  value,
}) {
  return (
    <div style={styles.detailItem}>
      <span style={styles.detailLabel}>
        {label}
      </span>

      <strong style={styles.detailValue}>
        {String(value ?? "-")}
      </strong>
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
        ...styles.messageBox,
        background:
          isSuccess
            ? "#f0fdf4"
            : "#fef2f2",
        color:
          isSuccess
            ? "#166534"
            : "#991b1b",
        borderColor:
          isSuccess
            ? "#bbf7d0"
            : "#fecaca",
      }}
    >
      <span>{message}</span>

      <button
        type="button"
        onClick={onClose}
        style={styles.messageClose}
      >
        ×
      </button>
    </div>
  );
}

function formatDateTime(value) {
  if (!value) {
    return "-";
  }

  const date =
    new Date(value);

  if (
    Number.isNaN(
      date.getTime(),
    )
  ) {
    return "-";
  }

  return new Intl.DateTimeFormat(
    undefined,
    {
      year: "numeric",
      month: "short",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
    },
  ).format(date);
}

function getStatusStyle(status) {
  switch (status) {
    case "Active":
      return {
        background: "#dcfce7",
        color: "#166534",
      };

    case "Scheduled":
      return {
        background: "#dbeafe",
        color: "#1d4ed8",
      };

    case "Closed":
      return {
        background: "#e5e7eb",
        color: "#374151",
      };

    case "Cancelled":
      return {
        background: "#fee2e2",
        color: "#991b1b",
      };

    default:
      return {
        background: "#f3f4f6",
        color: "#4b5563",
      };
  }
}

function getPastTense(action) {
  switch (action) {
    case "start":
      return "started";

    case "close":
      return "closed";

    case "cancel":
      return "cancelled";

    default:
      return "updated";
  }
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

const styles = {
  page: {
    width: "100%",
    paddingBottom: "40px",
  },

  header: {
    display: "flex",
    alignItems: "flex-start",
    justifyContent: "space-between",
    gap: "20px",
    flexWrap: "wrap",
    marginBottom: "24px",
  },

  title: {
    margin: 0,
    color: "#111827",
    fontSize: "30px",
  },

  subtitle: {
    margin: "7px 0 0",
    color: "#6b7280",
  },

  refreshButton: {
    border: "1px solid #dbe2ea",
    background: "#ffffff",
    color: "#2563eb",
    borderRadius: "10px",
    padding: "11px 16px",
    cursor: "pointer",
    fontWeight: 600,
  },

  messageBox: {
    border: "1px solid",
    borderRadius: "12px",
    padding: "14px 16px",
    display: "flex",
    justifyContent: "space-between",
    alignItems: "center",
    gap: "12px",
    marginBottom: "20px",
  },

  messageClose: {
    border: "none",
    background: "transparent",
    color: "inherit",
    fontSize: "22px",
    cursor: "pointer",
  },

  layout: {
    display: "grid",
    gridTemplateColumns:
      "minmax(300px, 420px) minmax(0, 1fr)",
    gap: "24px",
    alignItems: "start",
  },

  formCard: {
    background: "#ffffff",
    borderRadius: "18px",
    padding: "22px",
    border: "1px solid #e5e7eb",
    boxShadow:
      "0 6px 20px rgba(15, 23, 42, 0.04)",
  },

  cardHeader: {
    marginBottom: "20px",
  },

  cardTitle: {
    margin: 0,
    fontSize: "20px",
    color: "#111827",
  },

  cardSubtitle: {
    margin: "6px 0 0",
    color: "#6b7280",
    fontSize: "14px",
  },

  form: {
    display: "flex",
    flexDirection: "column",
    gap: "16px",
  },

  assignedDepartmentBox: {
    padding: "13px 14px",
    border: "1px solid #bfdbfe",
    borderRadius: "11px",
    background: "#eff6ff",
    display: "flex",
    flexDirection: "column",
    gap: "4px",
  },

  missingDepartmentBox: {
    borderColor: "#fecaca",
    background: "#fef2f2",
  },

  assignedDepartmentLabel: {
    color: "#64748b",
    fontSize: "12px",
    fontWeight: 600,
  },

  assignedDepartmentName: {
    color: "#1d4ed8",
    fontSize: "16px",
  },

  missingDepartmentName: {
    color: "#b91c1c",
  },

  assignedHospitalName: {
    color: "#64748b",
    fontSize: "12px",
  },

  twoColumn: {
    display: "grid",
    gridTemplateColumns:
      "repeat(auto-fit, minmax(170px, 1fr))",
    gap: "14px",
  },

  field: {
    display: "flex",
    flexDirection: "column",
    gap: "7px",
  },

  label: {
    color: "#374151",
    fontSize: "14px",
    fontWeight: 600,
  },

  required: {
    color: "#dc2626",
  },

  input: {
    width: "100%",
    boxSizing: "border-box",
    border: "1px solid #dbe2ea",
    borderRadius: "10px",
    padding: "12px 13px",
    background: "#ffffff",
    color: "#111827",
    fontSize: "14px",
    outline: "none",
  },

  primaryButton: {
    border: "none",
    borderRadius: "10px",
    padding: "13px 18px",
    background: "#2563eb",
    color: "#ffffff",
    fontWeight: 700,
  },

  listSection: {
    minWidth: 0,
  },

  listHeader: {
    display: "flex",
    alignItems: "flex-start",
    justifyContent: "space-between",
    gap: "16px",
    flexWrap: "wrap",
    marginBottom: "16px",
  },

  statusFilter: {
    border: "1px solid #dbe2ea",
    borderRadius: "10px",
    padding: "10px 12px",
    background: "#ffffff",
    color: "#111827",
  },

  sessionList: {
    display: "flex",
    flexDirection: "column",
    gap: "16px",
  },

  sessionCard: {
    background: "#ffffff",
    border: "1px solid #e5e7eb",
    borderRadius: "18px",
    padding: "20px",
    boxShadow:
      "0 6px 20px rgba(15, 23, 42, 0.04)",
  },

  sessionTop: {
    display: "flex",
    alignItems: "flex-start",
    justifyContent: "space-between",
    gap: "14px",
  },

  sessionTitle: {
    margin: 0,
    color: "#111827",
    fontSize: "18px",
  },

  sessionHospital: {
    margin: "5px 0 0",
    color: "#6b7280",
    fontSize: "13px",
  },

  statusBadge: {
    borderRadius: "999px",
    padding: "6px 11px",
    fontSize: "12px",
    fontWeight: 700,
  },

  detailsGrid: {
    display: "grid",
    gridTemplateColumns:
      "repeat(auto-fit, minmax(150px, 1fr))",
    gap: "12px",
    marginTop: "18px",
  },

  detailItem: {
    background: "#f8fafc",
    borderRadius: "11px",
    padding: "12px",
  },

  detailLabel: {
    display: "block",
    color: "#6b7280",
    fontSize: "12px",
    marginBottom: "5px",
  },

  detailValue: {
    color: "#111827",
    fontSize: "14px",
    overflowWrap: "anywhere",
  },

  notesBox: {
    marginTop: "14px",
    padding: "12px",
    borderRadius: "10px",
    background: "#fffbeb",
    color: "#92400e",
    fontSize: "13px",
    lineHeight: 1.5,
  },

  actionRow: {
    display: "flex",
    alignItems: "center",
    gap: "10px",
    flexWrap: "wrap",
    marginTop: "18px",
  },

  startButton: {
    border: "none",
    borderRadius: "9px",
    padding: "10px 15px",
    background: "#16a34a",
    color: "#ffffff",
    cursor: "pointer",
    fontWeight: 700,
  },

  closeQueueButton: {
    border: "none",
    borderRadius: "9px",
    padding: "10px 15px",
    background: "#2563eb",
    color: "#ffffff",
    cursor: "pointer",
    fontWeight: 700,
  },

  cancelButton: {
    border: "1px solid #fecaca",
    borderRadius: "9px",
    padding: "9px 15px",
    background: "#ffffff",
    color: "#dc2626",
    cursor: "pointer",
    fontWeight: 700,
  },

  finishedText: {
    color: "#6b7280",
    fontSize: "13px",
  },

  emptyBox: {
    background: "#ffffff",
    border: "1px dashed #cbd5e1",
    borderRadius: "16px",
    padding: "36px 20px",
    textAlign: "center",
    color: "#6b7280",
  },
};

export default QueueSessions;