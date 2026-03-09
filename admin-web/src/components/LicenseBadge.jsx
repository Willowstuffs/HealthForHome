function LicenseBadge({ status }) {
  const map = {
    ACTIVE: { label: "WAŻNA", bg: "#22c55e" },
    EXPIRING_SOON: { label: "WYGASA WKRÓTCE", bg: "#f59e0b" },
    EXPIRED: { label: "WYGASŁA", bg: "#ef4444" },
    UNKNOWN: { label: "BRAK DANYCH", bg: "#64748b" },
    SUSPENDED: { label: "ZAWIESZONA", bg: "#f59e0b" },
    REVOKED: { label: "ODEBRANA", bg: "#6b7280" },
  };

  const cfg = map[status] || map.UNKNOWN;

  return (
    <span
      style={{
        display: "inline-block",
        padding: "4px 10px",
        borderRadius: 999,
        fontSize: 12,
        fontWeight: 700,
        color: "#111",
        background: cfg.bg,
      }}
    >
      {cfg.label}
    </span>
  );
}

export default LicenseBadge;