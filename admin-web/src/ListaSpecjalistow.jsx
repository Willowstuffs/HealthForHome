import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";

import {
  approveSpecialist,
  listSpecialists,
  rejectSpecialist,
} from "./api/adminApi";

import StatusBadge from "./components/StatusBadge";

const DEFAULT_QUERY = {
  status: "",
  specialization: "",
  createdFrom: "",
  createdTo: "",
  sort: "",
  page: 1,
  pageSize: 20,
};

const SPECIALIZATION_LABELS = {
  physiotherapist: "Fizjoterapeuta",
  fizjoterapia: "Fizjoterapeuta",
  FIZJOTERAPEUTA: "Fizjoterapeuta",

  nurse: "Pielęgniarz",
  pielegniarstwo: "Pielęgniarz",
  pielęgniarstwo: "Pielęgniarz",
  PIELEGNIARKA: "Pielęgniarz",
};

function getSpecializationLabel(specialist) {
  return (
    SPECIALIZATION_LABELS[specialist.professionalTitle] ||
    SPECIALIZATION_LABELS[specialist.specialization] ||
    specialist.professionalTitle ||
    specialist.specialization ||
    "-"
  );
}

function matchesSpecialization(specialist, specialization) {
  if (!specialization) {
    return true;
  }

  const raw = String(
    specialist.professionalTitle ||
      specialist.specialization ||
      ""
  ).toLowerCase();

  if (specialization === "physiotherapist") {
    return raw.includes("physio") || raw.includes("fizjo");
  }

  if (specialization === "nurse") {
    return raw.includes("nurse") || raw.includes("piel");
  }

  return true;
}

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

  async function loadSpecialists() {
    setLoading(true);
    setError("");

    try {
      const res = await listSpecialists(query);
      const payload = res?.data ?? res;

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
  }

  useEffect(() => {
    loadSpecialists();
  }, [query]);

  async function handleApprove(id) {
    try {
      await approveSpecialist(id);

      alert("Specjalista został zaakceptowany");

      await loadSpecialists();
    } catch {
      alert("Nie udało się zaakceptować specjalisty");
    }
  }

  async function handleReject(id) {
    const reason = prompt("Podaj powód odrzucenia");

    if (!reason?.trim()) {
      return;
    }

    try {
      await rejectSpecialist(id, { reason });

      alert("Specjalista został odrzucony");

      await loadSpecialists();
    } catch {
      alert("Nie udało się odrzucić specjalisty");
    }
  }

  const filteredItems = useMemo(() => {
    return data.items.filter((s) =>
      matchesSpecialization(s, query.specialization)
    );
  }, [data.items, query.specialization]);

  const canPrev = query.page > 1;

  const canNext =
    data.page * data.pageSize < data.total;

  const resultLabel = useMemo(() => {
    if (loading) {
      return "Ładowanie…";
    }

    if (error) {
      return "Błąd";
    }

    if (data.total === 0) {
      return "Brak wyników";
    }

    return `Strona ${data.page} z ${Math.max(
      1,
      Math.ceil(data.total / data.pageSize)
    )} • Wyświetlono ${data.items.length} wyników`;
  }, [loading, error, data]);

  return (
    <div className="page">
      <h1>Lista specjalistów</h1>

      <div className="card card-pad">
        <div className="filters-grid">
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
              <option value="PENDING">Oczekuje</option>
              <option value="APPROVED">Zaakceptowany</option>
              <option value="REJECTED">Odrzucony</option>
            </select>
          </label>

          <label className="field">
            <span>Specjalizacja</span>

            <select
              value={query.specialization}
              onChange={(e) =>
                setQuery((q) => ({
                  ...q,
                  specialization: e.target.value,
                  page: 1,
                }))
              }
            >
              <option value="">Wszystkie</option>
              <option value="physiotherapist">
                Fizjoterapeuta
              </option>
              <option value="nurse">
                Pielęgniarz
              </option>
            </select>
          </label>

          <label className="field">
            <span>Data zgłoszenia od</span>

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
            <span>Data zgłoszenia do</span>

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
              <option value="">Domyślne</option>
              <option value="CREATED_ASC">
                Najstarsze
              </option>
              <option value="CREATED_DESC">
                Najnowsze
              </option>
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

      {loading && (
        <p
          className="muted"
          style={{ marginTop: 12 }}
        >
          Ładowanie...
        </p>
      )}

      {error && (
        <p
          className="error"
          style={{ marginTop: 12 }}
        >
          {error}
        </p>
      )}

      {!loading && !error && (
        <div className="card table-card">
          <div className="table-scroll">
            <table className="table">
              <thead>
                <tr>
                  <th>Imię i nazwisko</th>
                  <th>Specjalizacja</th>
                  <th>Email</th>
                  <th>Status</th>
                  <th></th>
                  <th></th>
                </tr>
              </thead>

              <tbody>
                {filteredItems.length === 0 ? (
                  <tr>
                    <td
                      colSpan={6}
                      className="muted"
                    >
                      Brak wyników
                    </td>
                  </tr>
                ) : (
                  filteredItems.map((s) => {
                    const status =
                      s.status ||
                      s.verificationStatus;

                    const isPending =
                      String(status).toUpperCase() ===
                      "PENDING";

                    return (
                      <tr key={s.specialistId}>
                        <td className="cell-strong">
                          {s.firstName} {s.lastName}
                        </td>

                        <td>
                          {getSpecializationLabel(s)}
                        </td>

                        <td>{s.email}</td>

                        <td>
                          <StatusBadge
                            status={status}
                          />
                        </td>

                        <td>
                          {isPending && (
                            <div
                              style={{
                                display: "flex",
                                gap: 8,
                              }}
                            >
                              <button
                                className="btn"
                                onClick={() =>
                                  handleApprove(
                                    s.specialistId
                                  )
                                }
                              >
                                Akceptuj
                              </button>

                              <button
                                className="btn"
                                onClick={() =>
                                  handleReject(
                                    s.specialistId
                                  )
                                }
                              >
                                Odrzuć
                              </button>
                            </div>
                          )}
                        </td>

                        <td className="cell-right">
                          <Link
                            className="table-link"
                            to={`/specialists/${s.specialistId}`}
                          >
                            Szczegóły
                          </Link>
                        </td>
                      </tr>
                    );
                  })
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

export default ListaSpecjalistow;