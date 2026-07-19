import { useEffect, useRef, useState } from "react";
import {
  Bell,
  Building2,
  UserCircle,
  X,
} from "lucide-react";

import socket from "../services/socket";

function getStoredUser() {
  const possibleKeys = [
    "user",
    "admin",
    "currentUser",
    "authUser",
  ];

  for (const key of possibleKeys) {
    const rawValue = localStorage.getItem(key);

    if (!rawValue) {
      continue;
    }

    try {
      const parsedValue = JSON.parse(rawValue);

      if (parsedValue && typeof parsedValue === "object") {
        return parsedValue;
      }
    } catch {
      // Ignore invalid stored JSON and continue.
    }
  }

  return null;
}

function getHospitalName() {
  const directHospitalName =
    localStorage.getItem("hospitalName")?.trim();

  if (directHospitalName) {
    return directHospitalName;
  }

  const storedUser = getStoredUser();

  const possibleHospitalNames = [
    storedUser?.hospitalName,
    storedUser?.hospital?.name,
    storedUser?.hospitalId?.name,
    storedUser?.user?.hospitalName,
    storedUser?.user?.hospital?.name,
  ];

  const matchedHospitalName =
    possibleHospitalNames.find(
      (value) =>
        typeof value === "string" &&
        value.trim().length > 0,
    );

  return matchedHospitalName?.trim() || "";
}

function getUserRole() {
  const directRole =
    localStorage.getItem("userRole")?.trim();

  if (directRole) {
    return directRole;
  }

  const storedUser = getStoredUser();

  return (
    storedUser?.role ||
    storedUser?.user?.role ||
    "super_admin"
  );
}

function getAdminName() {
  const directName =
    localStorage.getItem("userName")?.trim() ||
    localStorage.getItem("adminName")?.trim();

  if (directName) {
    return directName;
  }

  const storedUser = getStoredUser();

  return (
    storedUser?.name ||
    storedUser?.username ||
    storedUser?.user?.name ||
    storedUser?.user?.username ||
    "Admin"
  );
}

function formatRole(role) {
  return role
    .replaceAll("_", " ")
    .replace(/\b\w/g, (character) =>
      character.toUpperCase(),
    );
}

function Topbar() {
  const dropdownRef = useRef(null);

  const [notifications, setNotifications] =
    useState([]);

  const [open, setOpen] = useState(false);

  const [role, setRole] = useState(
    getUserRole(),
  );

  const [hospitalName, setHospitalName] =
    useState(getHospitalName());

  const [adminName, setAdminName] =
    useState(getAdminName());

  const isSuperAdmin =
    role === "super_admin" ||
    role === "superadmin";

  const topbarTitle =
    !isSuperAdmin && hospitalName
      ? hospitalName
      : "Admin Panel";

  useEffect(() => {
    const handleNotification = (data) => {
      setNotifications((previous) => [
        data,
        ...previous,
      ]);
    };

    socket.on(
      "notification",
      handleNotification,
    );

    return () => {
      socket.off(
        "notification",
        handleNotification,
      );
    };
  }, []);

  useEffect(() => {
    const updateStoredUserDetails = () => {
      setRole(getUserRole());
      setHospitalName(getHospitalName());
      setAdminName(getAdminName());
    };

    window.addEventListener(
      "storage",
      updateStoredUserDetails,
    );

    window.addEventListener(
      "smartq-user-updated",
      updateStoredUserDetails,
    );

    return () => {
      window.removeEventListener(
        "storage",
        updateStoredUserDetails,
      );

      window.removeEventListener(
        "smartq-user-updated",
        updateStoredUserDetails,
      );
    };
  }, []);

  useEffect(() => {
    const handleOutsideClick = (event) => {
      if (
        dropdownRef.current &&
        !dropdownRef.current.contains(
          event.target,
        )
      ) {
        setOpen(false);
      }
    };

    document.addEventListener(
      "mousedown",
      handleOutsideClick,
    );

    return () => {
      document.removeEventListener(
        "mousedown",
        handleOutsideClick,
      );
    };
  }, []);

  const clearNotifications = (event) => {
    event.stopPropagation();

    setNotifications([]);
    setOpen(false);
  };

  const toggleNotifications = () => {
    setOpen((previous) => !previous);
  };

  return (
    <header style={topbar}>
      <div style={titleSection}>
        <div style={hospitalIcon}>
          <Building2
            size={20}
            color="#2563eb"
          />
        </div>

        <div>
          <h3 style={title}>
            {topbarTitle}
          </h3>

          <p style={subtitle}>
            SmartQ Hospital Queue System
          </p>
        </div>
      </div>

      <div style={right}>
        <div
          ref={dropdownRef}
          style={bellBox}
        >
          <button
            type="button"
            style={bellButton}
            onClick={toggleNotifications}
            aria-label="Open notifications"
            aria-expanded={open}
          >
            <Bell
              size={22}
              color="#475569"
            />

            {notifications.length > 0 && (
              <span style={badge}>
                {notifications.length > 99
                  ? "99+"
                  : notifications.length}
              </span>
            )}
          </button>

          {open && (
            <div style={dropdown}>
              <div style={dropHeader}>
                <div>
                  <strong style={dropdownTitle}>
                    Notifications
                  </strong>

                  <p style={notificationCount}>
                    {notifications.length}
                    {notifications.length === 1
                      ? " notification"
                      : " notifications"}
                  </p>
                </div>

                <button
                  type="button"
                  style={clearBtn}
                  onClick={clearNotifications}
                  aria-label="Clear notifications"
                  title="Clear notifications"
                >
                  <X size={17} />
                </button>
              </div>

              <div style={notificationList}>
                {notifications.length === 0 ? (
                  <div style={emptyContainer}>
                    <Bell
                      size={28}
                      color="#94a3b8"
                    />

                    <p style={empty}>
                      No notifications
                    </p>
                  </div>
                ) : (
                  notifications.map(
                    (notification, index) => (
                      <div
                        key={
                          notification.id ||
                          `${notification.time}-${index}`
                        }
                        style={notificationItem}
                      >
                        <strong style={notiType}>
                          {notification.type ||
                            "Notification"}
                        </strong>

                        <p style={notiMsg}>
                          {notification.message ||
                            "You have a new notification."}
                        </p>

                        <small style={notiTime}>
                          {notification.time
                            ? new Date(
                                notification.time,
                              ).toLocaleTimeString(
                                [],
                                {
                                  hour: "2-digit",
                                  minute: "2-digit",
                                },
                              )
                            : "Just now"}
                        </small>
                      </div>
                    ),
                  )
                )}
              </div>
            </div>
          )}
        </div>

        <div style={profile}>
          <UserCircle
            size={30}
            color="#2563eb"
          />

          <div style={profileDetails}>
            <strong style={adminNameStyle}>
              {adminName}
            </strong>

            <p style={roleText}>
              {formatRole(role)}
            </p>
          </div>
        </div>
      </div>
    </header>
  );
}

