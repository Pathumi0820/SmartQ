import { useEffect, useState } from "react";
import api from "../services/api";

function DepartmentManagement() {
  const [departments, setDepartments] = useState([]);
  const [hospitals, setHospitals] = useState([]);

  const [name, setName] = useState("");
  const [hospitalId, setHospitalId] = useState("");
  const [prefix, setPrefix] = useState("");
  const [editId, setEditId] = useState(null);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    const hospitalRes = await api.get("/hospitals");
    setHospitals(hospitalRes.data);

    const departmentRes = await api.get("/departments");
    setDepartments(departmentRes.data);
  };

  const saveDepartment = async () => {
    if (!name || !hospitalId || !prefix) {
      alert("Please fill all fields");
      return;
    }

    const data = {
      name,
      hospital: hospitalId,
      prefix,
    };

    if (editId) {
      await api.put(`/departments/${editId}`, data);
    } else {
      await api.post("/departments", data);
    }

    setName("");
    setHospitalId("");
    setPrefix("");
    setEditId(null);
    loadData();
  };

  const editDepartment = (department) => {
    setEditId(department._id);
    setName(department.name);
    setHospitalId(department.hospital?._id || department.hospital);
    setPrefix(department.prefix || "");
  };

  const deleteDepartment = async (id) => {
    if (confirm("Delete this department?")) {
      await api.delete(`/departments/${id}`);
      loadData();
    }
  };

  return (
    <div>
      <h1>Department Management</h1>
      <p style={subtitle}>Add, edit and manage hospital departments</p>

      <div style={formBox}>
        <input
          style={input}
          placeholder="Department Name"
          value={name}
          onChange={(e) => setName(e.target.value)}
        />

        <select
          style={input}
          value={hospitalId}
          onChange={(e) => setHospitalId(e.target.value)}
        >
          <option value="">Select Hospital</option>
          {hospitals.map((hospital) => (
            <option key={hospital._id} value={hospital._id}>
              {hospital.name}
            </option>
          ))}
        </select>

        <input
          style={input}
          placeholder="Token Prefix"
          value={prefix}
          onChange={(e) => setPrefix(e.target.value.toUpperCase())}
        />

        <button style={button} onClick={saveDepartment}>
          {editId ? "Update Department" : "Add Department"}
        </button>
      </div>

      <div style={tableBox}>
        <table style={table}>
          <thead>
            <tr>
              <th style={th}>Department</th>
              <th style={th}>Hospital</th>
              <th style={th}>Prefix</th>
              <th style={th}>Status</th>
              <th style={th}>Actions</th>
            </tr>
          </thead>

          <tbody>
            {departments.map((department) => (
              <tr key={department._id}>
                <td style={td}>{department.name}</td>
                <td style={td}>{department.hospital?.name}</td>
                <td style={td}>
                  <span style={badge}>{department.prefix}</span>
                </td>
                <td style={td}>{department.status}</td>
                <td style={td}>
                  <button style={editBtn} onClick={() => editDepartment(department)}>
                    Edit
                  </button>
                  <button style={deleteBtn} onClick={() => deleteDepartment(department._id)}>
                    Delete
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {departments.length === 0 && (
          <p style={{ textAlign: "center", color: "#6b7280" }}>
            No departments found
          </p>
        )}
      </div>
    </div>
  );
}

const subtitle = { color: "#6b7280", marginBottom: "20px" };
const formBox = { background: "#fff", padding: "20px", borderRadius: "16px", display: "flex", gap: "12px", marginBottom: "24px" };
const input = { flex: 1, padding: "12px", border: "1px solid #e5e7eb", borderRadius: "10px" };
const button = { background: "#2563eb", color: "#fff", border: "none", padding: "12px 18px", borderRadius: "10px", cursor: "pointer" };
const tableBox = { background: "#fff", padding: "20px", borderRadius: "16px" };
const table = { width: "100%", borderCollapse: "collapse" };
const th = { textAlign: "left", padding: "14px", borderBottom: "1px solid #e5e7eb" };
const td = { padding: "14px", borderBottom: "1px solid #f1f5f9" };
const badge = { background: "#dbeafe", color: "#1d4ed8", padding: "6px 12px", borderRadius: "20px" };
const editBtn = { marginRight: "8px", padding: "7px 12px", border: "none", borderRadius: "8px", background: "#e0f2fe", color: "#0369a1", cursor: "pointer" };
const deleteBtn = { padding: "7px 12px", border: "none", borderRadius: "8px", background: "#fee2e2", color: "#b91c1c", cursor: "pointer" };

export default DepartmentManagement;