import { useEffect, useMemo, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import AdminHeader from "./components/AdminHeader";
import StatusBadge from "./components/StatusBadge";
import LicenseBadge from "./components/LicenseBadge";

import {
  getSpecialist,
  approveSpecialist,
  rejectSpecialist,
  updateLicenseValidity,
  suspendSpecialist,
  unsuspendSpecialist,
} from "./api/adminApi";
import "./styles/specjalistaSzczegoly.css";

function computeLicenseStatus(licenseStatus, licenseValidUntil) {
  if (!licenseValidUntil) return "UNKNOWN";

  const until = new Date(licenseValidUntil);
  if (Number.isNaN(until.getTime())) return "UNKNOWN";

  const today = new Date();
  today.setHours(0, 0, 0, 0);
  until.setHours(0, 0, 0, 0);

  const diffMs = until - today;
  const diffDays = Math.ceil(diffMs / (1000 * 60 * 60 * 24));

  if (diffDays < 0) return "EXPIRED";
  if (diffDays <= 30) return "EXPIRING_SOON";
  return "ACTIVE";
}

function initials(firstName, lastName) {
  const a = (firstName || "").trim().charAt(0).toUpperCase();
  const b = (lastName || "").trim().charAt(0).toUpperCase();
  return (a + b) || "??";
}

function verifyLinkForSpecialization(spec) {
  if (spec === "PIELEGNIARKA" || spec === "POLOZNA") {
    return { href: "https://nipip.pl/weryfikacja-pwz/", label: "Weryfikuj PWZ w rejestrze NIPiP" };
  }
  if (spec === "FIZJOTERAPEUTA") {
    return { href: "https://kif.info.pl/rejestr/", label: "Weryfikuj PWZ w rejestrze KIF" };
  }
  return null;
}

function SzczegolySpecjalisty() {
  const { id } = useParams();
  const navigate = useNavigate();

  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const [actionLoading, setActionLoading] = useState(false);
  const [rejectReason, setRejectReason] = useState("");
  const [showReject, setShowReject] = useState(false);
  const [licenseValidUntil, setLicenseValidUntil] = useState("");

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setError("");

    getSpecialist(id)
      .then((res) => {
        const payload = res?.data ?? res;
        if (!cancelled) setData(payload);
        if (!cancelled) {
          setData(payload);
          setLicenseValidUntil(
            payload?.licenseValidUntil
              ? new Date(payload.licenseValidUntil).toISOString().split("T")[0]
              : ""
          );
        }
      })
      
      .catch((e) => {
        if (!cancelled) setError(e?.message || "Błąd pobierania danych");
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });

    return () => {
      cancelled = true;
    };
  }, [id]);

  const licenseStatus = useMemo(() => {
    if (!data) return "UNKNOWN";
    return computeLicenseStatus(data.licenseStatus, data.licenseValidUntil);
  }, [data]);

  if (loading) return <p style={{ padding: 24 }}>Ładowanie...</p>;
  if (error) return <p style={{ padding: 24, color: "tomato" }}>{error}</p>;
  if (!data) return null;

  const accountStatus = data.status || data.verificationStatus;
  const canApprove = accountStatus === "PENDING";
  const canReject = accountStatus === "PENDING";

  const verify = verifyLinkForSpecialization(data.specialization);

  async function handleApprove() {
    if (!canApprove) return;
    if (!window.confirm("Czy na pewno zaakceptować specjalistę?")) return;

    try {
      setActionLoading(true);
      await approveSpecialist(id);
      alert("Konto zaakceptowane");
      navigate("/specialists");
    } catch (e) {
      alert(e?.message || "Błąd akceptacji");
    } finally {
      setActionLoading(false);
    }
  }

  async function handleReject() {
    if (!canReject) return;
    if (!rejectReason.trim()) {
      alert("Podaj powód odrzucenia");
      return;
    }

    try {
      setActionLoading(true);
      await rejectSpecialist(id, { reason: rejectReason });
      alert("Konto odrzucone");
      navigate("/specialists");
    } catch (e) {
      alert(e?.message || "Błąd odrzucenia");
    } finally {
      setActionLoading(false);
    }
  }
  async function handleSaveLicenseValidity() {
    try {
      setActionLoading(true);
      await updateLicenseValidity(id, {
        licenseValidUntil: licenseValidUntil || null,
      });
      alert("Data ważności licencji została zapisana");

      const refreshed = await getSpecialist(id);
      const payload = refreshed?.data ?? refreshed;
      setData(payload);
      setLicenseValidUntil(
        payload?.licenseValidUntil
          ? new Date(payload.licenseValidUntil).toISOString().split("T")[0]
          : ""
      );
    } catch (e) {
      console.error(e);
      alert(e?.message || "Błąd zapisu daty licencji");
    } finally {
      setActionLoading(false);
    }
  }
async function handleSuspend() {
  if (!window.confirm("Czy zawiesić specjalistę?")) return;

  try {
    setActionLoading(true);
    await suspendSpecialist(id);
    alert("Specjalista został zawieszony");
    location.reload();
  } catch (e) {
    alert("Błąd zawieszania");
  } finally {
    setActionLoading(false);
  }
}

