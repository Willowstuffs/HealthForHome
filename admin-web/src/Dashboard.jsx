import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import { getAdminStats, listOrders } from "./api/adminApi";

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

// createdAt z backendu/moka to ISO string -> bierzemy YYYY-MM-DD
function orderDayKey(o) {
  if (!o?.createdAt) return null;
  if (typeof o.createdAt === "string" && o.createdAt.length >= 10) return o.createdAt.slice(0, 10);
  const d = new Date(o.createdAt);
  if (Number.isNaN(d.getTime())) return null;
  return toYMDLocal(d);
}

/** ---------- small components ---------- */
function StatCard({ title, value, hint, to, className = "" }) {
  const content = (
    <div className={`card card-pad stat-card ${className}`}>
      <div className="card-head">
        <div className="card-title">{title}</div>
      </div>

      <div className="stat-number">{value}</div>
      {hint ? <div className="muted" style={{ marginTop: 6 }}>{hint}</div> : null}
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

/** ---------- chart card (z orders) ---------- */
function OrdersChart({ series, totalRevenue, newOrders, successRate, loading }) {
  if (loading) {
    return (
      <div className="card card-pad">
        <div className="card-head" style={{ justifyContent: "space-between" }}>
          <div>
            <h2>Przychody</h2>
            <div className="muted" style={{ marginTop: 6 }}>Ostatnie 7 dni</div>
          </div>
        </div>
        <div className="muted" style={{ padding: "18px 0" }}>Ładowanie danych wykresu...</div>
      </div>
    );
  }

  if (!series || series.length === 0) {
    return (
      <div className="card card-pad">
        <div className="card-head" style={{ justifyContent: "space-between" }}>
          <div>
            <h2>Przychody</h2>
            <div className="muted" style={{ marginTop: 6 }}>Ostatnie 7 dni</div>
          </div>
        </div>
        <div className="muted" style={{ padding: "18px 0" }}>Brak danych z ostatnich 7 dni.</div>
      </div>
    );
  }

  const W = 600;
  const H = 180;
  const P = 16;

  const values = series.map((p) => Number(p.value || 0));
  const max = Math.max(1, ...values);
  const min = Math.min(...values);

  const scaleX = (i) => (series.length === 1 ? P : P + (i * (W - 2 * P)) / (series.length - 1));
  const scaleY = (v) => {
    if (max === min) return H / 2;
    const t = (v - min) / (max - min);
    return H - P - t * (H - 2 * P);
  };

  const points = series.map((p, i) => `${scaleX(i)},${scaleY(Number(p.value || 0))}`).join(" ");

  return (
    <div className="card card-pad">
      <div className="card-head" style={{ justifyContent: "space-between" }}>
        <div>
          <h2>Przychody</h2>
          <div className="muted" style={{ marginTop: 6 }}>Ostatnie 7 dni</div>
        </div>

        <select className="btn" style={{ height: 40 }} defaultValue="7" disabled>
          <option value="7">Ostatnie 7 dni</option>
        </select>
      </div>

      <div style={{ marginTop: 12 }}>
        <svg viewBox={`0 0 ${W} ${H}`} width="100%" height="180" role="img" aria-label="Wykres przychodów">
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

      <div style={{ display: "grid", gridTemplateColumns: "repeat(3, minmax(0, 1fr))", gap: 12, marginTop: 6 }}>
        <div>
          <div className="muted">Łączny przychód</div>
          <div className="stat-number" style={{ fontSize: 22 }}>{totalRevenue} PLN</div>
        </div>
        <div>
          <div className="muted">Nowe zamówienia</div>
          <div className="stat-number" style={{ fontSize: 22 }}>{newOrders}</div>
        </div>
        <div>
          <div className="muted">Skuteczność</div>
          <div className="stat-number" style={{ fontSize: 22 }}>{successRate}%</div>
        </div>
      </div>
    </div>
  );
}

/** ---------- później podmienimy na API ---------- */
function ActivityMock() {
  const items = [
    { name: "Marek Mazur", email: "marek.mazur@example.com", text: "Zarejestrował się.", time: "25 min temu" },
    { name: "Jakub Nowak", email: "jakub.nowak@example.com", text: "Dodał nowe zamówienie.", time: "12 dni temu" },
    { name: "Ewa Kowalska", email: "ewa.kowalska@example.com", text: "Zaktualizowała profil.", time: "2 dni temu" },
  ];

  return (
    <div className="card card-pad">
      <div className="card-head" style={{ justifyContent: "space-between" }}>
        <h2>Ostatnia aktywność</h2>
        <span className="muted">…</span>
      </div>

      <div style={{ display: "grid", gap: 12, marginTop: 8 }}>
        {items.map((x) => (
          <div key={x.email} style={{ display: "grid", gridTemplateColumns: "42px 1fr auto", gap: 12, alignItems: "center" }}>
            <div className="card-ico" style={{ width: 42, height: 42, borderRadius: 999 }}>
              {x.name.split(" ").map((p) => p[0]).join("").slice(0, 2)}
            </div>

            <div style={{ minWidth: 0 }}>
              <div style={{ fontWeight: 900 }}>{x.name}</div>
              <div className="muted" style={{ overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{x.email}</div>
              <div className="muted">{x.text}</div>
            </div>

            <div className="muted">{x.time}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

function OrdersTableMock() {
  const rows = [
    { id: 1234, client: "Jakub Nowak", specialist: "Andrzej Wiśniewski", date: "18.02.2026", status: "new" },
    { id: 1233, client: "Marek Mazur", specialist: "Andrzej Jakalk", date: "16.02.2026", status: "progress" },
    { id: 1232, client: "Janina Nowak", specialist: "Andrzej Kedreryk", date: "12.02.2026", status: "done" },
    { id: 1231, client: "Ewa Kowalska", specialist: "Piotr Kwiatkowski", date: "05.02.2026", status: "done" },
  ];

  const badge = (s) => {
    if (s === "new") return <span className="badge badge-new">Nowe</span>;
    if (s === "progress") return <span className="badge badge-progress">W realizacji</span>;
    return <span className="badge badge-done">Zakończone</span>;
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
              <th>Specjalista</th>
              <th>Data</th>
              <th>Status</th>
            </tr>
          </thead>

          <tbody>
            {rows.map((r) => (
              <tr key={r.id}>
                <td style={{ fontWeight: 900 }}>#{r.id}</td>
                <td>{r.client}</td>
                <td>{r.specialist}</td>
                <td>{r.date}</td>
                <td>{badge(r.status)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="card-pad muted" style={{ paddingTop: 10 }}>
        Wyświetlanie 1-4 z 4 zamówień (mock)
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

  // 1) stats cards (mock)
  useEffect(() => {
    let cancelled = false;

    setLoadingStats(true);
    setErrorStats("");

    getAdminStats()
      .then((res) => { if (!cancelled) setStats(res); })
      .catch((e) => { if (!cancelled) setErrorStats(e?.message || "Błąd pobierania statystyk"); })
      .finally(() => { if (!cancelled) setLoadingStats(false); });

    return () => { cancelled = true; };
  }, []);

  // 2) chart from orders API (mock listOrders)
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
          status: "",
          createdFrom,
          createdTo,
          sort: "CREATED_ASC",
          page: 1,
          pageSize: 5000,
        });

        const orders = res?.items ?? [];

        const sumByDay = new Map();
        let total = 0;
        let newCount = 0;
        let doneCount = 0;

        for (const o of orders) {
          const v = Number(o.totalValue ?? 0);
          total += v;

          if (o.status === "NEW") newCount += 1;
          if (o.status === "DONE") doneCount += 1;

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

        const successRate = orders.length ? Math.round((doneCount / orders.length) * 100) : 0;

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
    return () => { cancelled = true; };
  }, []);

  const cards = useMemo(() => {
    if (!stats) return [];
    return [
      { title: "Użytkownicy", value: stats.usersTotal, hint: "Łączna liczba klientów", to: "/users" },
      { title: "Specjaliści", value: stats.specialistsTotal, hint: `Oczekuje: ${stats.specialistsPending}`, to: "/specialists" },
      {
        title: "Zamówienia",
        value: stats.ordersTotal,
        hint: `Suma: ${stats.ordersTotalValue} PLN • Nowe: ${stats.ordersNew}`,
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
          <ActivityMock />
        </div>

        <OrdersTableMock />
      </div>
    </div>
  );
}
