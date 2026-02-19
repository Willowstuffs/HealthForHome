import { useEffect, useMemo, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import AdminHeader from "./components/AdminHeader";
import { getOrder } from "./api/adminApi";
import OrderStatusBadge from "./components/OrderStatusBadge";
import "./styles/zamowienieSzczegoly.css";

function initialsFromName(fullName) {
  const parts = String(fullName || "").trim().split(/\s+/).filter(Boolean);
  const a = (parts[0] || "").charAt(0).toUpperCase();
  const b = (parts[1] || "").charAt(0).toUpperCase();
  return (a + b) || "??";
}

function SzczegolyZamowienia() {
  const { id } = useParams();
  const navigate = useNavigate();

  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setError("");

    getOrder(id)
      .then((res) => {
        if (!cancelled) setData(res);
      })
      .catch((e) => {
        if (!cancelled) setError(e?.message || "Błąd pobierania zamówienia");
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });

    return () => {
      cancelled = true;
    };
  }, [id]);

  const createdAtLabel = useMemo(() => {
    if (!data?.createdAt) return "—";
    const d = new Date(data.createdAt);
    return Number.isNaN(d.getTime()) ? "—" : d.toLocaleString();
  }, [data]);

  if (loading) return <p style={{ padding: 24 }}>Ładowanie...</p>;
  if (error) return <p style={{ padding: 24, color: "tomato" }}>{error}</p>;
  if (!data) return null;

  const customerName =
    !data.userId
      ? ((data.customerFirstName || data.customerLastName)
          ? `${data.customerFirstName ?? ""} ${data.customerLastName ?? ""}`.trim()
          : "Gość")
      : (data.userName || "—");
  const customerEmail =
    typeof data.customerEmail === "string" && data.customerEmail.trim() !== ""
      ? data.customerEmail
      : "—";

  const customerPhone =
    typeof data.customerPhone === "string" && data.customerPhone.trim() !== ""
      ? data.customerPhone
      : "—";


  return (
    <div>
      <AdminHeader />

      <div className="admin-container">
        <div className="page order-wrap">
          <div className="order-hero">
            <div>
              <h1 className="order-title">Szczegóły zamówienia</h1>
            </div>
          </div>

          <div className="order-card">
            {/* header: avatar + customer */}
            <div className="order-header">
              <div className="order-avatar">{initialsFromName(customerName)}</div>

              <div className="order-header-main">
                <h2 className="order-customer-name">{customerName}</h2>
                <div className="order-customer-email">{customerEmail}</div>
              </div>
            </div>

            {/* grid: left info, right status/value/desc */}
            <div className="order-grid">
              {/* LEFT */}
              <div className="order-col">
                <div className="order-section">
                  <div className="order-label">Data zamówienia</div>
                  <div className="order-value order-date">{createdAtLabel}</div>
                </div>

                <div className="order-section">
                  <div className="order-label">Zamawiający</div>
                  <div className="order-kv">
                    <div className="order-value">{customerName}</div>
                    <div className="order-value" style={{ color: "rgba(15,23,42,0.65)", fontWeight: 700 }}>
                      {customerEmail}
                    </div>
                    <div className="order-value" style={{ color: "rgba(15,23,42,0.65)", fontWeight: 700 }}>
                      {customerPhone}
                    </div>
                    {!data.userId && (
                      <div className="order-value" style={{ color: "rgba(15,23,42,0.55)", fontWeight: 800 }}>
                        (bez konta)
                      </div>
                    )}
                  </div>
                </div>

                <div className="order-section">
                  <div className="order-label">Specjalista</div>
                  <div className="order-value">{data.specialistName || "—"}</div>
                </div>
              </div>

              {/* RIGHT */}
              <div className="order-col order-col--right">
                <div className="order-section">
                  <div className="order-label">Status</div>
                  <div className="order-status-wrap">
                    <OrderStatusBadge status={data.status} />
                  </div>
                </div>

                <div className="order-section">
                  <div className="order-label">Wartość zamówienia</div>
                  <div className="order-value" style={{ fontWeight: 900 }}>
                    {typeof data.totalValue === "number" ? `${data.totalValue} PLN` : "—"}
                  </div>
                </div>

                <div className="order-section">
                  <div className="order-label">Opis</div>
                  <div className="order-value">{data.description || "—"}</div>
                </div>
              </div>
            </div>

            <div className="order-back-row">
              <button className="order-back-link" onClick={() => navigate("/orders")} type="button">
                ← Lista zamówień
              </button>
            </div>
          </div>

        </div>
      </div>
    </div>
  );
}

export default SzczegolyZamowienia;
