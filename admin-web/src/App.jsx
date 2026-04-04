import { Routes, Route, Navigate } from "react-router-dom";

import LoginPage from "./LoginPage.jsx";
import RequireAdminAuth from "./RequireAdminAuth.jsx";

import AdminLayout from "./AdminLayout.jsx";
import Dashboard from "./Dashboard.jsx";

import ListaSpecjalistow from "./ListaSpecjalistow.jsx";
import SzczegolySpecjalisty from "./SzczegolySpecjalisty.jsx";

import ListaUzytkownikow from "./ListaUzytkownikow.jsx";
import SzczegolyUzytkownika from "./SzczegolyUzytkownika.jsx";

import ListaZamowien from "./ListaZamowien.jsx";
import SzczegolyZamowienia from "./SzczegolyZamowienia.jsx";
import "/src/styles/admin.css";


function App() {
  return (
    <Routes>
      <Route path="/" element={<Navigate to="/login" replace />} />
      <Route path="/login" element={<LoginPage />} />

      {/* wszystko po zalogowaniu ma wspólny layout */}
      <Route
        element={
          <RequireAdminAuth>
            <AdminLayout />
          </RequireAdminAuth>
        }
      >
        <Route path="/dashboard" element={<Dashboard />} />

        <Route path="/specialists" element={<ListaSpecjalistow />} />
        <Route path="/specialists/:id" element={<SzczegolySpecjalisty />} />

        <Route path="/users" element={<ListaUzytkownikow />} />
        <Route path="/users/:id" element={<SzczegolyUzytkownika />} />

        <Route path="/orders" element={<ListaZamowien />} />
        <Route path="/orders/:id" element={<SzczegolyZamowienia />} />

        {/* fallback w panelu */}
        <Route path="*" element={<div style={{ padding: 24 }}>404 - Nie znaleziono strony</div>} />
      </Route>
    </Routes>
  );
}

export default App;
