function LicenseBadge({ status }) {
  const map = {
    VALID: { label: "LICENCJA: OK", bg: "#22c55e" },
    EXPIRED: { label: "LICENCJA: WYGASŁA", bg: "#ef4444" },
    SUSPENDED: { label: "LICENCJA: ZAWIESZONA", bg: "#f59e0b" },
    REVOKED: { label: "LICENCJA: ODEBRANA", bg: "#6b7280" },
  };

  const cfg = map[status] || { label: status || "LICENCJA: BRAK", bg: "#64748b" };

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
