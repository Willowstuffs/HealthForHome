import { useEffect, useMemo, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";

import AdminHeader from "./components/AdminHeader";
import { getUser } from "./api/adminApi";

import "./styles/uzytkownikSzczegoly.css";

function initials(firstName, lastName) {
  const first = String(firstName || "")
    .trim()
    .charAt(0)
    .toUpperCase();

  const last = String(lastName || "")
    .trim()
    .charAt(0)
    .toUpperCase();

  return first + last || "??";
}

function translateStatus(status) {
  switch (String(status || "").toLowerCase()) {
    case "open":
      return "Otwarte";

    case "pending":
      return "Oczekujące";

    case "confirmed":
      return "Potwierdzone";

    case "in_progress":
      return "W trakcie";

    case "completed":
      return "Zakończone";

    case "cancelled":
      return "Anulowane";

    case "no_show":
      return "Nieobecność";

    default:
      return status || "-";
  }
}

function formatDateTimePL(value) {
  if (!value) return "-";

  const date = new Date(value);

  if (Number.isNaN(date.getTime())) {
    return "-";
  }

  return date.toLocaleString("pl-PL", {
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
  });
}

function formatPrice(value) {
  return typeof value === "number"
    ? `${value} PLN`
    : "-";
}

function SzczegolyUzytkownika() {
  const { id } = useParams();
  const navigate = useNavigate();

  const [data, setData] = useState(null);

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    let cancelled = false;

    async function loadUser() {
      setLoading(true);
      setError("");

      try {
        const res = await getUser(id);

        if (!cancelled) {
          setData(res);
        }
      } catch (e) {
        if (!cancelled) {
          setError(
            e?.message ||
              "Błąd pobierania danych użytkownika"
          );
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }

    loadUser();

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

  const appointments = Array.isArray(
    data.appointments
  )
    ? data.appointments
    : [];

  const ordersCount = appointments.length;

  const ordersTotalValue = appointments.reduce(
    (sum, item) =>
      sum +
      Number(
        item.price ??
          item.totalPrice ??
          0
      ),
    0
  );

  return (
    <div>
      <AdminHeader />

      <div className="admin-container">
        <div className="page user-details-wrap">
          <div className="user-details-hero">
            <h1 className="user-details-title">
              Szczegóły użytkownika
            </h1>
          </div>

          <div className="user-profile-card">
            <div className="user-profile-left">
              <div className="user-avatar">
                {initials(
                  data.firstName,
                  data.lastName
                )}
              </div>

              <div className="user-profile-main">
                <h2 className="user-name">
                  {data.firstName}{" "}
                  {data.lastName}
                </h2>

                <div className="user-email">
                  {data.email}
                </div>
              </div>
            </div>
          </div>

          <div className="user-details-grid">
            <div className="user-card">
              <h3 className="user-card-title">
                Informacje podstawowe
              </h3>

              <div className="user-kv">
                <div className="user-kv-row">
                  <div className="user-kv-key">
                    ID użytkownika
                  </div>

                  <div className="user-kv-val">
                    {data.clientId ||
                      data.id ||
                      "-"}
                  </div>
                </div>

                <div className="user-kv-row">
                  <div className="user-kv-key">
                    Telefon
                  </div>

                  <div className="user-kv-val">
                    {data.phoneNumber ||
                      data.phone ||
                      "-"}
                  </div>
                </div>

                <div className="user-kv-row">
                  <div className="user-kv-key">
                    Data rejestracji
                  </div>

                  <div className="user-kv-val">
                    {createdAtLabel}
                  </div>
                </div>
              </div>
            </div>

            <div className="user-card user-card--activity">
              <h3 className="user-card-title">
                Aktywność
              </h3>

              <div className="user-kv">
                <div className="user-kv-row">
                  <div className="user-kv-key">
                    Liczba zamówień
                  </div>

                  <div className="user-kv-val">
                    {ordersCount}
                  </div>
                </div>

                <div className="user-kv-row">
                  <div className="user-kv-key">
                    Wartość zamówień
                  </div>

                  <div className="user-kv-val">
                    {ordersTotalValue} PLN
                  </div>
                </div>
              </div>
            </div>

            <div className="user-card user-activity-card">
              <div className="user-activity-head">
                <h3
                  className="user-card-title"
                  style={{ margin: 0 }}
                >
                  Aktywność
                </h3>
              </div>

              <div className="user-activity-body">
                <table className="user-activity-table">
                  <thead>
                    <tr>
                      <th>ID</th>
                      <th>Data</th>
                      <th>Status</th>
                      <th>Wartość</th>
                    </tr>
                  </thead>

                  <tbody>
                    {appointments.length === 0 ? (
                      <tr>
                        <td
                          colSpan={4}
                          className="user-activity-empty"
                        >
                          Użytkownik nie złożył
                          jeszcze żadnego
                          zamówienia.
                        </td>
                      </tr>
                    ) : (
                      appointments.map(
                        (appointment) => (
                          <tr
                            key={
                              appointment.appointmentId
                            }
                          >
                            <td>
                              #
                              {
                                appointment.appointmentId
                              }
                            </td>

                            <td>
                              {formatDateTimePL(
                                appointment.scheduledStart
                              )}
                            </td>

                            <td>
                              {translateStatus(
                                appointment.status
                              )}
                            </td>

                            <td>
                              {formatPrice(
                                appointment.price
                              )}
                            </td>
                          </tr>
                        )
                      )
                    )}
                  </tbody>
                </table>

                <div className="user-back-row">
                  <button
                    className="user-back-link"
                    onClick={() =>
                      navigate("/users")
                    }
                    type="button"
                  >
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