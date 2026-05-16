const STATUS_CONFIG = {
  PENDING: {
    label: "Oczekuje",
    style: {
      background: "#e0f2fe",
      color: "#0369a1",
      border: "1px solid #bae6fd",
    },
  },

  APPROVED: {
    label: "Zaakceptowany",
    style: {
      background: "#dcfce7",
      color: "#166534",
      border: "1px solid #bbf7d0",
    },
  },

  REJECTED: {
    label: "Odrzucony",
    style: {
      background: "#fee2e2",
      color: "#991b1b",
      border: "1px solid #fecaca",
    },
  },

  SUSPENDED: {
    label: "Zawieszony",
    style: {
      background: "#fff3cd",
      color: "#856404",
      border: "1px solid #ffe69c",
    },
  },

  DEFAULT: {
    label: "-",
    style: {
      background: "#f1f5f9",
      color: "#475569",
      border: "1px solid #e2e8f0",
    },
  },
};

export default function StatusBadge({ status }) {
  const config =
    STATUS_CONFIG[status] || {
      ...STATUS_CONFIG.DEFAULT,
      label: status || "-",
    };

  return (
    <span
      className="badge"
      style={config.style}
    >
      {config.label}
    </span>
  );
}