import { NavLink, Outlet, useNavigate } from "react-router-dom";
import { useEffect, useState } from "react";
import { getLoggedAdmin } from "./api/adminAuthApi";
import "./styles/admin.css";
import logo from "./assets/logo.png";

function AdminLayout() {
  const navigate = useNavigate();

  function handleLogout() {
    localStorage.removeItem("admin_token");
    navigate("/login");
  }
const [admin, setAdmin] = useState(null);

useEffect(() => {
  setAdmin(getLoggedAdmin());
}, []);

  return (
    <div className="admin-shell">
      <aside className="sidebar">
        <div className="sidebar-brand">
          <div className="sidebar-logo"> <img src={logo} alt="Health For Home" /></div>
          <div>
            <div className="sidebar-title">Panel Administratora</div>
            <div className="sidebar-subtitle">Biznes panel</div>
          </div>
        </div>

        <nav className="sidebar-nav">
          <NavLink to="/dashboard" className={({ isActive }) => `sidebar-item ${isActive ? "active" : ""}`}>
            Strona główna
          </NavLink>

          <NavLink to="/specialists" className={({ isActive }) => `sidebar-item ${isActive ? "active" : ""}`}>
            Specjaliści
          </NavLink>

          <NavLink to="/users" className={({ isActive }) => `sidebar-item ${isActive ? "active" : ""}`}>
            Użytkownicy
          </NavLink>

          <NavLink to="/orders" className={({ isActive }) => `sidebar-item ${isActive ? "active" : ""}`}>
            Zamówienia
          </NavLink>
        </nav>

        <div className="sidebar-footer">
          <button className="btn-logout" onClick={handleLogout}>
            Wyloguj
          </button>
        </div>
      </aside>


      <main className="admin-main">
        <div className="admin-container">
          <div className="topbar">
            <div className="topbar-left">
              <div className="topbar-meta">
                Zalogowano: {admin?.email ?? "—"}
              </div>
            </div>

            <div className="topbar-right">
              {new Date().toLocaleString(undefined, { dateStyle: "short", timeStyle: "short" })}
            </div>
          </div>

          <Outlet />
        </div>
      </main>

    </div>
  );
}

export default AdminLayout;
