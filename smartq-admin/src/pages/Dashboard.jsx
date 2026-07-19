import { useEffect, useState } from "react";
import {
  Hospital,
  Building2,
  Ticket,
  Clock,
  CheckCircle,
  Users,
} from "lucide-react";
import {
  PieChart,
  Pie,
  Cell,
  Tooltip,
  ResponsiveContainer,
  BarChart,
  Bar,
  XAxis,
  YAxis,
} from "recharts";
import api from "../services/api";
import socket from "../services/socket";

function Dashboard() {
  const [statsData, setStatsData] = useState({});
  const [tokens, setTokens] = useState([]);

  useEffect(() => {
    loadDashboard();

    socket.on("tokensUpdated", loadDashboard);
    socket.on("dashboardUpdated", loadDashboard);

    return () => {
      socket.off("tokensUpdated", loadDashboard);
      socket.off("dashboardUpdated", loadDashboard);
    };
  }, []);

  const loadDashboard = async () => {
    const statsRes = await api.get("/dashboard/stats");
    setStatsData(statsRes.data);

    const tokenRes = await api.get("/tokens");
    setTokens(tokenRes.data.slice(0, 5));
  };

  const chartData = statsData.tokenStatusChart || [];

  const stats = [
    { title: "Hospitals", value: statsData.totalHospitals || 0, icon: Hospital, color: "#2563eb" },
    { title: "Departments", value: statsData.totalDepartments || 0, icon: Building2, color: "#7c3aed" },
    { title: "Today Tokens", value: statsData.todayTokens || 0, icon: Ticket, color: "#0891b2" },
    { title: "Waiting", value: statsData.waitingTokens || 0, icon: Clock, color: "#f59e0b" },
    { title: "Completed", value: statsData.completedTokens || 0, icon: CheckCircle, color: "#16a34a" },
    { title: "Users", value: statsData.totalUsers || 0, icon: Users, color: "#dc2626" },
  ];

  return (
    <div>
      <h1 style={pageTitle}>Dashboard</h1>
      <p style={subtitle}>SmartQ hospital queue management overview</p>

      <div style={grid}>
        {stats.map((item, index) => {
          const Icon = item.icon;
          return (
            <div key={index} style={card}>
              <div style={{ ...iconBox, background: item.color }}>
                <Icon size={24} color="#fff" />
              </div>
              <div>
                <p style={label}>{item.title}</p>
                <h2 style={value}>{item.value}</h2>
              </div>
            </div>
          );
        })}
      </div>

      <div style={chartGrid}>
        <div style={panel}>
          <h2 style={panelTitle}>Token Status</h2>
          <ResponsiveContainer width="100%" height={280}>
            <PieChart>
              <Pie data={chartData} dataKey="value" nameKey="name" outerRadius={95} label>
                {chartData.map((entry, index) => (
                  <Cell key={index} fill={chartColors[index % chartColors.length]} />
                ))}
              </Pie>
              <Tooltip />
            </PieChart>
          </ResponsiveContainer>
        </div>

        <div style={panel}>
          <h2 style={panelTitle}>Queue Summary</h2>
          <ResponsiveContainer width="100%" height={280}>
            <BarChart data={chartData}>
              <XAxis dataKey="name" />
              <YAxis allowDecimals={false} />
              <Tooltip />
              <Bar dataKey="value" fill="#2563eb" radius={[8, 8, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      <div style={contentGrid}>
        <div style={panel}>
          <h2 style={panelTitle}>Today’s Queue</h2>

          <table style={table}>
            <thead>
              <tr>
                <th style={th}>Token</th>
                <th style={th}>Patient</th>
                <th style={th}>Department</th>
                <th style={th}>Status</th>
              </tr>
            </thead>

            <tbody>
              {tokens.map((token) => (
                <tr key={token._id}>
                  <td style={td}>
                    {token.prefix}
                    {String(token.tokenNumber).padStart(3, "0")}
                  </td>
                  <td style={td}>{token.patientName}</td>
                  <td style={td}>{token.department?.name}</td>
                  <td style={td}>
                    <span style={getBadge(token.status)}>{token.status}</span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>

          {tokens.length === 0 && (
            <p style={{ textAlign: "center", color: "#64748b" }}>
              No tokens found
            </p>
          )}
        </div>
      </div>
    </div>
  );
}

const getBadge = (status) => ({
  background: status === "Completed" ? "#dcfce7" : status === "Cancelled" ? "#fee2e2" : "#fef3c7",
  color: status === "Completed" ? "#15803d" : status === "Cancelled" ? "#b91c1c" : "#92400e",
  padding: "6px 12px",
  borderRadius: "20px",
});

const chartColors = ["#f59e0b", "#2563eb", "#7c3aed", "#16a34a", "#dc2626"];

const pageTitle = { margin: 0, color: "#0f172a" };
const subtitle = { color: "#64748b", marginBottom: "24px" };
const grid = { display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: "20px" };
const chartGrid = { display: "grid", gridTemplateColumns: "1fr 1fr", gap: "20px", marginTop: "24px" };
const card = { background: "#fff", padding: "22px", borderRadius: "18px", display: "flex", alignItems: "center", gap: "16px", boxShadow: "0 6px 18px rgba(15, 23, 42, 0.06)" };
const iconBox = { width: "52px", height: "52px", borderRadius: "14px", display: "flex", alignItems: "center", justifyContent: "center" };
const label = { margin: 0, color: "#64748b", fontSize: "14px" };
const value = { margin: "6px 0 0", fontSize: "30px", color: "#0f172a" };
const contentGrid = { display: "grid", gridTemplateColumns: "1fr", gap: "20px", marginTop: "24px" };
const panel = { background: "#fff", padding: "24px", borderRadius: "18px", boxShadow: "0 6px 18px rgba(15, 23, 42, 0.06)" };
const panelTitle = { marginTop: 0, color: "#0f172a" };
const table = { width: "100%", borderCollapse: "collapse" };
const th = { textAlign: "left", padding: "14px", borderBottom: "1px solid #e5e7eb", color: "#475569" };
const td = { padding: "14px", borderBottom: "1px solid #f1f5f9" };

export default Dashboard;