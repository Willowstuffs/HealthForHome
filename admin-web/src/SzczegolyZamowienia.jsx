import { useEffect, useMemo, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";

import AdminHeader from "./components/AdminHeader";
import OrderStatusBadge from "./components/OrderStatusBadge";

import { getOrder } from "./api/adminApi";

import "./styles/zamowienieSzczegoly.css";

function initialsFromName(fullName) {
  const parts = String(fullName || "")
    .trim()
    .split(/\s+/)
    .filter(Boolean);

  const first = (parts[0] || "")
    .charAt(0)
    .toUpperCase();

  const second = (parts[1] || "")
    .charAt(0)
    .toUpperCase();

  return first + second || "??";
}

function formatDateTimePL(value) {
  if (!value) {
    return "—";
  }

  const date = new Date(value);

  if (Number.isNaN(date.getTime())) {
    return "—";
  }

  return date.toLocaleString("pl-PL", {
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  });
}

function formatPrice(value) {
  return typeof value === "number"
    ? `${value} PLN`
    : "—";
}

function stars(rating) {
  const value = Number(rating || 0);

  return (
    `${"★".repeat(value)}` +
    `${"☆".repeat(Math.max(0, 5 - value))}`
  );
}

function SzczegolyZamowienia() {
  const { id } = useParams();
  const navigate = useNavigate();

  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    let cancelled = false;

    async function loadOrder() {
      setLoading(true);
      setError("");

      try {
        const res = await getOrder(id);

        if (!cancelled) {
          setData(res);
        }
      } catch (e) {
        if (!cancelled) {
          setError(
            e?.message ||
            "Błąd pobierania zamówienia"
          );
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }

    loadOrder();

    return () => {
      cancelled = true;
    };
  }, [id]);

  const createdAtLabel = useMemo(() => {
    return formatDateTimePL(data?.createdAt);
  }, [data?.createdAt]);

  if (loading) {
    return (
      <p style={{ padding: 24 }}>
        Ładowanie...
      </p>
    );
  }

  if (error) {
    return (
      <p
        style={{
          padding: 24,
          color: "tomato",
        }}
      >
        {error}
      </p>
    );
  }

  if (!data) {
    return null;
  }

  const customerName =
    typeof data.contactName === "string" &&
      data.contactName.trim() !== ""
      ? data.contactName
      : "—";

  const customerEmail =
    typeof data.contactEmail === "string" &&
      data.contactEmail.trim() !== ""
      ? data.contactEmail
      : "—";

  const customerPhone =
    typeof data.contactPhoneNumber ===
      "string" &&
      data.contactPhoneNumber.trim() !== ""
      ? data.contactPhoneNumber
      : "—";

  const isCompleted =
    String(data.status).toUpperCase() ===
    "COMPLETED";

  return (
    <div>
      <AdminHeader />

      <div className="admin-container">
        <div className="page order-wrap">
          <div className="order-hero">
            <div>
              <h1 className="order-title">
                Szczegóły zamówienia
              </h1>
            </div>
          </div>

          <div className="order-card">
            <div className="order-header">
              <div className="order-avatar">
                {initialsFromName(customerName)}
              </div>

              <div className="order-header-main">
                <h2 className="order-customer-name">
                  {customerName}
                </h2>

                <div className="order-customer-email">
                  {customerEmail}
                </div>
              </div>
            </div>

            <div className="order-grid">
              <div className="order-col">
                <div className="order-section">
                  <div className="order-label">
                    Data zamówienia
                  </div>

                  <div className="order-value order-date">
                    {createdAtLabel}
                  </div>
                </div>

                <div className="order-section">
                  <div className="order-label">
                    Usługa
                  </div>

                  <div className="order-value">
                    {data.serviceName || "—"}
                  </div>
                </div>

                <div className="order-section">
                  <div className="order-label">
                    Zamawiający
                  </div>

                  <div className="order-kv">
                    <div className="order-value">
                      {customerName}
                    </div>

                    <div
                      className="order-value"
                      style={{
                        color:
                          "rgba(15,23,42,0.65)",
                        fontWeight: 700,
                      }}
                    >
                      {customerEmail}
                    </div>

                    <div
                      className="order-value"
                      style={{
                        color:
                          "rgba(15,23,42,0.65)",
                        fontWeight: 700,
                      }}
                    >
                      {customerPhone}
                    </div>
                  </div>
                </div>

                <div className="order-section">
                  <div className="order-label">
                    Specjalista
                  </div>

                  <div className="order-value">
                    {data.specialistName ||
                      "—"}
                  </div>
                </div>
              </div>

              <div className="order-col order-col--right">
                <div className="order-section">
                  <div className="order-label">
                    Status
                  </div>

                  <div className="order-status-wrap">
                    <OrderStatusBadge
                      status={data.status}
                    />
                  </div>
                </div>

                <div className="order-section">
                  <div className="order-label">
                    Wartość zamówienia
                  </div>

                  <div
                    className="order-value"
                    style={{
                      fontWeight: 900,
                    }}
                  >
                    {formatPrice(
                      data.totalPrice
                    )}
                  </div>
                </div>

                <div className="order-section">
                  <div className="order-label">
                    Opis
                  </div>

                  <div className="order-value">
                    {data.clientNotes ||
                      "—"}
                  </div>
                </div>

                {isCompleted && (
                  <div className="order-section">
                    <div className="order-label">
                      Ocena wizyty
                    </div>
                    {typeof data.rating === "number" ? (
                      <div className="order-kv">
                        <div
                          className="order-value"
                          style={{
                            fontWeight: 900,
                          }}
                        >
                          {stars(data.rating)} {data.rating}/5
                        </div>

                        <div
                          className="order-value"
                          style={{
                            color: "rgba(15,23,42,0.65)",
                            fontWeight: 700,
                          }}
                        >
                          {data.comment || "Brak komentarza"}
                        </div>
                      </div>
                    ) : (
                      <div className="order-value">Brak opinii</div>
                    )}
                  </div>
                )}
              </div>
            </div>

            <div className="order-back-row">
              <button
                className="order-back-link"
                onClick={() =>
                  navigate("/orders")
                }
                type="button"
              >
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