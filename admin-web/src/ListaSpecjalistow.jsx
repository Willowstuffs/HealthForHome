import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import {
  listSpecialists,
  approveSpecialist,
  rejectSpecialist,
} from "./api/adminApi";
import StatusBadge from "./components/StatusBadge";
import LicenseBadge from "./components/LicenseBadge";
function computeLicenseStatus(licenseStatus, licenseValidUntil) {
  if (!licenseValidUntil) return licenseStatus || "UNKNOWN";

  const until = new Date(licenseValidUntil);
  if (Number.isNaN(until.getTime())) return licenseStatus || "UNKNOWN";

  const today = new Date();
  today.setHours(0, 0, 0, 0);
  until.setHours(0, 0, 0, 0);

  const diffMs = until - today;
  const diffDays = Math.ceil(diffMs / (1000 * 60 * 60 * 24));

  if (diffDays < 0) return "EXPIRED";
  if (diffDays <= 30) return "EXPIRING_SOON";
  return "ACTIVE";
}

const DEFAULT_QUERY = {
  status: "",
  specialization: "",
  createdFrom: "",
  createdTo: "",
  sort: "",
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

  const loadSpecialists = async () => {
    setLoading(true);
    setError("");

    try {
      const res = await listSpecialists(query);
      const payload = res?.data ?? res;

      console.log("SPECIALISTS PAYLOAD:", payload);
      console.log("SPECIALISTS ITEMS:", payload?.items);
      console.log("FIRST SPECIALIST:", payload?.items?.[0]);
      console.log("FIRST SPECIALIST KEYS:", Object.keys(payload?.items?.[0] || {}));

      setData({
        items: payload?.items ?? [],
        total: payload?.totalCount ?? payload?.total ?? 0,
        page: payload?.page ?? query.page,
        pageSize: payload?.pageSize ?? query.pageSize,
      });
    } catch (e) {
      setError(e?.message || "Błąd pobierania listy");
    } finally {
      setLoading(false);
    }
  };
  useEffect(() => {
    loadSpecialists();
  }, [query]);

  const handleApprove = async (id) => {
    try {
      await approveSpecialist(id);
      alert("Specjalista został zaakceptowany");
      await loadSpecialists();
    } catch (e) {
      console.error(e);
      alert("Nie udało się zaakceptować specjalisty");
    }
  };
  const handleReject = async (id) => {
  const reason = prompt("Podaj powód odrzucenia");

      if (!reason || !reason.trim()) {
        return;
      }

      try {
        await rejectSpecialist(id, { reason });
        alert("Specjalista został odrzucony");
        await loadSpecialists();
      } catch (e) {
        console.error(e);
        alert("Nie udało się odrzucić specjalisty");
      }
    };

  const canPrev = query.page > 1;
  const canNext = data.page * data.pageSize < data.total;

  const resultLabel = useMemo(() => {
    if (loading) return "Ładowanie…";
    if (error) return "Błąd";
    if (data.total === 0) return "Brak wyników";
    return `Strona ${data.page} z ${Math.max(1, Math.ceil(data.total / data.pageSize))} • Wyświetlono ${data.items.length} wyników`;
  }, [loading, error, data]);
    const specializationLabels = {
      physiotherapist: "Fizjoterapeuta",
      nurse: "Pielęgniarz",
      doctor: "Lekarz",
      caregiver: "Opiekun medyczny"
    };

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
              <option value="physiotherapist">Fizjoterapeuta</option>
              <option value="nurse">Pielęgniarz</option>
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
              <option value="">Domyślne</option>
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
                    <th>Akcje</th>
                    <th></th>
                  </tr>
                </thead>

                <tbody>
                  {data.items.length === 0 ? (
                    <tr>
                      <td colSpan={8} className="muted">
                        Brak wyników
                      </td>
                    </tr>
                  ) : (
                    data.items.map((s) => (
                      <tr key={s.specialistId}>
                        <td className="cell-strong">
                          {s.firstName} {s.lastName}
                        </td>
                        <td>{specializationLabels[s.professionalTitle] || s.professionalTitle}</td>
                        <td>{s.email}</td>
                        <td>
                          <StatusBadge status={s.status || s.verificationStatus} />
                        </td>
                        <td>{s.city || "-"}</td>
                        <td>
                          <LicenseBadge
                            status={computeLicenseStatus(s.licenseStatus, s.licenseValidUntil)}
                          />
                        </td>


                        <td>
                          {(s.status || s.verificationStatus)?.toUpperCase() === "PENDING" && (
                            <div style={{ display: "flex", gap: "8px" }}>
                              <button className="btn" onClick={() => handleApprove(s.specialistId)}>
                                Akceptuj
                              </button>

                              <button className="btn" onClick={() => handleReject(s.specialistId)}>
                                Odrzuć
                              </button>
                            </div>
                          )}
                        </td>

                        <td className="cell-right">
                          <Link className="table-link" to={`/specialists/${s.specialistId}`}>
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
