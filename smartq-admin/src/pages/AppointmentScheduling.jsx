import { useEffect, useState } from "react";
import api from "../services/api";
import socket from "../services/socket";

function AppointmentScheduling() {
  const [appointments, setAppointments] = useState([]);
  const [hospitals, setHospitals] = useState([]);
  const [departments, setDepartments] = useState([]);

  const [patientName, setPatientName] = useState("");
  const [patientPhone, setPatientPhone] = useState("");
  const [hospital, setHospital] = useState("");
  const [department, setDepartment] = useState("");
  const [doctorName, setDoctorName] = useState("");
  const [appointmentDate, setAppointmentDate] = useState("");
  const [appointmentTime, setAppointmentTime] = useState("");

  useEffect(() => {
    loadData();

    socket.on("appointmentsUpdated", loadData);
    socket.on("dashboardUpdated", loadData);

    return () => {
      socket.off("appointmentsUpdated", loadData);
      socket.off("dashboardUpdated", loadData);
    };
  }, []);

  const loadData = async () => {
    const appointmentRes = await api.get("/appointments");
    setAppointments(appointmentRes.data);

    const hospitalRes = await api.get("/hospitals");
    setHospitals(hospitalRes.data);

    const departmentRes = await api.get("/departments");
    setDepartments(departmentRes.data);
  };

  const addAppointment = async () => {
    if (!patientName || !hospital || !department || !appointmentDate || !appointmentTime) {
      alert("Please fill all required fields");
      return;
    }

    await api.post("/appointments", {
      patientName,
      patientPhone,
      hospital,
      department,
      doctorName,
      appointmentDate,
      appointmentTime,
    });

    setPatientName("");
    setPatientPhone("");
    setHospital("");
    setDepartment("");
    setDoctorName("");
    setAppointmentDate("");
    setAppointmentTime("");

    loadData();
  };

  const updateStatus = async (id, status) => {
    await api.put(`/appointments/${id}`, { status });
    loadData();
  };

  const deleteAppointment = async (id) => {
    if (confirm("Delete this appointment?")) {
      await api.delete(`/appointments/${id}`);
      loadData();
    }
  };

  const filteredDepartments = departments.filter(
    (d) => d.hospital?._id === hospital || d.hospital === hospital
  );

  return (
    <div>
      <h1>Appointment Scheduling</h1>
      <p style={subtitle}>Create and manage patient appointments</p>

      <div style={formBox}>
        <input style={input} placeholder="Patient Name" value={patientName} onChange={(e) => setPatientName(e.target.value)} />

        <input style={input} placeholder="Phone Number" value={patientPhone} onChange={(e) => setPatientPhone(e.target.value)} />

        <select style={input} value={hospital} onChange={(e) => {
          setHospital(e.target.value);
          setDepartment("");
        }}>
          <option value="">Select Hospital</option>
          {hospitals.map((h) => (
            <option key={h._id} value={h._id}>{h.name}</option>
          ))}
        </select>

        <select style={input} value={department} onChange={(e) => setDepartment(e.target.value)}>
          <option value="">Select Department</option>
          {filteredDepartments.map((d) => (
            <option key={d._id} value={d._id}>{d.name}</option>
          ))}
        </select>

        <input style={input} placeholder="Doctor Name" value={doctorName} onChange={(e) => setDoctorName(e.target.value)} />

        <input style={input} type="date" value={appointmentDate} onChange={(e) => setAppointmentDate(e.target.value)} />

        <input style={input} type="time" value={appointmentTime} onChange={(e) => setAppointmentTime(e.target.value)} />

        <button style={button} onClick={addAppointment}>Add Appointment</button>
      </div>

      <div style={tableBox}>
        <table style={table}>
          <thead>
            <tr>
              <th style={th}>Patient</th>
              <th style={th}>Phone</th>
              <th style={th}>Hospital</th>
              <th style={th}>Department</th>
              <th style={th}>Doctor</th>
              <th style={th}>Date</th>
              <th style={th}>Time</th>
              <th style={th}>Status</th>
              <th style={th}>Actions</th>
            </tr>
          </thead>

          <tbody>
            {appointments.map((a) => (
              <tr key={a._id}>
                <td style={td}>{a.patientName}</td>
                <td style={td}>{a.patientPhone || "-"}</td>
                <td style={td}>{a.hospital?.name}</td>
                <td style={td}>{a.department?.name}</td>
                <td style={td}>{a.doctorName || "-"}</td>
                <td style={td}>{a.appointmentDate}</td>
                <td style={td}>{a.appointmentTime}</td>
                <td style={td}>{a.status}</td>
                <td style={td}>
                  <button style={completeBtn} onClick={() => updateStatus(a._id, "Completed")}>
                    Complete
                  </button>
                  <button style={cancelBtn} onClick={() => updateStatus(a._id, "Cancelled")}>
                    Cancel
                  </button>
                  <button style={deleteBtn} onClick={() => deleteAppointment(a._id)}>
                    Delete
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {appointments.length === 0 && (
          <p style={{ textAlign: "center", color: "#6b7280" }}>
            No appointments found
          </p>
        )}
      </div>
    </div>
  );
}

const subtitle = { color: "#6b7280", marginBottom: "20px" };

const formBox = {
  background: "#fff",
  padding: "20px",
  borderRadius: "16px",
  display: "grid",
  gridTemplateColumns: "repeat(4, 1fr)",
  gap: "12px",
  marginBottom: "24px",
};

const input = { padding: "12px", border: "1px solid #e5e7eb", borderRadius: "10px" };
const button = { background: "#2563eb", color: "#fff", border: "none", borderRadius: "10px", cursor: "pointer" };
const tableBox = { background: "#fff", padding: "20px", borderRadius: "16px" };
const table = { width: "100%", borderCollapse: "collapse" };
const th = { textAlign: "left", padding: "14px", borderBottom: "1px solid #e5e7eb" };
const td = { padding: "14px", borderBottom: "1px solid #f1f5f9" };

const completeBtn = { marginRight: "8px", padding: "7px 12px", border: "none", borderRadius: "8px", background: "#dcfce7", color: "#15803d", cursor: "pointer" };
const cancelBtn = { marginRight: "8px", padding: "7px 12px", border: "none", borderRadius: "8px", background: "#fee2e2", color: "#b91c1c", cursor: "pointer" };
const deleteBtn = { padding: "7px 12px", border: "none", borderRadius: "8px", background: "#f3f4f6", color: "#374151", cursor: "pointer" };

export default AppointmentScheduling;