async function handleUnsuspend() {
  if (!window.confirm("Czy przywrócić specjalistę?")) return;

  try {
    setActionLoading(true);
    await unsuspendSpecialist(id);
    alert("Specjalista został odwieszony");
    location.reload();
  } catch (e) {
    alert("Błąd przywracania");
  } finally {
    setActionLoading(false);
  }
}

  return (
    <div>
      <AdminHeader />

      <div className="admin-container">
        <div className="page details-wrap">
          <div className="details-hero">
              <h1 className="details-title">Szczegóły specjalisty</h1>
            </div>

            <div className="card profile-card">
              <div className="profile-left">
                <div className="avatar">{initials(data.firstName, data.lastName)}</div>

                <div className="profile-main">
                  <h2 className="profile-name">
                    {data.firstName} {data.lastName}
                  </h2>

                  <div>
                    <span className="profile-email">{data.email}</span>
                    <span className={`status-pill status-pill--${String(data.status || data.verificationStatus).toLowerCase()}`}>
                      <StatusBadge status={data.status || data.verificationStatus} />
                    </span>

                  </div>

                </div>
              </div>

              <div className="details-actions">
        {accountStatus === "PENDING" && (
          <>
            <button
              className="btn btn-primary"
              disabled={actionLoading || !canApprove}
              onClick={handleApprove}
              type="button"
            >
              ✓ Zaakceptuj
            </button>

            <button
              className="btn btn-danger"
              disabled={actionLoading || !canReject}
              onClick={() => {
                setRejectReason("");
                setShowReject(true);
              }}
              type="button"
            >
              Odrzuć
            </button>
          </>
        )}

        {data?.isActive ? (
          <button
            className="btn"
            onClick={handleSuspend}
            disabled={actionLoading}
            type="button"
          >
            Zawieś
          </button>
        ) : (
          <button
            className="btn"
            onClick={handleUnsuspend}
            disabled={actionLoading}
            type="button"
          >
            Odwieś
          </button>
        )}
      </div>
      </div>

          {/* Cards grid */}
          <div className="details-grid">
            <div className="card">
              <div className="card-title-row">
                <h3 className="card-title">Dane specjalisty</h3>
              </div>

              <div className="kv">
                <div className="kv-row">
                  <div className="kv-key">Specjalizacja</div>
                  <div className="kv-val">{data.specialization || data.professionalTitle || "-"}</div>
                </div>

                <div className="kv-row">
                  <div className="kv-key">NIP</div>
                  <div className="kv-val">{data.nip}</div>
                </div>

                <div className="kv-row">
                  <div className="kv-key">Numer księgi rejestrowej</div>
                  <div className="kv-val">{data.registryBookNumber}</div>
                </div>

                <div className="kv-row">
                  <div className="kv-key">Numer prawa wykonywania</div>
                  <div className="kv-val">
                    {data.licenseNumber}
                    {verify && (
                      <div className="kv-sub">
                        <a className="verify-link" href={verify.href} target="_blank" rel="noreferrer">
                          {verify.label}
                        </a>
                      </div>
                    )}
                  </div>
                </div>
              </div>
            </div>

            <div className="card">
              <div className="card-title-row">
                <h3 className="card-title">Licencja</h3>
              </div>

              <div className="license-grid">
                <div className="license-cell">
                  <div className="license-label">Status licencji</div>
                  <div className="license-value">
                    <LicenseBadge status={licenseStatus} />
                  </div>
                </div>

                <div className="license-cell license-cell--right">
                  <div className="license-label">Licencja ważna do</div>

                  <div className="license-value license-date" style={{ marginBottom: 8 }}>
                    {data.licenseValidUntil
                      ? new Date(data.licenseValidUntil).toLocaleDateString()
                      : "brak danych"}
                  </div>

                  <div>
                    <input
                      type="date"
                      value={licenseValidUntil}
                      onChange={(e) => setLicenseValidUntil(e.target.value)}
                    />
                    <button
                      className="btn"
                      type="button"
                      onClick={handleSaveLicenseValidity}
                      disabled={actionLoading}
                      style={{ marginLeft: 8 }}
                    >
                      Zapisz
                    </button>
                  </div>
                </div>

                <div className="license-address">
                  <div className="license-label">Adres:</div>
                  <div className="license-address-value">
                    {data.address}, {data.city}, {data.voivodeship}
                  </div>
                </div>
              </div>

            </div>

            
            <div className="card activity-card">
              <div className="activity-head">
                <h3 className="card-title">Ostatnia aktywność</h3>
              </div>

              <div className="activity-body">
                <table className="activity-table">
                  <thead>
                    <tr>
                      <th>Data</th>
                      <th>Aktywność</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td colSpan={2} className="activity-empty">
                        Użytkownik nie wykonał jeszcze żadnej aktywności w systemie.
                      </td>
                    </tr>
                  </tbody>
                </table>

                <div className="back-row">
                  <button className="back-link" onClick={() => navigate("/specialists")} type="button">
                    ← Lista specjalistów
                  </button>
                </div>
              </div>
            </div>
          </div>

  
          {showReject && (
            <div className="card reject-box">
              <h3 className="card-title" style={{ marginTop: 0 }}>Usuń konto</h3>

              <textarea
                placeholder="Podaj powód"
                value={rejectReason}
                onChange={(e) => setRejectReason(e.target.value)}
              />

              <div className="details-actions" style={{ marginTop: 12, justifyContent: "flex-start" }}>
                <button className="btn btn-primary" disabled={actionLoading} onClick={handleReject} type="button">
                  Potwierdź
                </button>

                <button className="btn" onClick={() => setShowReject(false)} type="button">
                  Anuluj
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

export default SzczegolySpecjalisty;
