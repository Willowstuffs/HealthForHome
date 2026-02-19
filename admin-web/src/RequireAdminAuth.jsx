import { Navigate } from "react-router-dom";

function RequireAdminAuth({ children }) {
  const token = localStorage.getItem("admin_token");

  if (!token) {
    return <Navigate to="/login" replace />;
  }

  return children;
}

export default RequireAdminAuth;
