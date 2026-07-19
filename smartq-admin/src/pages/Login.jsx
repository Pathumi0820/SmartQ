import { useState } from "react";
import { useNavigate } from "react-router-dom";
import axios from "axios";

function Login() {
  const navigate = useNavigate();

  const [email, setEmail] = useState("admin@smartq.com");
  const [password, setPassword] = useState("Admin123456");
  const [loading, setLoading] = useState(false);

  const handleLogin = async (e) => {
    e.preventDefault();

    try {
      setLoading(true);

      const res = await axios.post(
        "http://localhost:5000/api/auth/login",
        {
          email: email.trim(),
          password,
        }
      );

      const { token, user } = res.data;

      // Clear previous session
      localStorage.clear();

      // Save authentication
      localStorage.setItem("token", token);

      // Save full user
      localStorage.setItem(
        "user",
        JSON.stringify(user)
      );

      // Save user details
      localStorage.setItem(
        "userRole",
        user.role || ""
      );

      localStorage.setItem(
        "userName",
        user.fullName ||
          user.username ||
          "Admin"
      );

      // Save hospital information
      localStorage.setItem(
        "hospitalId",
        user.hospitalId || ""
      );

      localStorage.setItem(
        "hospitalName",
        user.hospitalName ||
          user.hospital?.name ||
          ""
      );

      // Notify Topbar to refresh
      window.dispatchEvent(
        new Event("smartq-user-updated")
      );

      navigate("/", {
        replace: true,
      });
    } catch (error) {
      alert(
        error.response?.data?.message ||
          "Login failed"
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={page}>
      <form
        style={card}
        onSubmit={handleLogin}
      >
        <h1 style={title}>
          SmartQ Admin
        </h1>

        <p style={subtitle}>
          Login to continue
        </p>

        <input
          style={input}
          type="email"
          placeholder="Email"
          value={email}
          autoComplete="email"
          onChange={(e) =>
            setEmail(e.target.value)
          }
        />

        <input
          style={input}
          type="password"
          placeholder="Password"
          value={password}
          autoComplete="current-password"
          onChange={(e) =>
            setPassword(e.target.value)
          }
        />

        <button
          style={{
            ...button,
            opacity: loading ? 0.8 : 1,
          }}
          disabled={loading}
        >
          {loading
            ? "Logging in..."
            : "Login"}
        </button>
      </form>
    </div>
  );
}

const page = {
  minHeight: "100vh",
  background: "#f8fafc",
  display: "flex",
  alignItems: "center",
  justifyContent: "center",
};

const card = {
  width: "380px",
  background: "#ffffff",
  padding: "32px",
  borderRadius: "18px",
  boxShadow:
    "0 10px 30px rgba(15,23,42,0.08)",
};

const title = {
  margin: 0,
  color: "#2563eb",
  fontWeight: 700,
};

const subtitle = {
  color: "#64748b",
  marginBottom: "24px",
};

const input = {
  width: "100%",
  padding: "12px",
  marginBottom: "14px",
  border: "1px solid #e5e7eb",
  borderRadius: "10px",
  fontSize: "15px",
  boxSizing: "border-box",
};

const button = {
  width: "100%",
  padding: "12px",
  background: "#2563eb",
  color: "#ffffff",
  border: "none",
  borderRadius: "10px",
  cursor: "pointer",
  fontWeight: "600",
  fontSize: "15px",
};

export default Login;