import {
  BrowserRouter,
  Route,
  Routes,
} from "react-router-dom";

import AdminLayout from "./components/AdminLayout";

import AppointmentScheduling from "./pages/AppointmentScheduling";
import ChangePassword from "./pages/ChangePassword";
import Dashboard from "./pages/Dashboard";
import DepartmentManagement from "./pages/DepartmentManagement";
import DisplayBoard from "./pages/DisplayBoard";
import HospitalManagement from "./pages/HospitalManagement";
import Login from "./pages/Login";
import QueueSessions from "./pages/QueueSessions";
import Reports from "./pages/Reports";
import TokenList from "./pages/TokenList";
import UserManagement from "./pages/UserManagement";
import VerifyPatient from "./pages/VerifyPatient";

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route
          path="/login"
          element={<Login />}
        />

        <Route
          path="/"
          element={
            <AdminLayout>
              <Dashboard />
            </AdminLayout>
          }
        />

        <Route
          path="/hospitals"
          element={
            <AdminLayout>
              <HospitalManagement />
            </AdminLayout>
          }
        />

        <Route
          path="/departments"
          element={
            <AdminLayout>
              <DepartmentManagement />
            </AdminLayout>
          }
        />

        <Route
          path="/users"
          element={
            <AdminLayout>
              <UserManagement />
            </AdminLayout>
          }
        />

        <Route
          path="/appointments"
          element={
            <AdminLayout>
              <AppointmentScheduling />
            </AdminLayout>
          }
        />

        <Route
          path="/display"
          element={
            <AdminLayout>
              <DisplayBoard />
            </AdminLayout>
          }
        />

        <Route
          path="/queue-sessions"
          element={
            <AdminLayout>
              <QueueSessions />
            </AdminLayout>
          }
        />

        <Route
          path="/tokens"
          element={
            <AdminLayout>
              <TokenList />
            </AdminLayout>
          }
        />

        <Route
          path="/verify"
          element={
            <AdminLayout>
              <VerifyPatient />
            </AdminLayout>
          }
        />

        <Route
          path="/reports"
          element={
            <AdminLayout>
              <Reports />
            </AdminLayout>
          }
        />

        <Route
          path="/change-password"
          element={
            <AdminLayout>
              <ChangePassword />
            </AdminLayout>
          }
        />
      </Routes>
    </BrowserRouter>
  );
}

export default App;