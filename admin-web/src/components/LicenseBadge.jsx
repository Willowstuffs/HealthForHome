const LICENSE_STATUS = {
  ACTIVE: {
    label: "WAŻNA",
    bg: "#22c55e",
  },
  EXPIRING_SOON: {
    label: "WYGASA WKRÓTCE",
    bg: "#f59e0b",
  },
  EXPIRED: {
    label: "WYGASŁA",
    bg: "#ef4444",
  },
  SUSPENDED: {
    label: "ZAWIESZONA",
    bg: "#f59e0b",
  },
  REVOKED: {
    label: "ODEBRANA",
    bg: "#6b7280",
  },
  UNKNOWN: {
    label: "BRAK DANYCH",
    bg: "#64748b",
  },
};

function LicenseBadge({ status }) {
  const { label, bg } =
    LICENSE_STATUS[status] || LICENSE_STATUS.UNKNOWN;

  return (
    <span
      style={{
        display: "inline-block",
        padding: "4px 10px",
        borderRadius: 999,
        fontSize: 12,
        fontWeight: 700,
        color: "#111",
        background: bg,
      }}
    >
      {label}
    </span>
  );
}

export default LicenseBadge;