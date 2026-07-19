import { useState } from "react";

function ChangePassword() {
  const [currentPassword, setCurrentPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");

  const handleChangePassword = () => {
    if (!currentPassword || !newPassword || !confirmPassword) {
      alert("Please fill all fields");
      return;
    }

    if (newPassword !== confirmPassword) {
      alert("Passwords do not match");
      return;
    }

    if (newPassword.length < 6) {
      alert("Password must be at least 6 characters");
      return;
    }

    alert("Password changed successfully!");

    setCurrentPassword("");
    setNewPassword("");
    setConfirmPassword("");
  };

  return (
    <div>
      <h1>Change Password</h1>
      <p style={subtitle}>Update your account password</p>

      <div style={card}>
        <input
          type="password"
          placeholder="Current Password"
          style={input}
          value={currentPassword}
          onChange={(e) => setCurrentPassword(e.target.value)}
        />

        <input
          type="password"
          placeholder="New Password"
          style={input}
          value={newPassword}
          onChange={(e) => setNewPassword(e.target.value)}
        />

        <input
          type="password"
          placeholder="Confirm New Password"
          style={input}
          value={confirmPassword}
          onChange={(e) => setConfirmPassword(e.target.value)}
        />

        <button style={button} onClick={handleChangePassword}>
          Change Password
        </button>
      </div>
    </div>
  );
}

const subtitle = {
  color: "#6b7280",
  marginBottom: "20px",
};

const card = {
  background: "#fff",
  padding: "24px",
  borderRadius: "16px",
  maxWidth: "500px",
};

const input = {
  width: "100%",
  padding: "12px",
  marginBottom: "14px",
  border: "1px solid #e5e7eb",
  borderRadius: "10px",
  boxSizing: "border-box",
};

const button = {
  background: "#2563eb",
  color: "#fff",
  border: "none",
  padding: "12px 20px",
  borderRadius: "10px",
  cursor: "pointer",
};

export default ChangePassword;