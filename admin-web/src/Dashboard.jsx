import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import {
  getAdminStats,
  listOrders,
  listUsers,
  listSpecialists,
} from "./api/adminApi";

/** ---------- helpers (daty / etykiety) ---------- */
function pad2(n) {
  return String(n).padStart(2, "0");
}

function toYMDLocal(d) {
  return `${d.getFullYear()}-${pad2(d.getMonth() + 1)}-${pad2(d.getDate())}`;
}

function dayLabelPL(d) {
  const days = ["Nd", "Pn", "Wt", "Śr", "Cz", "Pt", "Sb"];
  return days[d.getDay()];
}

function orderDayKey(o) {
  const value = o?.createdAt || o?.scheduledStart;
  if (!value) return null;

  if (typeof value === "string" && value.length >= 10) {
    return value.slice(0, 10);
  }

  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return null;
  return toYMDLocal(d);
}

function timeAgoPL(value) {
  if (!value) return "—";

  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return "—";

  const diffMs = Date.now() - d.getTime();
  const diffMin = Math.max(0, Math.floor(diffMs / 60000));

  if (diffMin < 60) return `${diffMin} min temu`;

  const diffH = Math.floor(diffMin / 60);
  if (diffH < 24) return `${diffH} godz. temu`;

  const diffD = Math.floor(diffH / 24);
  return `${diffD} dni temu`;
}

/** ---------- small components ---------- */
function StatCard({ title, value, hint, to, className = "" }) {
  const content = (
    <div className={`card card-pad stat-card ${className}`}>
      <div className="card-head">
        <div className="card-title">{title}</div>
      </div>

      <div className="stat-number">{value}</div>
      {hint ? (
        <div className="muted" style={{ marginTop: 6 }}>
          {hint}
        </div>
      ) : null}
    </div>
  );

  return to ? (
    <Link to={to} style={{ textDecoration: "none", color: "inherit" }}>
      {content}
    </Link>
  ) : (
    content
  );
}

/** ---------- chart card ---------- */
function OrdersChart({ series, totalRevenue, newOrders, successRate, loading }) {
  if (loading) {
    return (
      <div className="card card-pad">
        <div className="card-head" style={{ justifyContent: "space-between" }}>
          <div>
            <h2>Przychody</h2>
            <div className="muted" style={{ marginTop: 6 }}>
              Ostatnie 7 dni
            </div>
          </div>
        </div>
        <div className="muted" style={{ padding: "18px 0" }}>
          Ładowanie danych wykresu...
        </div>
      </div>
    );
  }

  if (!series || series.length === 0) {
    return (
      <div className="card card-pad">
        <div className="card-head" style={{ justifyContent: "space-between" }}>
          <div>
            <h2>Przychody</h2>
            <div className="muted" style={{ marginTop: 6 }}>
              Ostatnie 7 dni
            </div>
          </div>
        </div>
        <div className="muted" style={{ padding: "18px 0" }}>
          Brak danych z ostatnich 7 dni.
        </div>
      </div>
    );
  }

  const W = 600;
  const H = 180;
  const P = 16;

  const values = series.map((p) => Number(p.value || 0));
  const max = Math.max(1, ...values);
  const min = Math.min(...values);

  const steps = 4;
const stepValues = [];

for (let i = 0; i <= steps; i++) {
  const value = Math.round((max / steps) * i);
  stepValues.push(value);
}

  const scaleX = (i) =>
    series.length === 1 ? P : P + (i * (W - 2 * P)) / (series.length - 1);

  const scaleY = (v) => {
    if (max === min) return H / 2;
    const t = (v - min) / (max - min);
    return H - P - t * (H - 2 * P);
  };

  const points = series
    .map((p, i) => `${scaleX(i)},${scaleY(Number(p.value || 0))}`)
    .join(" ");

  return (
    <div className="card card-pad">
      <div className="card-head" style={{ justifyContent: "space-between" }}>
        <div>
          <h2>Przychody</h2>
          <div className="muted" style={{ marginTop: 6 }}>
            Ostatnie 7 dni
          </div>
        </div>

        <select className="btn" style={{ height: 40 }} defaultValue="7" disabled>
          <option value="7">Ostatnie 7 dni</option>
        </select>
      </div>

      <div style={{ marginTop: 12 }}>
        <svg
          viewBox={`0 0 ${W} ${H}`}
          width="100%"
          height="180"
          role="img"
          aria-label="Wykres przychodów"
        >
          {stepValues.map((v, i) => {
  const y = scaleY(v);
  return (
    <g key={i}>
      <line
        x1={P}
        x2={W - P}
        y1={y}
        y2={y}
        stroke="currentColor"
        strokeWidth="1"
        opacity="0.1"
      />
      <text
        x={P - 6}
        y={y + 4}
        textAnchor="end"
        fontSize="12"
        opacity="0.5"
      >
        {v} zł
      </text>
    </g>
  );
})}
          <polyline
            fill="none"
            stroke="currentColor"
            strokeWidth="3"
            points={points}
            opacity="0.25"
          />
          <polyline
            fill="none"
            stroke="currentColor"
            strokeWidth="3"
            points={points}
          />

          {series.map((p, i) => (
            <text
              key={p.date + i}
              x={scaleX(i)}
              y={H - 4}
              textAnchor="middle"
              fontSize="12"
              opacity="0.5"
            >
              {p.dateLabel}
            </text>
          ))}
        </svg>
      </div>

      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(3, minmax(0, 1fr))",
          gap: 12,
          marginTop: 6,
        }}
      >
        <div>
          <div className="muted">Łączny przychód</div>
          <div className="stat-number" style={{ fontSize: 22 }}>
            {totalRevenue} PLN
          </div>
        </div>
        <div>
          <div className="muted">Nowe zamówienia</div>
          <div className="stat-number" style={{ fontSize: 22 }}>
            {newOrders}
          </div>
        </div>
        <div>
          <div className="muted">Skuteczność</div>
          <div className="stat-number" style={{ fontSize: 22 }}>
            {successRate}%
          </div>
        </div>
      </div>
    </div>
  );
}

