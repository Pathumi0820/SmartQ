import { useState } from "react";
import {
  NavLink,
  useNavigate,
} from "react-router-dom";

import {
  BarChart3,
  Building2,
  CalendarDays,
  ClipboardList,
  Hospital,
  KeyRound,
  LayoutDashboard,
  LogOut,
  Monitor,
  ShieldCheck,
  Ticket,
  Users,
} from "lucide-react";

import { signOut } from "firebase/auth";

import logoImg from "../assets/logo.png";
import { auth } from "../firebase";

function Sidebar({
  setSidebarOpen,
}) {
  const [open, setOpen] =
    useState(false);

  const [isLoggingOut, setIsLoggingOut] =
    useState(false);

  const navigate = useNavigate();

  const role =
    localStorage.getItem(
      "userRole",
    ) || "";

  const isSuperAdmin =
    role === "super_admin";

  const isHospitalAdmin =
    role === "hospital_admin";

  const isDepartmentAdmin =
    role === "department_admin";

  const hasDashboardAccess =
    isSuperAdmin ||
    isHospitalAdmin ||
    isDepartmentAdmin;

  const hasReportAccess =
    isSuperAdmin ||
    isHospitalAdmin ||
    isDepartmentAdmin;

  const hasPasswordAccess =
    isSuperAdmin ||
    isHospitalAdmin ||
    isDepartmentAdmin;

  const logout = async () => {
    if (isLoggingOut) {
      return;
    }

    try {
      setIsLoggingOut(true);

      await signOut(auth);
    } catch (error) {
      console.error(
        "Logout error:",
        error,
      );
    } finally {
      localStorage.removeItem(
        "userRole",
      );

      localStorage.removeItem(
        "token",
      );

      localStorage.removeItem(
        "user",
      );

      navigate(
        "/login",
        {
          replace: true,
        },
      );

      setIsLoggingOut(false);
    }
  };

  const handleMouseEnter = () => {
    setOpen(true);

    if (
      typeof setSidebarOpen ===
      "function"
    ) {
      setSidebarOpen(true);
    }
  };

  const handleMouseLeave = () => {
    setOpen(false);

    if (
      typeof setSidebarOpen ===
      "function"
    ) {
      setSidebarOpen(false);
    }
  };

  const linkStyle = ({
    isActive,
  }) => ({
    display: "flex",
    alignItems: "center",
    gap: "14px",
    minHeight: "48px",
    padding: "0 14px",
    borderRadius: "14px",
    textDecoration: "none",
    color: isActive
      ? "#2563eb"
      : "#cbd5e1",
    background: isActive
      ? "#ffffff"
      : "transparent",
    fontWeight: isActive
      ? "800"
      : "600",
    whiteSpace: "nowrap",
    transition:
      "all 0.2s ease",
  });

  const ItemText = ({
    children,
  }) =>
    open ? (
      <span style={itemText}>
        {children}
      </span>
    ) : null;

  return (
    <aside
      style={{
        ...sidebar,
        width: open
          ? "250px"
          : "78px",
      }}
      onMouseEnter={
        handleMouseEnter
      }
      onMouseLeave={
        handleMouseLeave
      }
    >
      <div style={logoBox}>
        <img
          src={logoImg}
          alt="SmartQ Logo"
          style={logoImage}
        />

        {open && (
          <div style={logoTextContainer}>
            <h2 style={logoTitle}>
              SmartQ
            </h2>

            <p style={logoSub}>
              Queue System
            </p>
          </div>
        )}
      </div>

      <nav style={nav}>
        {/* Dashboard: all admin roles */}
        {hasDashboardAccess && (
          <NavLink
            to="/"
            end
            style={linkStyle}
          >
            <LayoutDashboard
              size={19}
            />

            <ItemText>
              Dashboard
            </ItemText>
          </NavLink>
        )}

        {/* Super Admin menu */}
        {isSuperAdmin && (
          <>
            <NavLink
              to="/hospitals"
              style={linkStyle}
            >
              <Hospital size={19} />

              <ItemText>
                Hospitals
              </ItemText>
            </NavLink>

            <NavLink
              to="/departments"
              style={linkStyle}
            >
              <Building2 size={19} />

              <ItemText>
                Departments
              </ItemText>
            </NavLink>

            <NavLink
              to="/users"
              style={linkStyle}
            >
              <Users size={19} />

              <ItemText>
                Users
              </ItemText>
            </NavLink>
          </>
        )}

        {/* Hospital Admin menu */}
        {isHospitalAdmin && (
          <>
            <NavLink
              to="/departments"
              style={linkStyle}
            >
              <Building2 size={19} />

              <ItemText>
                Departments
              </ItemText>
            </NavLink>

            <NavLink
              to="/users"
              style={linkStyle}
            >
              <Users size={19} />

              <ItemText>
                Users
              </ItemText>
            </NavLink>

            <NavLink
              to="/appointments"
              style={linkStyle}
            >
              <CalendarDays
                size={19}
              />

              <ItemText>
                Appointments
              </ItemText>
            </NavLink>
          </>
        )}

        {/* Department Admin menu */}
        {isDepartmentAdmin && (
          <>
            <NavLink
              to="/display"
              style={linkStyle}
            >
              <Monitor size={19} />

              <ItemText>
                Display Board
              </ItemText>
            </NavLink>

            <NavLink
              to="/queue-sessions"
              style={linkStyle}
            >
              <ClipboardList
                size={19}
              />

              <ItemText>
                Queue Management
              </ItemText>
            </NavLink>

            <NavLink
              to="/tokens"
              style={linkStyle}
            >
              <Ticket size={19} />

              <ItemText>
                Tokens
              </ItemText>
            </NavLink>

            <NavLink
              to="/verify"
              style={linkStyle}
            >
              <ShieldCheck
                size={19}
              />

              <ItemText>
                Verify Patient
              </ItemText>
            </NavLink>
          </>
        )}

        {/* Reports: all admin roles */}
        {hasReportAccess && (
          <NavLink
            to="/reports"
            style={linkStyle}
          >
            <BarChart3 size={19} />

            <ItemText>
              Reports
            </ItemText>
          </NavLink>
        )}

        {/* Change Password: all admin roles */}
        {hasPasswordAccess && (
          <NavLink
            to="/change-password"
            style={linkStyle}
          >
            <KeyRound size={19} />

            <ItemText>
              Change Password
            </ItemText>
          </NavLink>
        )}
      </nav>

      <button
        type="button"
        style={{
          ...logoutStyle,
          opacity: isLoggingOut
            ? 0.65
            : 1,
          cursor: isLoggingOut
            ? "not-allowed"
            : "pointer",
        }}
        onClick={logout}
        disabled={isLoggingOut}
        title={
          open
            ? undefined
            : "Logout"
        }
      >
        <LogOut size={19} />

        {open && (
          <span>
            {isLoggingOut
              ? "Logging out..."
              : "Logout"}
          </span>
        )}
      </button>
    </aside>
  );
}

