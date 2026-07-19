import { Navigate } from "react-router-dom";
import { auth } from "../firebase";

function ProtectedRoute({ children, allowedRoles = [] }) {
  const user = auth.currentUser;
  const userRole = localStorage.getItem("userRole");

  if (!user) {
    return <Navigate to="/login" replace />;
  }

  if (
    allowedRoles.length > 0 &&
    !allowedRoles.includes(userRole)
  ) {
    return <Navigate to="/login" replace />;
  }

  return children;
}

export default ProtectedRoute;