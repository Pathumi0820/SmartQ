import { useState } from "react";
import Sidebar from "./Sidebar";
import Topbar from "./Topbar";

function AdminLayout({ children }) {
  const [sidebarOpen, setSidebarOpen] = useState(false);

  return (
    <div style={layout}>
      <Sidebar setSidebarOpen={setSidebarOpen} />

      <div
        style={{
          ...content,
          marginLeft: sidebarOpen ? "250px" : "78px",
        }}
      >
        <Topbar />
        <main style={main}>{children}</main>
      </div>
    </div>
  );
}

const layout = {
  minHeight: "100vh",
  background: "#f8fafc",
};

const content = {
  minHeight: "100vh",
  display: "flex",
  flexDirection: "column",
  transition: "margin-left 0.3s ease",
};

const main = {
  padding: "24px",
  boxSizing: "border-box",
};

export default AdminLayout;