const sidebar = {
  height: "100vh",
  background:
    "linear-gradient(180deg, #0f172a 0%, #111827 100%)",
  padding: "20px 14px",
  boxSizing: "border-box",
  display: "flex",
  flexDirection: "column",
  position: "fixed",
  top: 0,
  left: 0,
  zIndex: 1000,
  overflow: "hidden",
  transition:
    "width 0.3s ease",
  boxShadow:
    "6px 0 24px rgba(15, 23, 42, 0.25)",
};

const logoBox = {
  display: "flex",
  alignItems: "center",
  gap: "12px",
  minHeight: "44px",
  marginBottom: "28px",
};

const logoImage = {
  width: "44px",
  height: "44px",
  borderRadius: "12px",
  objectFit: "cover",
  background: "#ffffff",
  flexShrink: 0,
};

const logoTextContainer = {
  minWidth: 0,
};

const logoTitle = {
  margin: 0,
  color: "#ffffff",
  fontSize: "22px",
  fontWeight: "800",
  lineHeight: "22px",
};

const logoSub = {
  margin: "3px 0 0",
  color: "#94a3b8",
  fontSize: "12px",
};

const nav = {
  display: "flex",
  flexDirection: "column",
  gap: "8px",
  flex: 1,
  overflowY: "auto",
  overflowX: "hidden",
  paddingRight: "2px",
};

const itemText = {
  overflow: "hidden",
  textOverflow: "ellipsis",
};

const logoutStyle = {
  display: "flex",
  alignItems: "center",
  gap: "14px",
  minHeight: "48px",
  padding: "0 14px",
  borderRadius: "14px",
  color: "#fb7185",
  border: "none",
  background: "transparent",
  fontWeight: "800",
  fontSize: "14px",
  whiteSpace: "nowrap",
  flexShrink: 0,
};

export default Sidebar;