const topbar = {
  height: "72px",
  background: "#ffffff",
  borderBottom: "1px solid #e5e7eb",
  display: "flex",
  alignItems: "center",
  justifyContent: "space-between",
  padding: "0 24px",
  position: "relative",
  zIndex: 1000,
};

const titleSection = {
  display: "flex",
  alignItems: "center",
  gap: "12px",
  minWidth: 0,
};

const hospitalIcon = {
  width: "40px",
  height: "40px",
  borderRadius: "12px",
  background: "#eff6ff",
  display: "flex",
  alignItems: "center",
  justifyContent: "center",
  flexShrink: 0,
};

const title = {
  margin: 0,
  color: "#0f172a",
  fontSize: "17px",
  fontWeight: 700,
  lineHeight: 1.25,
  maxWidth: "420px",
  whiteSpace: "nowrap",
  overflow: "hidden",
  textOverflow: "ellipsis",
};

const subtitle = {
  margin: "3px 0 0",
  fontSize: "12px",
  color: "#64748b",
};

const right = {
  display: "flex",
  alignItems: "center",
  gap: "20px",
};

const bellBox = {
  position: "relative",
};

const bellButton = {
  width: "40px",
  height: "40px",
  border: "none",
  borderRadius: "10px",
  background: "transparent",
  cursor: "pointer",
  display: "flex",
  alignItems: "center",
  justifyContent: "center",
  position: "relative",
};

const badge = {
  position: "absolute",
  top: "1px",
  right: "1px",
  background: "#dc2626",
  color: "#ffffff",
  fontSize: "10px",
  fontWeight: 700,
  minWidth: "18px",
  height: "18px",
  padding: "0 4px",
  borderRadius: "999px",
  border: "2px solid #ffffff",
  display: "flex",
  alignItems: "center",
  justifyContent: "center",
  boxSizing: "border-box",
};

const dropdown = {
  position: "absolute",
  top: "48px",
  right: 0,
  width: "340px",
  background: "#ffffff",
  border: "1px solid #e5e7eb",
  borderRadius: "14px",
  boxShadow:
    "0 16px 40px rgba(15, 23, 42, 0.16)",
  zIndex: 2000,
  overflow: "hidden",
};

const dropHeader = {
  display: "flex",
  justifyContent: "space-between",
  alignItems: "center",
  padding: "14px 16px",
  borderBottom: "1px solid #e5e7eb",
};

const dropdownTitle = {
  color: "#0f172a",
  fontSize: "15px",
};

const notificationCount = {
  margin: "2px 0 0",
  color: "#64748b",
  fontSize: "12px",
};

const clearBtn = {
  width: "32px",
  height: "32px",
  border: "none",
  borderRadius: "8px",
  background: "#f8fafc",
  color: "#475569",
  cursor: "pointer",
  display: "flex",
  alignItems: "center",
  justifyContent: "center",
};

const notificationList = {
  maxHeight: "360px",
  overflowY: "auto",
};

const notificationItem = {
  padding: "12px 16px",
  borderBottom: "1px solid #f1f5f9",
};

const notiType = {
  color: "#2563eb",
  textTransform: "capitalize",
  fontSize: "13px",
};

const notiMsg = {
  margin: "5px 0",
  color: "#334155",
  fontSize: "14px",
  lineHeight: 1.4,
};

const notiTime = {
  color: "#94a3b8",
  fontSize: "11px",
};

const emptyContainer = {
  minHeight: "150px",
  display: "flex",
  flexDirection: "column",
  alignItems: "center",
  justifyContent: "center",
  gap: "8px",
};

const empty = {
  margin: 0,
  textAlign: "center",
  color: "#64748b",
  fontSize: "14px",
};

const profile = {
  display: "flex",
  alignItems: "center",
  gap: "10px",
};

const profileDetails = {
  lineHeight: 1.2,
};

const adminNameStyle = {
  color: "#0f172a",
  fontSize: "14px",
};

const roleText = {
  margin: "3px 0 0",
  fontSize: "11px",
  color: "#64748b",
};

export default Topbar;