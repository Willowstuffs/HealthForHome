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

    setLoading(true);
    setError("");

    listUsers(query)
      .then((res) => {
        if (!cancelled) setData(res);
      })
      .catch((e) => {
        if (!cancelled) setError(e?.message || "Błąd pobierania listy użytkowników");
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });

    return () => {
      cancelled = true;
    };
  }, [query]);

  const canPrev = query.page > 1;
  const canNext = data.page * data.pageSize < data.total;

  const resultLabel = useMemo(() => {
    if (loading) return "Ładowanie…";
    if (error) return "Błąd";
    if (data.total === 0) return "Brak wyników";
    const totalPages = Math.max(1, Math.ceil(data.total / data.pageSize));
    return `Strona ${data.page} z ${totalPages} • Wyświetlono ${data.items.length} wyników`;
  }, [loading, error, data]);

  return (
    <div className="page">
      <h1>Lista użytkowników</h1>

      {/* FILTRY */}
      <div className="card card-pad">
        <div className="filters-grid users-filters">
          <label className="field field-span-2">
            <span>Szukaj (imię, nazwisko, email)</span>
            <input
              value={query.q}
              onChange={(e) => setQuery((q) => ({ ...q, q: e.target.value, page: 1 }))}
              placeholder="np. Kowalski / test@test.pl"
            />
          </label>

          <label className="field">
            <span>Data rejestracji od</span>
            <input
              type="date"
              value={query.createdFrom}
              onChange={(e) => setQuery((q) => ({ ...q, createdFrom: e.target.value, page: 1 }))}
            />
          </label>

          <label className="field">
            <span>Data rejestracji do</span>
            <input
              type="date"
              value={query.createdTo}
              onChange={(e) => setQuery((q) => ({ ...q, createdTo: e.target.value, page: 1 }))}
            />
          </label>

          <label className="field">
            <span>Sortowanie</span>
            <select
              value={query.sort}
              onChange={(e) => setQuery((q) => ({ ...q, sort: e.target.value, page: 1 }))}
            >
              <option value="CREATED_DESC">Najnowsze</option>
              <option value="CREATED_ASC">Najstarsze</option>
            </select>
          </label>

          <div className="filters-actions">
            <button className="btn" onClick={() => setQuery(DEFAULT_QUERY)}>
              Wyczyść
            </button>
          </div>
        </div>
      </div>

      {/* STANY */}
      {loading && <p className="muted">Ładowanie...</p>}
      {error && <p className="error">{error}</p>}

      {/* TABELA */}
      {!loading && !error && (
        <div className="card table-card">
          <div className="table-scroll">
            <table className="table">
              <thead>
                <tr>
                  <th>Imię i nazwisko</th>
                  <th>Email</th>
                  <th>Telefon</th>
                  <th>Data rejestracji</th>
                  <th></th>
                </tr>
              </thead>

              <tbody>
                {data.items.length === 0 ? (
                  <tr>
                    <td colSpan={5} className="muted">
                      Brak wyników
                    </td>
                  </tr>
                ) : (
                  data.items.map((u) => (
                    <tr key={u.id}>
                      <td className="cell-strong">
                        {`${u.firstName || ""} ${u.lastName || ""}`.trim() || "—"}
                      </td>
                      <td>{u.email || "—"}</td>
                      <td>{u.phoneNumber || u.phone || "—"}</td>
                      <td>{u.createdAt ? new Date(u.createdAt).toLocaleDateString() : "—"}</td>
                      <td className="cell-right">
                        <Link className="table-link" to={`/users/${u.id}`}>
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
                onClick={() => setQuery((q) => ({ ...q, page: q.page - 1 }))}
              >
                ← Poprzednia
              </button>

              <button
                className="btn"
                disabled={!canNext}
                onClick={() => setQuery((q) => ({ ...q, page: q.page + 1 }))}
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
