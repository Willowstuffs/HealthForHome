import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";

import {
  getAdminStats,
  listOrders,
} from "./api/adminApi";

import OrderStatusBadge from "./components/OrderStatusBadge";

function pad2(n) {
  return String(n).padStart(2, "0");
}

function toYMDLocal(d) {
  return `${d.getFullYear()}-${pad2(d.getMonth() + 1)}-${pad2(d.getDate())}`;
}

function dayLabelPL(d) {
  return ["Nd", "Pn", "Wt", "Śr", "Cz", "Pt", "Sb"][d.getDay()];
}

function formatDateTimePL(value) {
  if (!value) return "—";

  const d = new Date(value);

  if (Number.isNaN(d.getTime())) {
    return "—";
  }

  return d.toLocaleString("pl-PL", {
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
  });
}

function orderDayKey(order) {
  const value = order?.createdAt || order?.scheduledStart;

  if (!value) {
    return null;
  }

  if (typeof value === "string" && value.length >= 10) {
    return value.slice(0, 10);
  }

  const d = new Date(value);

  if (Number.isNaN(d.getTime())) {
    return null;
  }

  return toYMDLocal(d);
}

function timeAgoPL(value) {
  if (!value) return "—";

  const d = new Date(value);

  if (Number.isNaN(d.getTime())) {
    return "—";
  }

  const diffMs = Date.now() - d.getTime();

  if (diffMs < 0) {
    return "zaplanowano";
  }

  const diffMin = Math.floor(diffMs / 60000);

  if (diffMin < 1) return "przed chwilą";
  if (diffMin < 60) return `${diffMin} min temu`;

  const diffH = Math.floor(diffMin / 60);

  if (diffH < 24) {
    return `${diffH} godz. temu`;
  }

  return `${Math.floor(diffH / 24)} dni temu`;
}

function StatCard({ title, value, hint, to }) {
  const content = (
    <div className="card card-pad stat-card">
      <div className="card-head">
        <div className="card-title">{title}</div>
      </div>

      <div className="stat-number">{value}</div>

      {hint && (
        <div className="muted" style={{ marginTop: 6 }}>
          {hint}
        </div>
      )}
    </div>
  );

  if (!to) {
    return content;
  }

  return (
    <Link
      to={to}
      style={{
        textDecoration: "none",
        color: "inherit",
      }}
    >
      {content}
    </Link>
  );
}