function ActivityList({ items, loading }) {
  if (loading) {
    return (
      <div className="card card-pad">
        <div className="card-head" style={{ justifyContent: "space-between" }}>
          <h2>Ostatnia aktywność</h2>
          <span className="muted">…</span>
        </div>
        <div className="muted" style={{ marginTop: 12 }}>
          Ładowanie aktywności...
        </div>
      </div>
    );
  }

  if (!items || items.length === 0) {
    return (
      <div className="card card-pad">
        <div className="card-head" style={{ justifyContent: "space-between" }}>
          <h2>Ostatnia aktywność</h2>
          <span className="muted">…</span>
        </div>
        <div className="muted" style={{ marginTop: 12 }}>
          Brak aktywności.
        </div>
      </div>
    );
  }

  return (
    <div className="card card-pad">
      <div className="card-head" style={{ justifyContent: "space-between" }}>
        <h2>Ostatnia aktywność</h2>
        <span className="muted">…</span>
      </div>

      <div style={{ display: "grid", gap: 12, marginTop: 8 }}>
        {items.map((x, idx) => (
          <div
            key={`${x.type}-${x.id}-${idx}`}
            style={{
              display: "grid",
              gridTemplateColumns: "42px 1fr auto",
              gap: 12,
              alignItems: "center",
            }}
          >
            <div className="card-ico" style={{ width: 42, height: 42, borderRadius: 999 }}>
              {String(x.name || "?")
                .split(" ")
                .map((p) => p[0])
                .join("")
                .slice(0, 2)
                .toUpperCase()}
            </div>

            <div style={{ minWidth: 0 }}>
              <div style={{ fontWeight: 900 }}>{x.name}</div>
              <div
                className="muted"
                style={{
                  overflow: "hidden",
                  textOverflow: "ellipsis",
                  whiteSpace: "nowrap",
                }}
              >
                {x.subtitle || "—"}
              </div>
              <div className="muted">{x.text}</div>
            </div>

            <div className="muted">{timeAgoPL(x.date)}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

function OrdersTable({ rows, loading }) {
  const badge = (s) => {
    if (s === "pending") return <span className="badge badge-new">Pending</span>;
    if (s === "completed") return <span className="badge badge-done">Zakończone</span>;
    if (s === "cancelled") return <span className="badge badge-progress">Anulowane</span>;
    return <span className="badge badge-progress">{s || "—"}</span>;
  };

  return (
    <div className="card dashboard-table">
      <div className="card-pad" style={{ paddingBottom: 10 }}>
        <div className="card-head">
          <h2>Ostatnie zamówienia</h2>
        </div>
      </div>

      <div style={{ overflowX: "auto" }}>
        <table className="table">
          <thead>
            <tr>
              <th>ID</th>
              <th>Klient</th>
              <th>Usługa</th>
              <th>Data</th>
              <th>Status</th>
            </tr>
          </thead>

          <tbody>
            {loading ? (
              <tr>
                <td colSpan={5} className="muted">
                  Ładowanie...
                </td>
              </tr>
            ) : !rows || rows.length === 0 ? (
              <tr>
                <td colSpan={5} className="muted">
                  Brak zamówień
                </td>
              </tr>
            ) : (
              rows.map((r) => (
                <tr key={r.appointmentId}>
                  <td style={{ fontWeight: 900 }}>#{r.appointmentId}</td>
                  <td>{r.contactName || "—"}</td>
                  <td>{r.serviceName || "—"}</td>
                  <td>
                    {r.scheduledStart
                      ? new Date(r.scheduledStart).toLocaleString("pl-PL")
                      : "—"}
                  </td>
                  <td>{badge(r.status)}</td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      <div className="card-pad muted" style={{ paddingTop: 10 }}>
        {rows?.length ? `Wyświetlanie ${rows.length} ostatnich zamówień` : "Brak danych"}
      </div>
    </div>
  );
}

/** ---------- Dashboard ---------- */
export default function Dashboard() {
  const [stats, setStats] = useState(null);
  const [loadingStats, setLoadingStats] = useState(false);
  const [errorStats, setErrorStats] = useState("");

  const [chart, setChart] = useState({
    series: [],
    totalRevenue: 0,
    newOrders: 0,
    successRate: 0,
  });
  const [loadingChart, setLoadingChart] = useState(false);

  const [activityItems, setActivityItems] = useState([]);
  const [loadingActivity, setLoadingActivity] = useState(false);

  const [recentOrders, setRecentOrders] = useState([]);
  const [loadingRecentOrders, setLoadingRecentOrders] = useState(false);

  useEffect(() => {
    let cancelled = false;

    setLoadingStats(true);
    setErrorStats("");

    getAdminStats()
      .then((res) => {
        if (!cancelled) setStats(res);
      })
      .catch((e) => {
        if (!cancelled) setErrorStats(e?.message || "Błąd pobierania statystyk");
      })
      .finally(() => {
        if (!cancelled) setLoadingStats(false);
      });

    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    let cancelled = false;

    async function loadChart7d() {
      setLoadingChart(true);

      try {
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        const from = new Date(today);
        from.setDate(from.getDate() - 6);

        const createdFrom = toYMDLocal(from);
        const createdTo = toYMDLocal(today);

        const res = await listOrders({
          page: 1,
          pageSize: 5000,
        });

        const allOrders = res?.items ?? [];

        const orders = allOrders.filter((o) => {
          const key = orderDayKey(o);
          if (!key) return false;
          return key >= createdFrom && key <= createdTo;
        });

        const sumByDay = new Map();
        let total = 0;
        let newCount = 0;
        let doneCount = 0;

        for (const o of orders) {
          const v = Number(o.totalPrice ?? 0);
          total += v;

          if (o.status === "pending") newCount += 1;
          if (o.status === "completed") doneCount += 1;

          const key = orderDayKey(o);
          if (!key) continue;

          sumByDay.set(key, (sumByDay.get(key) ?? 0) + v);
        }

        const series = [];
        for (let i = 0; i < 7; i++) {
          const d = new Date(from);
          d.setDate(from.getDate() + i);
          const key = toYMDLocal(d);

          series.push({
            date: key,
            dateLabel: dayLabelPL(d),
            value: Math.round(sumByDay.get(key) ?? 0),
          });
        }

        const successRate = orders.length
          ? Math.round((doneCount / orders.length) * 100)
          : 0;

        if (!cancelled) {
          setChart({
            series,
            totalRevenue: Math.round(total),
            newOrders: newCount,
            successRate,
          });
        }
      } catch (e) {
        console.error("Błąd pobierania danych do wykresu:", e);
        if (!cancelled) {
          setChart({ series: [], totalRevenue: 0, newOrders: 0, successRate: 0 });
        }
      } finally {
        if (!cancelled) setLoadingChart(false);
      }
    }

    loadChart7d();

    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    let cancelled = false;

    async function loadActivity() {
      setLoadingActivity(true);

      try {
        const [usersRes, specialistsRes, ordersRes] = await Promise.all([
          listUsers({ page: 1, pageSize: 5, sort: "CREATED_DESC" }),
          listSpecialists({ page: 1, pageSize: 5, sort: "CREATED_DESC" }),
          listOrders({ page: 1, pageSize: 5 }),
        ]);

        const userItems = (usersRes?.items ?? []).map((u) => ({
          id: u.id,
          type: "user",
          name: `${u.firstName || ""} ${u.lastName || ""}`.trim() || u.email || "Użytkownik",
          subtitle: u.email || "—",
          text: "Zarejestrował się jako klient.",
          date: u.createdAt,
        }));

        const specialistItems = (specialistsRes?.items ?? []).map((s) => ({
          id: s.id,
          type: "specialist",
          name: `${s.firstName || ""} ${s.lastName || ""}`.trim() || s.email || "Specjalista",
          subtitle: s.email || "—",
          text: "Zarejestrował się jako specjalista.",
          date: s.createdAt,
        }));

        const orderItems = (ordersRes?.items ?? []).map((o) => ({
          id: o.appointmentId,
          type: "order",
          name: o.contactName || "Klient",
          subtitle: o.clientAddress || "—",
          text: "Dodał nowe zamówienie.",
          date: o.scheduledStart,
        }));

        const merged = [...userItems, ...specialistItems, ...orderItems]
          .filter((x) => x.date)
          .sort((a, b) => new Date(b.date) - new Date(a.date))
          .slice(0, 5);

        if (!cancelled) setActivityItems(merged);
      } catch (e) {
        console.error("Błąd pobierania aktywności:", e);
        if (!cancelled) setActivityItems([]);
      } finally {
        if (!cancelled) setLoadingActivity(false);
      }
    }

    loadActivity();

    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    let cancelled = false;

    async function loadRecentOrders() {
      setLoadingRecentOrders(true);

      try {
        const res = await listOrders({
          page: 1,
          pageSize: 5,
        });

        if (!cancelled) {
          setRecentOrders(res?.items ?? []);
        }
      } catch (e) {
        console.error("Błąd pobierania ostatnich zamówień:", e);
        if (!cancelled) setRecentOrders([]);
      } finally {
        if (!cancelled) setLoadingRecentOrders(false);
      }
    }

    loadRecentOrders();

    return () => {
      cancelled = true;
    };
  }, []);

  const cards = useMemo(() => {
    if (!stats) return [];

    return [
      {
        title: "Użytkownicy",
        value: stats.totalClients ?? 0,
        hint: "Łączna liczba klientów",
        to: "/users",
      },
      {
        title: "Specjaliści",
        value: stats.totalSpecialists ?? 0,
        hint: `Oczekuje: ${stats.pendingSpecialists ?? 0}`,
        to: "/specialists",
      },
      {
        title: "Zamówienia",
        value: stats.totalAppointments ?? 0,
        hint: "Łączna liczba wizyt w systemie",
        to: "/orders",
      },
    ];
  }, [stats]);

  return (
    <div>
      <h1>Strona główna</h1>

      {loadingStats && <p className="muted">Ładowanie...</p>}
      {errorStats && <p style={{ color: "tomato" }}>{errorStats}</p>}

      <div className="dashboard">
        <div className="dashboard-stats">
          {stats ? cards.map((c) => <StatCard key={c.title} {...c} />) : null}
        </div>

        <div className="dashboard-mid">
          <OrdersChart
            series={chart.series}
            totalRevenue={chart.totalRevenue}
            newOrders={chart.newOrders}
            successRate={chart.successRate}
            loading={loadingChart}
          />
          <ActivityList items={activityItems} loading={loadingActivity} />
        </div>

        <OrdersTable rows={recentOrders} loading={loadingRecentOrders} />
      </div>
    </div>
  );
}