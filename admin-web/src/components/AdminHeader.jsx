import { useNavigate } from "react-router-dom";
import { getLoggedAdmin } from "../api/adminAuthApi";

function AdminHeader() {
  const navigate = useNavigate();
  const admin = getLoggedAdmin();

  function handleLogout() {
    logoutAdmin();
    navigate("/login", { replace: true });
  }

  return (
    <div
      style={{
        padding: "12px 24px",
        borderBottom: "1px solid #444",
        display: "flex",
        justifyContent: "space-between",
        alignItems: "center",
        gap: 12,
      }}
    >
      <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
        <b>Health For Home </b>
        
      </div>
    </div>
  );
}

export default AdminHeader;
