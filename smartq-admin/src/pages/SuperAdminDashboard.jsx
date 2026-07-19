import StatCard from "../components/StatCard";

function SuperAdminDashboard() {
  return (
    <div>
      <h1>Dashboard</h1>
      <p style={{ color: "#6b7280" }}>Welcome to SmartQ Admin Panel</p>

      <div style={grid}>
        <StatCard title="Total Hospitals" value="12" />
        <StatCard title="Total Departments" value="48" />
        <StatCard title="Total Users" value="1,245" />
        <StatCard title="Tokens Today" value="326" />
      </div>

      <div style={section}>
        <h2>Recent Activity</h2>

        {[
          "New hospital added: Colombo National Hospital",
          "Dental department updated",
          "New patient token created",
          "Queue status updated",
        ].map((item, index) => (
          <div key={index} style={activityItem}>
            {item}
          </div>
        ))}
      </div>
    </div>
  );
}

const grid = {
  display: "grid",
  gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))",
  gap: "20px",
  marginTop: "24px",
};

const section = {
  background: "#fff",
  padding: "24px",
  borderRadius: "16px",
  marginTop: "28px",
  boxShadow: "0 4px 12px rgba(0,0,0,0.05)",
};

const activityItem = {
  padding: "14px 0",
  borderBottom: "1px solid #e5e7eb",
  color: "#374151",
};

export default SuperAdminDashboard;