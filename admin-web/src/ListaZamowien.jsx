import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";

import { listOrders } from "./api/adminApi";

import OrderStatusBadge from "./components/OrderStatusBadge";

const DEFAULT_QUERY = {
  status: "",
  createdFrom: "",
  createdTo: "",
  sort: "CREATED_DESC",
  page: 1,
  pageSize: 20,
};

function formatDateTimePL(value) {
  if (!value) return "—";

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
  });
}

function formatPrice(value) {
  return typeof value === "number"
    ? `${value} PLN`
    : "—";
}

function ListaZamowien() {
  const [query, setQuery] = useState(DEFAULT_QUERY);

  const [data, setData] = useState({
    items: [],
    total: 0,
    page: 1,
    pageSize: 20,
  });

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    let cancelled = false;

    async function loadOrders() {
      setLoading(true);
      setError("");

      try {
        const res = await listOrders(query);

        if (!cancelled) {
          setData(res);
        }
      } catch (e) {
        if (!cancelled) {
          setError(
            e?.message ||
              "Błąd pobierania listy zamówień"
          );
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }

    loadOrders();

    return () => {
      cancelled = true;
    };
  }, [query]);

  const canPrev = query.page > 1;

  const canNext =
    data.page * data.pageSize < data.total;

  const resultLabel = useMemo(() => {
    if (loading) return "Ładowanie…";
    if (error) return "Błąd";
    if (data.total === 0) return "Brak wyników";

    const totalPages = Math.max(
      1,
      Math.ceil(data.total / data.pageSize)
    );

    return `Strona ${data.page} z ${totalPages} • Wyświetlono ${data.items.length} wyników`;
  }, [loading, error, data]);

  return (
    <div className="page">
      <h1>Lista zamówień</h1>

      <div className="card card-pad">
        <div className="filters-grid orders-filters">
          <label className="field">
            <span>Status</span>

            <select
              value={query.status}
              onChange={(e) =>
                setQuery((q) => ({
                  ...q,
                  status: e.target.value,
                  page: 1,
                }))
              }
            >
              <option value="">Wszystkie</option>
              <option value="pending">
                Oczekujące
              </option>
              <option value="confirmed">
                Potwierdzone
              </option>
              <option value="open">
                Otwarte
              </option>
              <option value="cancelled">
                Anulowane
              </option>
              <option value="completed">
                Zakończone
              </option>
            </select>
          </label>

          <label className="field">
            <span>Data od</span>

            <input
              type="date"
              value={query.createdFrom}
              onChange={(e) =>
                setQuery((q) => ({
                  ...q,
                  createdFrom: e.target.value,
                  page: 1,
                }))
              }
            />
          </label>

          <label className="field">
            <span>Data do</span>

            <input
              type="date"
              value={query.createdTo}
              onChange={(e) =>
                setQuery((q) => ({
                  ...q,
                  createdTo: e.target.value,
                  page: 1,
                }))
              }
            />
          </label>

          <label className="field">
            <span>Sortowanie</span>

            <select
              value={query.sort}
              onChange={(e) =>
                setQuery((q) => ({
                  ...q,
                  sort: e.target.value,
                  page: 1,
                }))
              }
            >
              <option value="CREATED_DESC">
                Najnowsze
              </option>

              <option value="CREATED_ASC">
                Najstarsze
              </option>
            </select>
          </label>

          <div className="filters-actions">
            <button
              className="btn"
              onClick={() =>
                setQuery(DEFAULT_QUERY)
              }
            >
              Wyczyść
            </button>
          </div>
        </div>
      </div>

      {loading && (
        <p className="muted">
          Ładowanie...
        </p>
      )}

      {error && (
        <p className="error">
          {error}
        </p>
      )}

      {!loading && !error && (
        <div className="card table-card">
          <div className="table-scroll">
            <table className="table">
              <thead>
                <tr>
                  <th>ID</th>
                  <th>Zamawiający</th>
                  <th>Adres</th>
                  <th>Specjalista</th>
                  <th>Wartość</th>
                  <th>Status</th>
                  <th>Data wizyty</th>
                  <th></th>
                </tr>
              </thead>

              <tbody>
                {data.items.length === 0 ? (
                  <tr>
                    <td
                      colSpan={8}
                      className="muted"
                    >
                      Brak wyników
                    </td>
                  </tr>
                ) : (
                  data.items.map((order) => (
                    <tr
                      key={order.appointmentId}
                    >
                      <td className="mono cell-strong">
                        #{order.appointmentId}
                      </td>

                      <td>
                        <div className="cell-strong">
                          {order.contactName ||
                            "—"}
                        </div>
                      </td>

                      <td>
                        {order.clientAddress ||
                          "—"}
                      </td>

                      <td>
                        {order.serviceName ||
                          "—"}
                      </td>

                      <td className="cell-strong">
                        {formatPrice(
                          order.totalPrice
                        )}
                      </td>

                      <td>
                        <OrderStatusBadge
                          status={order.status}
                        />
                      </td>

                      <td>
                        {formatDateTimePL(
                          order.scheduledStart
                        )}
                      </td>

                      <td className="cell-right">
                        <Link
                          className="table-link"
                          to={`/orders/${
                            order.appointmentId ||
                            order.id
                          }`}
                        >
                          Szczegóły
                        </Link>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>

          <div className="table-footer">
            <span className="muted">
              {resultLabel}
            </span>

            <div className="pager">
              <button
                className="btn"
                disabled={!canPrev}
                onClick={() =>
                  setQuery((q) => ({
                    ...q,
                    page: q.page - 1,
                  }))
                }
              >
                ← Poprzednia
              </button>

              <button
                className="btn"
                disabled={!canNext}
                onClick={() =>
                  setQuery((q) => ({
                    ...q,
                    page: q.page + 1,
                  }))
                }
              >
                Następna →
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default ListaZamowien;