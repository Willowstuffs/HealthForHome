import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import { listSpecialists } from "./api/adminApi";
import StatusBadge from "./components/StatusBadge";
import LicenseBadge from "./components/LicenseBadge";
import { computeLicenseStatus } from "./utils/license";

const DEFAULT_QUERY = {
  status: "",
  specialization: "",
  createdFrom: "",
  createdTo: "",
  sort: "CREATED_ASC",
  page: 1,
  pageSize: 20,
};

function ListaSpecjalistow() {
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

    listSpecialists(query)
      .then((res) => {
        if (!cancelled) setData(res);
      })
      .catch((e) => {
        if (!cancelled) setError(e?.message || "Błąd pobierania listy");
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
    return `Strona ${data.page} z ${Math.max(1, Math.ceil(data.total / data.pageSize))} • Wyświetlono ${data.items.length} wyników`;
  }, [loading, error, data]);

  return (
    <div className="page">
      <h1>Lista specjalistów</h1>

      {/* FILTRY */}
      <div className="card card-pad">
        <div className="filters-grid">
          <label className="field">
            <span>Status</span>
            <select
              value={query.status}
              onChange={(e) => setQuery((q) => ({ ...q, status: e.target.value, page: 1 }))}
            >
              <option value="">Wszystkie</option>
              <option value="PENDING">Oczekuje</option>
              <option value="APPROVED">Zaakceptowany</option>
              <option value="REJECTED">Odrzucony</option>
            </select>
          </label>

          <label className="field">
            <span>Specjalizacja</span>
            <select
              value={query.specialization}
              onChange={(e) => setQuery((q) => ({ ...q, specialization: e.target.value, page: 1 }))}
            >
              <option value="">Wszystkie</option>
              <option value="PIELEGNIARKA">PIELEGNIARKA</option>
              <option value="POLOZNA">POLOZNA</option>
              <option value="FIZJOTERAPEUTA">FIZJOTERAPEUTA</option>
              <option value="REHABILITANT">REHABILITANT</option>
              <option value="INNE">INNE</option>
            </select>
          </label>

          <label className="field">
            <span>Data zgłoszenia od</span>
            <input
              type="date"
              value={query.createdFrom}
              onChange={(e) => setQuery((q) => ({ ...q, createdFrom: e.target.value, page: 1 }))}
            />
          </label>

          <label className="field">
            <span>Data zgłoszenia do</span>
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
              <option value="CREATED_ASC">Najstarsze</option>
              <option value="CREATED_DESC">Najnowsze</option>
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
      {loading && <p className="muted" style={{ marginTop: 12 }}>Ładowanie...</p>}
      {error && <p className="error" style={{ marginTop: 12 }}>{error}</p>}

      {/* TABELA */}
      {!loading && !error && (
        <>
          <div className="card table-card">
            <div className="table-scroll">
              <table className="table">
                <thead>
                  <tr>
                    <th>Imię i nazwisko</th>
                    <th>Specjalizacja</th>
                    <th>Email</th>
                    <th>Status</th>
                    <th>Lokalizacja</th>
                    <th>Licencja</th>
                    <th></th>
                  </tr>
                </thead>

                <tbody>
                  {data.items.length === 0 ? (
                    <tr>
                      <td colSpan={7} className="muted">
                        Brak wyników
                      </td>
                    </tr>
                  ) : (
                    data.items.map((s) => (
                      <tr key={s.id}>
                        <td className="cell-strong">
                          {s.firstName} {s.lastName}
                        </td>
                        <td>{s.specialization}</td>
                        <td>{s.email}</td>
                        <td>
                          <StatusBadge status={s.status} />
                        </td>
                        <td>
                          {s.voivodeship}, {s.city}
                        </td>
                        <td>
                          <LicenseBadge
                            status={computeLicenseStatus(s.licenseStatus, s.licenseValidUntil)}
                          />
                        </td>
                        <td className="cell-right">
                          <Link className="table-link" to={`/specialists/${s.id}`}>
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
        </>
      )}
    </div>
  );
}

export default ListaSpecjalistow;
