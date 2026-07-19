import { useEffect, useState } from "react";
import { Search, Plus, Edit, Trash2, Hospital, X } from "lucide-react";
import api from "../services/api";

function HospitalManagement() {
  const [hospitals, setHospitals] = useState([]);
  const [name, setName] = useState("");
  const [city, setCity] = useState("");
  const [search, setSearch] = useState("");
  const [editId, setEditId] = useState(null);

  useEffect(() => {
    fetchHospitals();
  }, []);

  const fetchHospitals = async () => {
    try {
      const res = await api.get("/hospitals");
      console.log("Hospitals from backend:", res.data);
      setHospitals(res.data);
    } catch (error) {
      console.error("Fetch hospitals error:", error.response?.data || error);
      alert(error.response?.data?.message || "Failed to load hospitals");
    }
  };

  const saveHospital = async () => {
    if (!name || !city) {
      alert("Please fill all fields");
      return;
    }

    if (editId) {
      await api.put(`/hospitals/${editId}`, { name, city });
    } else {
      await api.post("/hospitals", { name, city });
    }

    setName("");
    setCity("");
    setEditId(null);
    fetchHospitals();
  };

  const startEdit = (hospital) => {
    setEditId(hospital._id);
    setName(hospital.name);
    setCity(hospital.city);
  };

  const cancelEdit = () => {
    setEditId(null);
    setName("");
    setCity("");
  };

  const deleteHospital = async (id) => {
    if (confirm("Delete this hospital?")) {
      await api.delete(`/hospitals/${id}`);
      fetchHospitals();
    }
  };

  const filteredHospitals = hospitals.filter((h) =>
    h.name.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div>
      <h1 style={title}>Hospital Management</h1>
      <p style={subtitle}>Add and manage hospitals in SmartQ</p>

      <div style={formCard}>
        <input
          style={input}
          placeholder="Hospital Name"
          value={name}
          onChange={(e) => setName(e.target.value)}
        />

        <input
          style={input}
          placeholder="City"
          value={city}
          onChange={(e) => setCity(e.target.value)}
        />

        <button style={addBtn} onClick={saveHospital}>
          <Plus size={18} /> {editId ? "Update Hospital" : "Add Hospital"}
        </button>

        {editId && (
          <button style={cancelBtn} onClick={cancelEdit}>
            <X size={18} /> Cancel
          </button>
        )}
      </div>

      <div style={tableCard}>
        <div style={tableHeader}>
          <h2 style={{ margin: 0 }}>Hospitals</h2>

          <div style={searchBox}>
            <Search size={18} color="#64748b" />
            <input
              style={searchInput}
              placeholder="Search hospital..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>
        </div>

        <table style={table}>
          <thead>
            <tr>
              <th style={th}>Hospital</th>
              <th style={th}>City</th>
              <th style={th}>Status</th>
              <th style={th}>Actions</th>
            </tr>
          </thead>

          <tbody>
            {filteredHospitals.map((hospital) => (
              <tr key={hospital._id}>
                <td style={td}>
                  <div style={hospitalCell}>
                    <div style={iconBox}>
                      <Hospital size={20} color="#2563eb" />
                    </div>
                    {hospital.name}
                  </div>
                </td>

                <td style={td}>{hospital.city}</td>

                <td style={td}>
                  <span style={activeBadge}>{hospital.status}</span>
                </td>

                <td style={td}>
                  <button style={editBtn} onClick={() => startEdit(hospital)}>
                    <Edit size={16} />
                  </button>

                  <button
                    style={deleteBtn}
                    onClick={() => deleteHospital(hospital._id)}
                  >
                    <Trash2 size={16} />
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {filteredHospitals.length === 0 && (
          <p style={{ textAlign: "center", color: "#64748b" }}>
            No hospitals found
          </p>
        )}
      </div>
    </div>
  );
}

const title = { margin: 0, color: "#0f172a" };
const subtitle = { color: "#64748b", marginBottom: "24px" };

const formCard = {
  background: "#fff",
  padding: "20px",
  borderRadius: "18px",
  display: "grid",
  gridTemplateColumns: "1fr 1fr auto auto",
  gap: "14px",
  marginBottom: "24px",
  boxShadow: "0 6px 18px rgba(15,23,42,0.06)",
};

const input = {
  padding: "12px",
  border: "1px solid #e5e7eb",
  borderRadius: "12px",
};

const addBtn = {
  background: "#2563eb",
  color: "#fff",
  border: "none",
  borderRadius: "12px",
  padding: "0 18px",
  display: "flex",
  alignItems: "center",
  gap: "8px",
  cursor: "pointer",
};

const cancelBtn = {
  background: "#64748b",
  color: "#fff",
  border: "none",
  borderRadius: "12px",
  padding: "0 18px",
  display: "flex",
  alignItems: "center",
  gap: "8px",
  cursor: "pointer",
};

const tableCard = {
  background: "#fff",
  padding: "24px",
  borderRadius: "18px",
  boxShadow: "0 6px 18px rgba(15,23,42,0.06)",
};

const tableHeader = {
  display: "flex",
  justifyContent: "space-between",
  alignItems: "center",
  marginBottom: "18px",
};

const searchBox = {
  display: "flex",
  alignItems: "center",
  gap: "8px",
  border: "1px solid #e5e7eb",
  borderRadius: "12px",
  padding: "10px 12px",
};

const searchInput = {
  border: "none",
  outline: "none",
};

const table = { width: "100%", borderCollapse: "collapse" };

const th = {
  textAlign: "left",
  padding: "14px",
  borderBottom: "1px solid #e5e7eb",
  color: "#475569",
};

const td = {
  padding: "14px",
  borderBottom: "1px solid #f1f5f9",
};

const hospitalCell = {
  display: "flex",
  alignItems: "center",
  gap: "12px",
};

const iconBox = {
  width: "38px",
  height: "38px",
  borderRadius: "12px",
  background: "#eff6ff",
  display: "flex",
  alignItems: "center",
  justifyContent: "center",
};

const activeBadge = {
  background: "#dcfce7",
  color: "#15803d",
  padding: "6px 12px",
  borderRadius: "20px",
};

const editBtn = {
  marginRight: "8px",
  border: "none",
  background: "#e0f2fe",
  color: "#0369a1",
  padding: "8px",
  borderRadius: "10px",
  cursor: "pointer",
};

const deleteBtn = {
  border: "none",
  background: "#fee2e2",
  color: "#b91c1c",
  padding: "8px",
  borderRadius: "10px",
  cursor: "pointer",
};

export default HospitalManagement;