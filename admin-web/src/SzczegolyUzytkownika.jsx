import { useEffect, useMemo, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import AdminHeader from "./components/AdminHeader";
import { getUser } from "./api/adminApi";
import "./styles/uzytkownikSzczegoly.css";

function initials(firstName, lastName) {
  const a = (firstName || "").trim().charAt(0).toUpperCase();
  const b = (lastName || "").trim().charAt(0).toUpperCase();
  return (a + b) || "??";
}

function SzczegolyUzytkownika() {
  const { id } = useParams();
  const navigate = useNavigate();

  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setError("");

    getUser(id)
      .then((res) => {
        if (!cancelled) setData(res);
      })
      .catch((e) => {
        if (!cancelled) setError(e?.message || "Błąd pobierania danych użytkownika");
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });

    return () => {
      cancelled = true;
    };
  }, [id]);

  const createdAtLabel = useMemo(() => {
    if (!data?.createdAt) return "-";
    const d = new Date(data.createdAt);
    return Number.isNaN(d.getTime()) ? "-" : d.toLocaleString();
  }, [data]);

  if (loading) return <p style={{ padding: 24 }}>Ładowanie...</p>;
  if (error) return <p style={{ padding: 24, color: "tomato" }}>{error}</p>;
  if (!data) return null;

  return (
    <div>
      <AdminHeader />

      <div className="admin-container">
        <div className="page user-details-wrap">
          <div className="user-details-hero">
            <h1 className="user-details-title">Szczegóły użytkownika</h1>
          </div>

          {/* Header card */}
          <div className="user-profile-card">
            <div className="user-profile-left">
              <div className="user-avatar">{initials(data.firstName, data.lastName)}</div>

              <div className="user-profile-main">
                <h2 className="user-name">
                  {data.firstName} {data.lastName}
                </h2>
                <div className="user-email">{data.email}</div>
              </div>
            </div>

            {/* Bez Zablokuj i Usuń */}
            <div className="user-actions">
              <button className="btn" onClick={() => alert("TODO: edycja")} type="button">
                Edytuj
              </button>
            </div>
          </div>

          {/* Cards grid */}
          <div className="user-details-grid">
            <div className="user-card">
              <h3 className="user-card-title">Informacje podstawowe</h3>

              <div className="user-kv">
                <div className="user-kv-row">
                  <div className="user-kv-key">ID użytkownika</div>
                  <div className="user-kv-val">{data.id}</div>
                </div>

                <div className="user-kv-row">
                  <div className="user-kv-key">Telefon</div>
                  <div className="user-kv-val">{data.phone || "-"}</div>
                </div>

                <div className="user-kv-row">
                  <div className="user-kv-key">Data rejestracji</div>
                  <div className="user-kv-val">{createdAtLabel}</div>
                </div>
              </div>
            </div>

            <div className="user-card user-card--activity">
              <h3 className="user-card-title">Aktywność</h3>

              <div className="user-kv">
                <div className="user-kv-row">
                  <div className="user-kv-key">Liczba zamówień</div>
                  <div className="user-kv-val">
                    {typeof data.ordersCount === "number" ? data.ordersCount : "-"}
                  </div>
                </div>

                <div className="user-kv-row">
                  <div className="user-kv-key">Wartość zamówień</div>
                  <div className="user-kv-val">
                    {typeof data.ordersTotalValue === "number" ? `${data.ordersTotalValue} PLN` : "-"}
                  </div>
                </div>
              </div>
            </div>

           
            <div className="user-card user-activity-card">
              <div className="user-activity-head">
                <h3 className="user-card-title" style={{ margin: 0 }}>Aktywność</h3>
              </div>

              <div className="user-activity-body">
                <table className="user-activity-table">
                  <thead>
                    <tr>
                      <th>ID</th>
                      <th>Data</th>
                      <th>Status</th>
                      <th>Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td colSpan={4} className="user-activity-empty">
                        Użytkownik nie złożył jeszcze żadnego zamówienia.
                      </td>
                    </tr>
                  </tbody>
                </table>

                <div className="user-back-row">
                  <button className="user-back-link" onClick={() => navigate("/users")} type="button">
                    ← Lista użytkowników
                  </button>
                </div>
              </div>
            </div>
          </div>

        </div>
      </div>
    </div>
  );
}

export default SzczegolyUzytkownika;
