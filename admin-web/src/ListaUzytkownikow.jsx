import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";

import { listUsers } from "./api/adminApi";

const DEFAULT_QUERY = {
  q: "",
  createdFrom: "",
  createdTo: "",
  sort: "CREATED_DESC",
  page: 1,
  pageSize: 20,
};

function formatDate(value) {
  if (!value) return "—";

  const date = new Date(value);

  if (Number.isNaN(date.getTime())) return "—";

  return date.toLocaleDateString();
}

function getFullName(user) {
  return `${user.firstName || ""} ${user.lastName || ""}`.trim() || "—";
}

function ListaUzytkownikow() {
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

    async function loadUsers() {
      setLoading(true);
      setError("");

      try {
        const res = await listUsers(query);

        if (!cancelled) {
          setData(res);
        }
      } catch (e) {
        if (!cancelled) {
          setError(e?.message || "Błąd pobierania listy użytkowników");
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }

    loadUsers();

    return () => {
      cancelled = true;
    };
  }, [query]);

  const page = Number(data.page || query.page || 1);
  const pageSize = Number(data.pageSize || query.pageSize || 20);
  const total = Number(data.total ?? data.totalCount ?? data.items?.length ?? 0);

  const canPrev = page > 1;
  const canNext = page * pageSize < total;

  const resultLabel = useMemo(() => {
    if (loading) return "Ładowanie…";
    if (error) return "Błąd";
    if (total === 0) return "Brak wyników";

    const totalPages = Math.max(1, Math.ceil(total / pageSize));

    return `Strona ${page} z ${totalPages} • Wyświetlono ${data.items.length} wyników`;
  }, [loading, error, data.items.length, page, pageSize, total]);

  return (
    <div className="page">
      <h1>Lista użytkowników</h1>

      <div className="card card-pad">
        <div className="filters-grid users-filters">
          <label className="field field-span-2">
            <span>Szukaj (imię, nazwisko, email)</span>

            <input
              value={query.q}
              onChange={(e) =>
                setQuery((q) => ({
                  ...q,
                  q: e.target.value,
                  page: 1,
                }))
              }
              placeholder="np. Kowalski / test@test.pl"
            />
          </label>

          <label className="field">
            <span>Data rejestracji od</span>

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
            <span>Data rejestracji do</span>

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
              <option value="CREATED_DESC">Najnowsze</option>
              <option value="CREATED_ASC">Najstarsze</option>
            </select>
          </label>

          <div className="filters-actions">
            <button
              className="btn"
              onClick={() => setQuery(DEFAULT_QUERY)}
            >
              Wyczyść
            </button>
          </div>
        </div>
      </div>

      {loading && <p className="muted">Ładowanie...</p>}
      {error && <p className="error">{error}</p>}

      {!loading && !error && (
        <div className="card table-card">
          <div className="table-scroll">
            <table className="table">
              <thead>
                <tr>
                  <th>Imię i nazwisko</th>
                  <th>Email</th>
                  <th>Data rejestracji</th>
                  <th></th>
                </tr>
              </thead>

              <tbody>
                {data.items.length === 0 ? (
                  <tr>
                    <td colSpan={4} className="muted">
                      Brak wyników
                    </td>
                  </tr>
                ) : (
                  data.items.map((user) => (
                    <tr key={user.id}>
                      <td className="cell-strong">{getFullName(user)}</td>
                      <td>{user.email || "—"}</td>
                      <td>{formatDate(user.createdAt)}</td>
                      <td className="cell-right">
                        <Link className="table-link" to={`/users/${user.id}`}>
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
            <span className="muted">{resultLabel}</span>

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

export default ListaUzytkownikow;