function OrdersChart({
  series,
  totalRevenue,
  newOrders,
  successRate,
  loading,
}) {
  if (loading) {
    return (
      <div className="card card-pad">
        <h2>Wartość realizowanych usług</h2>

        <div className="muted" style={{ marginTop: 12 }}>
          Ładowanie danych...
        </div>
      </div>
    );
  }

  if (!series.length) {
    return (
      <div className="card card-pad">
        <h2>Wartość realizowanych usług</h2>

        <div className="muted" style={{ marginTop: 12 }}>
          Brak danych
        </div>
      </div>
    );
  }

  const W = 600;
  const H = 180;
  const P = 16;

  const values = series.map((x) => Number(x.value || 0));

  const max = Math.max(1, ...values);
  const min = Math.min(...values);

  const scaleX = (i) =>
    series.length === 1
      ? P
      : P + (i * (W - 2 * P)) / (series.length - 1);

  const scaleY = (v) => {
    if (max === min) {
      return H / 2;
    }

    const t = (v - min) / (max - min);

    return H - P - t * (H - 2 * P);
  };

  const points = series
    .map((p, i) => `${scaleX(i)},${scaleY(Number(p.value || 0))}`)
    .join(" ");

  return (
    <div className="card card-pad">
      <div className="card-head">
        <div>
          <h2>Wartość realizowanych usług</h2>

          <div className="muted" style={{ marginTop: 6 }}>
            Ostatnie 7 dni
          </div>
        </div>
      </div>

      <svg
        viewBox={`0 0 ${W} ${H}`}
        width="100%"
        height="180"
      >
        <polyline
          fill="none"
          stroke="currentColor"
          strokeWidth="3"
          points={points}
        />

        {series.map((p, i) => (
          <text
            key={p.date}
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

      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(3, minmax(0, 1fr))",
          gap: 12,
          marginTop: 12,
        }}
      >
        <div>
          <div className="muted">Łączna wartość zrealizowanych usług</div>

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
        <h2>Najbliższe wizyty</h2>

        <div className="muted" style={{ marginTop: 12 }}>
          Ładowanie...
        </div>
      </div>
    );
  }

  if (!items.length) {
    return (
      <div className="card card-pad">
        <h2>Najbliższe wizyty</h2>

        <div className="muted" style={{ marginTop: 12 }}>
          Brak wizyt
        </div>
      </div>
    );
  }

  return (
    <div className="card card-pad">
      <h2>Najbliższe wizyty</h2>

      <div
        style={{
          display: "grid",
          gap: 12,
          marginTop: 12,
        }}
      >
        {items.map((x) => (
          <div
            key={`${x.type}-${x.id}`}
            style={{
              display: "grid",
              gridTemplateColumns: "42px 1fr auto",
              gap: 12,
              alignItems: "center",
            }}
          >
            <div
              className="card-ico"
              style={{
                width: 42,
                height: 42,
                borderRadius: 999,
              }}
            >
              {String(x.name || "?")
                .split(" ")
                .map((p) => p[0])
                .join("")
                .slice(0, 2)
                .toUpperCase()}
            </div>

            <div>
              <div style={{ fontWeight: 900 }}>
                {x.name}
              </div>

              <div className="muted">
                {x.subtitle || "—"}
              </div>

              <div className="muted">
                {x.text}
              </div>
            </div>

            <div className="muted">
              {x.createdAt ? timeAgoPL(x.createdAt) : ""}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

function OrdersTable({ rows, loading }) {
  return (
    <div className="card dashboard-table">
      <div className="card-pad">
        <h2>Ostatnie zamówienia</h2>
      </div>

      <div style={{ overflowX: "auto" }}>
        <table className="table">
          <thead>
            <tr>
              <th>ID</th>
              <th>Klient</th>
              <th>Usługa</th>
              <th>Data wizyty</th>
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
            ) : !rows.length ? (
              <tr>
                <td colSpan={5} className="muted">
                  Brak zamówień
                </td>
              </tr>
            ) : (
              rows.map((r) => (
                <tr key={r.appointmentId}>
                  <td style={{ fontWeight: 900 }}>
                    #{r.appointmentId}
                  </td>

                  <td>{r.contactName || "—"}</td>

                  <td>{r.serviceName || "—"}</td>

                  <td>
                    {r.scheduledStart
                      ? formatDateTimePL(r.scheduledStart)
                      : "—"}
                  </td>

                  <td>
                    <OrderStatusBadge status={r.status} />
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      <div className="card-pad muted">
        {rows.length
          ? `Wyświetlanie ${rows.length} ostatnich zamówień`
          : "Brak danych"}
      </div>
    </div>
  );
}

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
  const [loadingRecentOrders, setLoadingRecentOrders] =
    useState(false);

  useEffect(() => {
    let cancelled = false;

    async function loadStats() {
      setLoadingStats(true);
      setErrorStats("");

      try {
        const res = await getAdminStats();

        if (!cancelled) {
          setStats(res);
        }
      } catch (e) {
        if (!cancelled) {
          setErrorStats(
            e?.message || "Błąd pobierania statystyk"
          );
        }
      } finally {
        if (!cancelled) {
          setLoadingStats(false);
        }
      }
    }

    loadStats();

    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    let cancelled = false;

    async function loadChart() {
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

        const orders = (res?.items ?? []).filter((o) => {
          const key = orderDayKey(o);

          return key && key >= createdFrom && key <= createdTo;
        });

        const sumByDay = new Map();

        let totalRevenue = 0;
        let newOrders = 0;

        for (const order of orders) {
          const status = String(order.status || "").toLowerCase();

          if (status === "pending") {
            newOrders += 1;
          }

          if (status !== "completed") {
            continue;
          }

          const value = Number(order.totalPrice ?? 0);

          totalRevenue += value;

          const key = orderDayKey(order);

          if (!key) {
            continue;
          }

          sumByDay.set(
            key,
            (sumByDay.get(key) ?? 0) + value
          );
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

        const finishedOrders = orders.filter((o) =>
          ["completed", "cancelled", "no_show"].includes(
            String(o.status).toLowerCase()
          )
        );

        const completedOrders = finishedOrders.filter(
          (o) =>
            String(o.status).toLowerCase() === "completed"
        );

        const successRate = finishedOrders.length
          ? Math.round(
              (completedOrders.length /
                finishedOrders.length) *
                100
            )
          : 0;

        if (!cancelled) {
          setChart({
            series,
            totalRevenue: Math.round(totalRevenue),
            newOrders,
            successRate,
          });
        }
      } finally {
        if (!cancelled) {
          setLoadingChart(false);
        }
      }
    }

    loadChart();

    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    let cancelled = false;

    async function loadActivity() {
      setLoadingActivity(true);

      try {
        const res = await listOrders({
          page: 1,
          pageSize: 10,
        });

        const items = (res?.items ?? [])
  .map((o) => ({
    id: o.appointmentId,
    type: "order",

    name: o.contactName || "Klient",

    subtitle: o.serviceName || "—",

    text: `Termin wizyty: ${
      o.scheduledStart
        ? formatDateTimePL(o.scheduledStart)
        : "—"
    }`,

    date: o.scheduledStart || o.createdAt,

    createdAt: o.scheduledStart || o.createdAt,
  }))
          .filter((x) => x.date)
          .sort(
            (a, b) =>
              new Date(b.date) - new Date(a.date)
          )
          .slice(0, 5);

        if (!cancelled) {
          setActivityItems(items);
        }
      } finally {
        if (!cancelled) {
          setLoadingActivity(false);
        }
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
      } finally {
        if (!cancelled) {
          setLoadingRecentOrders(false);
        }
      }
    }

    loadRecentOrders();

    return () => {
      cancelled = true;
    };
  }, []);

  const cards = useMemo(() => {
    if (!stats) {
      return [];
    }

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

      {loadingStats && (
        <p className="muted">Ładowanie...</p>
      )}

      {errorStats && (
        <p style={{ color: "tomato" }}>
          {errorStats}
        </p>
      )}

      <div className="dashboard">
        <div className="dashboard-stats">
          {cards.map((card) => (
            <StatCard
              key={card.title}
              {...card}
            />
          ))}
        </div>

        <div className="dashboard-mid">
          <OrdersChart
            series={chart.series}
            totalRevenue={chart.totalRevenue}
            newOrders={chart.newOrders}
            successRate={chart.successRate}
            loading={loadingChart}
          />

          <ActivityList
            items={activityItems}
            loading={loadingActivity}
          />
        </div>

        <OrdersTable
          rows={recentOrders}
          loading={loadingRecentOrders}
        />
      </div>
    </div>
  );
}