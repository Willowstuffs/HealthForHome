import { Navigate } from "react-router-dom";

function RequireAdminAuth({ children }) {
  const token = localStorage.getItem("admin_token");
  const rawUser = localStorage.getItem("admin_user");

  if (!token || !rawUser) {
    return <Navigate to="/login" replace />;
  }

  try {
    const user = JSON.parse(rawUser);

    if (user?.userType !== "admin") {
      localStorage.removeItem("admin_token");
      localStorage.removeItem("admin_user");
      return <Navigate to="/login" replace />;
    }
  } catch {
    localStorage.removeItem("admin_token");
    localStorage.removeItem("admin_user");
    return <Navigate to="/login" replace />;
  }

  return children;
}

export default RequireAdminAuth;