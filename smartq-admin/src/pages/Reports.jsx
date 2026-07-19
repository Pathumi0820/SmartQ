import { useEffect, useState } from "react";
import api from "../services/api";
import socket from "../services/socket";
import jsPDF from "jspdf";
import autoTable from "jspdf-autotable";
import * as XLSX from "xlsx";
import { saveAs } from "file-saver";

function Reports() {
  const [summary, setSummary] = useState({});
  const [tokens, setTokens] = useState([]);
  const [appointments, setAppointments] = useState([]);

  useEffect(() => {
    loadReports();

    socket.on("tokensUpdated", loadReports);
    socket.on("appointmentsUpdated", loadReports);
    socket.on("reportsUpdated", loadReports);

    return () => {
      socket.off("tokensUpdated", loadReports);
      socket.off("appointmentsUpdated", loadReports);
      socket.off("reportsUpdated", loadReports);
    };
  }, []);

  const loadReports = async () => {
    const res = await api.get("/reports");
    setSummary(res.data.summary);
    setTokens(res.data.tokens);
    setAppointments(res.data.appointments);
  };

  const formatToken = (t) =>
    `${t.prefix}${String(t.tokenNumber).padStart(3, "0")}`;

  const exportTokenPDF = () => {
    const doc = new jsPDF();
    doc.text("SmartQ Token Report", 14, 15);

    autoTable(doc, {
      startY: 25,
      head: [["Token", "Patient", "Hospital", "Department", "Status", "Date"]],
      body: tokens.map((t) => [
        formatToken(t),
        t.patientName,
        t.hospital?.name || "-",
        t.department?.name || "-",
        t.status,
        new Date(t.createdAt).toLocaleDateString(),
      ]),
    });

    doc.save("smartq-token-report.pdf");
  };

  const exportAppointmentPDF = () => {
    const doc = new jsPDF();
    doc.text("SmartQ Appointment Report", 14, 15);

    autoTable(doc, {
      startY: 25,
      head: [["Patient", "Hospital", "Department", "Date", "Time", "Status"]],
      body: appointments.map((a) => [
        a.patientName,
        a.hospital?.name || "-",
        a.department?.name || "-",
        a.appointmentDate,
        a.appointmentTime,
        a.status,
      ]),
    });

    doc.save("smartq-appointment-report.pdf");
  };

  const exportExcel = () => {
    const tokenData = tokens.map((t) => ({
      Token: formatToken(t),
      Patient: t.patientName,
      Hospital: t.hospital?.name || "-",
      Department: t.department?.name || "-",
      Status: t.status,
      Date: new Date(t.createdAt).toLocaleDateString(),
    }));

    const appointmentData = appointments.map((a) => ({
      Patient: a.patientName,
      Hospital: a.hospital?.name || "-",
      Department: a.department?.name || "-",
      Date: a.appointmentDate,
      Time: a.appointmentTime,
      Status: a.status,
    }));

    const workbook = XLSX.utils.book_new();

    XLSX.utils.book_append_sheet(
      workbook,
      XLSX.utils.json_to_sheet(tokenData),
      "Tokens"
    );

    XLSX.utils.book_append_sheet(
      workbook,
      XLSX.utils.json_to_sheet(appointmentData),
      "Appointments"
    );

    const excelBuffer = XLSX.write(workbook, {
      bookType: "xlsx",
      type: "array",
    });

    const file = new Blob([excelBuffer], {
      type: "application/octet-stream",
    });

    saveAs(file, "smartq-reports.xlsx");
  };

  const reports = [
    { title: "Total Tokens", value: summary.totalTokens || 0 },
    { title: "Completed Tokens", value: summary.completedTokens || 0 },
    { title: "Waiting Tokens", value: summary.waitingTokens || 0 },
    { title: "Cancelled Tokens", value: summary.cancelledTokens || 0 },
    { title: "Appointments", value: summary.totalAppointments || 0 },
  ];

  return (
    <div>
      <h1>Reports</h1>
      <p style={subtitle}>View token and hospital activity reports</p>

      <div style={grid}>
        {reports.map((report, index) => (
          <div key={index} style={card}>
            <p style={label}>{report.title}</p>
            <h2 style={value}>{report.value}</h2>
          </div>
        ))}
      </div>

      <div style={exportBox}>
        <button style={button} onClick={exportTokenPDF}>
          Export Token PDF
        </button>
        <button style={button} onClick={exportAppointmentPDF}>
          Export Appointment PDF
        </button>
        <button style={excelBtn} onClick={exportExcel}>
          Export Excel
        </button>
      </div>

      <div style={tableBox}>
        <h2>Token Report</h2>

        <table style={table}>
          <thead>
            <tr>
              <th style={th}>Token</th>
              <th style={th}>Patient</th>
              <th style={th}>Hospital</th>
              <th style={th}>Department</th>
              <th style={th}>Status</th>
              <th style={th}>Date</th>
            </tr>
          </thead>

          <tbody>
            {tokens.map((t) => (
              <tr key={t._id}>
                <td style={td}>{formatToken(t)}</td>
                <td style={td}>{t.patientName}</td>
                <td style={td}>{t.hospital?.name}</td>
                <td style={td}>{t.department?.name}</td>
                <td style={td}>{t.status}</td>
                <td style={td}>{new Date(t.createdAt).toLocaleDateString()}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div style={tableBox}>
        <h2>Appointment Report</h2>

        <table style={table}>
          <thead>
            <tr>
              <th style={th}>Patient</th>
              <th style={th}>Hospital</th>
              <th style={th}>Department</th>
              <th style={th}>Date</th>
              <th style={th}>Time</th>
              <th style={th}>Status</th>
            </tr>
          </thead>

          <tbody>
            {appointments.map((a) => (
              <tr key={a._id}>
                <td style={td}>{a.patientName}</td>
                <td style={td}>{a.hospital?.name}</td>
                <td style={td}>{a.department?.name}</td>
                <td style={td}>{a.appointmentDate}</td>
                <td style={td}>{a.appointmentTime}</td>
                <td style={td}>{a.status}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

const subtitle = { color: "#6b7280", marginBottom: "24px" };

const grid = {
  display: "grid",
  gridTemplateColumns: "repeat(5, 1fr)",
  gap: "20px",
};

const card = {
  background: "#fff",
  padding: "24px",
  borderRadius: "16px",
};

const label = { color: "#6b7280" };
const value = { fontSize: "32px", color: "#2563eb" };

const exportBox = {
  display: "flex",
  gap: "12px",
  marginTop: "24px",
};

const button = {
  background: "#2563eb",
  color: "#fff",
  border: "none",
  padding: "10px 16px",
  borderRadius: "8px",
  cursor: "pointer",
};

const excelBtn = {
  background: "#16a34a",
  color: "#fff",
  border: "none",
  padding: "10px 16px",
  borderRadius: "8px",
  cursor: "pointer",
};

const tableBox = {
  background: "#fff",
  padding: "24px",
  borderRadius: "16px",
  marginTop: "24px",
};

const table = { width: "100%", borderCollapse: "collapse" };

const th = {
  textAlign: "left",
  padding: "14px",
  borderBottom: "1px solid #e5e7eb",
};

const td = {
  padding: "14px",
  borderBottom: "1px solid #f1f5f9",
};

export default Reports;