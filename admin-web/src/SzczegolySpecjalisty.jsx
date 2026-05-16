import { useEffect, useMemo, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";

import AdminHeader from "./components/AdminHeader";
import LicenseBadge from "./components/LicenseBadge";
import StatusBadge from "./components/StatusBadge";

import {
  approveSpecialist,
  getAppointmentReview,
  getSpecialist,
  rejectSpecialist,
  suspendSpecialist,
  unsuspendSpecialist,
  updateLicenseValidity,
} from "./api/adminApi";

import "./styles/specjalistaSzczegoly.css";

function computeLicenseStatus(licenseValidUntil) {
  if (!licenseValidUntil) return "UNKNOWN";

  const until = new Date(licenseValidUntil);
  if (Number.isNaN(until.getTime())) return "UNKNOWN";

  const today = new Date();
  today.setHours(0, 0, 0, 0);
  until.setHours(0, 0, 0, 0);

  const diffDays = Math.ceil((until - today) / (1000 * 60 * 60 * 24));

  if (diffDays < 0) return "EXPIRED";
  if (diffDays <= 30) return "EXPIRING_SOON";

  return "ACTIVE";
}

function formatDateInput(value) {
  if (!value) return "";

  const date = new Date(value);

  if (Number.isNaN(date.getTime())) return "";

  return date.toISOString().split("T")[0];
}

function formatDateTimePL(value) {
  if (!value) return "-";

  const date = new Date(value);

  if (Number.isNaN(date.getTime())) return "-";

  return date.toLocaleString("pl-PL", {
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
  });
}

function initials(firstName, lastName) {
  const first = String(firstName || "").trim().charAt(0).toUpperCase();
  const last = String(lastName || "").trim().charAt(0).toUpperCase();

  return first + last || "??";
}

function stars(rating) {
  const value = Number(rating || 0);

  return `${"★".repeat(value)}${"☆".repeat(Math.max(0, 5 - value))}`;
}

function normalizeSpecialization(value) {
  const specialization = String(value || "").toLowerCase();

  if (specialization.includes("nurse") || specialization.includes("piel")) {
    return "nurse";
  }

  if (specialization.includes("physio") || specialization.includes("fizjo")) {
    return "physio";
  }

  return "other";
}

function verifyLinkForSpecialization(spec) {
  if (spec === "PIELEGNIARKA" || spec === "POLOZNA") {
    return {
      href: "https://nipip.pl/weryfikacja-pwz/",
      label: "Weryfikuj PWZ w rejestrze NIPiP",
    };
  }

  if (spec === "FIZJOTERAPEUTA") {
    return {
      href: "https://kif.info.pl/rejestr/",
      label: "Weryfikuj PWZ w rejestrze KIF",
    };
  }

  return null;
}

function getAccountStatus(data) {
  const baseStatus = String(
    data?.status || data?.verificationStatus || "",
  ).toUpperCase();

  const isSuspended =
    data?.isSuspended === true ||
    data?.isActive === false ||
    baseStatus === "SUSPENDED";

  return isSuspended ? "SUSPENDED" : baseStatus;
}

function getClientName(appointment) {
  if (appointment.clientName || appointment.contactName) {
    return appointment.clientName || appointment.contactName;
  }

  const name = `${appointment.client?.firstName ?? ""} ${
    appointment.client?.lastName ?? ""
  }`.trim();

  return name || "Klient";
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

  const [appointmentReviews, setAppointmentReviews] = useState([]);
  const [reviewsLoading, setReviewsLoading] = useState(false);

  useEffect(() => {
    let cancelled = false;

    async function loadSpecialist() {
      setLoading(true);
      setError("");

      try {
        const res = await getSpecialist(id);
        const payload = res?.data ?? res;

        if (!cancelled) {
          setData(payload);
          setLicenseValidUntil(formatDateInput(payload?.licenseValidUntil));
        }
      } catch (e) {
        if (!cancelled) {
          setError(e?.message || "Błąd pobierania danych");
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }

    loadSpecialist();

    return () => {
      cancelled = true;
    };
  }, [id]);

  useEffect(() => {
    if (!data?.appointments?.length) {
      setAppointmentReviews([]);
      return;
    }

    let cancelled = false;

    async function loadReviews() {
      setReviewsLoading(true);

      try {
        const results = await Promise.all(
          data.appointments.map(async (appointment) => {
            try {
              const review = await getAppointmentReview(
                appointment.appointmentId,
              );

              return {
                appointmentId: appointment.appointmentId,
                scheduledStart: appointment.scheduledStart,
                rating: review?.rating,
                comment: review?.comment,
                clientName: getClientName(appointment),
              };
            } catch {
              return null;
            }
          }),
        );

        if (!cancelled) {
          setAppointmentReviews(results.filter(Boolean));
        }
      } finally {
        if (!cancelled) {
          setReviewsLoading(false);
        }
      }
    }

    loadReviews();

    return () => {
      cancelled = true;
    };
  }, [data]);

  const licenseStatus = useMemo(
    () => computeLicenseStatus(data?.licenseValidUntil),
    [data?.licenseValidUntil],
  );

  if (loading) return <p style={{ padding: 24 }}>Ładowanie...</p>;

  if (error) {
    return <p style={{ padding: 24, color: "tomato" }}>{error}</p>;
  }

  if (!data) return null;

  const accountStatus = getAccountStatus(data);

  const canApprove = accountStatus === "PENDING";
  const canReject = accountStatus === "PENDING";

  const specializationRaw = data.specialization || data.professionalTitle;
  const specialization = normalizeSpecialization(specializationRaw);

  const isNurse = specialization === "nurse";
  const isPhysio = specialization === "physio";

  const verify = verifyLinkForSpecialization(data.specialization);

  const specialistActivities = (data.acceptedClients ?? [])
    .map((client) => ({
      date: client.acceptedAt ?? client.createdAt ?? null,
      text: `Zaakceptowano klienta: ${
        [client.firstName, client.lastName].filter(Boolean).join(" ") ||
        client.email ||
        "klient"
      }`,
    }))
    .filter((item) => item.text)
    .slice(0, 10);

  async function refreshSpecialist() {
    const refreshed = await getSpecialist(id);
    const payload = refreshed?.data ?? refreshed;

    setData(payload);
    setLicenseValidUntil(formatDateInput(payload?.licenseValidUntil));
  }

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

      await refreshSpecialist();
    } catch (e) {
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

      await refreshSpecialist();
    } catch {
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

      await refreshSpecialist();
    } catch {
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
              <div className="avatar">
                {initials(data.firstName, data.lastName)}
              </div>

              <div className="profile-main">
                <h2 className="profile-name">
                  {data.firstName} {data.lastName}
                </h2>

                <div>
                  <span className="profile-email">{data.email}</span>

                  <span
                    className={`status-pill status-pill--${String(
                      accountStatus,
                    ).toLowerCase()}`}
                  >
                    <StatusBadge status={accountStatus} />
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

              {accountStatus === "APPROVED" && (
                <button
                  className="btn"
                  onClick={handleSuspend}
                  disabled={actionLoading}
                  type="button"
                >
                  Zawieś
                </button>
              )}

              {accountStatus === "SUSPENDED" && (
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

          <div className="details-grid">
            <div className="card">
              <div className="card-title-row">
                <h3 className="card-title">Dane specjalisty</h3>
              </div>

              <div className="kv">
                <div className="kv-row">
                  <div className="kv-key">Specjalizacja</div>

                  <div className="kv-val">
                    {isNurse
                      ? "Pielęgniarstwo"
                      : isPhysio
                        ? "Fizjoterapia"
                        : specializationRaw || "-"}
                  </div>
                </div>

                {isPhysio && (
                  <>
                    <div className="kv-row">
                      <div className="kv-key">NIP</div>

                      <div className="kv-val">
                        {data.nip || (
                          <span className="empty-field">
                            Nie dodano numeru NIP
                          </span>
                        )}
                      </div>
                    </div>

                    <div className="kv-row">
                      <div className="kv-key">
                        Numer księgi rejestrowej
                      </div>

                      <div className="kv-val">
                        {data.registryBookNumber &&
                        data.registryBookNumber !== "PENDING" ? (
                          data.registryBookNumber
                        ) : data.licenseNumber &&
                          data.licenseNumber !== "PENDING" ? (
                          data.licenseNumber
                        ) : (
                          <span className="empty-field">
                            Nie dodano numeru księgi
                          </span>
                        )}
                      </div>
                    </div>
                  </>
                )}

                {isNurse && (
                  <div className="kv-row">
                    <div className="kv-key">
                      Numer prawa wykonywania zawodu
                    </div>

                    <div className="kv-val">
                      {data.licenseNumber &&
                      data.licenseNumber !== "PENDING" ? (
                        data.licenseNumber
                      ) : (
                        <span className="empty-field">
                          Nie dodano numeru PWZ
                        </span>
                      )}

                      {verify && (
                        <div className="kv-sub">
                          <a
                            className="verify-link"
                            href={verify.href}
                            target="_blank"
                            rel="noreferrer"
                          >
                            {verify.label}
                          </a>
                        </div>
                      )}
                    </div>
                  </div>
                )}
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
                    {licenseStatus !== "UNKNOWN" ? (
                      <LicenseBadge status={licenseStatus} />
                    ) : (
                      <span className="empty-field">Nie ustawiono</span>
                    )}
                  </div>
                </div>

                <div className="license-cell license-cell--right">
                  <div className="license-label">Licencja ważna do</div>

                  <div
                    className="license-value license-date"
                    style={{ marginBottom: 10 }}
                  >
                    {data.licenseValidUntil
                      ? new Date(data.licenseValidUntil).toLocaleDateString()
                      : " "}
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
                    {[data.address, data.city, data.voivodeship]
                      .filter(Boolean)
                      .join(", ") || (
                      <span className="empty-field">
                        Adres nie został uzupełniony
                      </span>
                    )}
                  </div>
                </div>
              </div>
            </div>

            <div className="card activity-card">
              <div className="activity-head">
                <h3 className="card-title">Oceny wizyt specjalisty</h3>
              </div>

              <div className="activity-body">
                {reviewsLoading ? (
                  <div className="activity-empty">Ładowanie ocen...</div>
                ) : appointmentReviews.length > 0 ? (
                  <table className="activity-table">
                    <thead>
                      <tr>
                        <th>Data wizyty</th>
                        <th>Klient</th>
                        <th>Ocena</th>
                        <th>Komentarz</th>
                      </tr>
                    </thead>

                    <tbody>
                      {appointmentReviews.map((review) => (
                        <tr key={review.appointmentId}>
                          <td>
                            {formatDateTimePL(review.scheduledStart)}
                          </td>

                          <td>{review.clientName}</td>

                          <td>
                            {stars(review.rating)} {review.rating}/5
                          </td>

                          <td>{review.comment || "Brak komentarza"}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                ) : (
                  <div className="activity-empty">
                    Brak ocen dla wizyt tego specjalisty.
                  </div>
                )}
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
                    {specialistActivities.length > 0 ? (
                      specialistActivities.map((activity, index) => (
                        <tr key={index}>
                          <td>{formatDateTimePL(activity.date)}</td>
                          <td>{activity.text}</td>
                        </tr>
                      ))
                    ) : (
                      <tr>
                        <td colSpan={2} className="activity-empty">
                          Dane aktywności specjalisty nie są jeszcze dostępne.
                        </td>
                      </tr>
                    )}
                  </tbody>
                </table>

                <div className="back-row">
                  <button
                    className="back-link"
                    onClick={() => navigate("/specialists")}
                    type="button"
                  >
                    ← Lista specjalistów
                  </button>
                </div>
              </div>
            </div>
          </div>

          {showReject && (
            <div className="card reject-box">
              <h3 className="card-title" style={{ marginTop: 0 }}>
                Usuń konto
              </h3>

              <textarea
                placeholder="Podaj powód"
                value={rejectReason}
                onChange={(e) => setRejectReason(e.target.value)}
              />

              <div
                className="details-actions"
                style={{
                  marginTop: 12,
                  justifyContent: "flex-start",
                }}
              >
                <button
                  className="btn btn-primary"
                  disabled={actionLoading}
                  onClick={handleReject}
                  type="button"
                >
                  Potwierdź
                </button>

                <button
                  className="btn"
                  onClick={() => setShowReject(false)}
                  type="button"
                >
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