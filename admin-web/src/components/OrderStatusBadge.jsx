const STATUS_CONFIG = {
  pending: {
    label: "Oczekujące",
    className: "badge--primary",
  },

  open: {
    label: "Otwarte",
    className: "badge--muted",
  },

  confirmed: {
    label: "Potwierdzone",
    className: "badge--success",
  },

  completed: {
    label: "Zakończone",
    className: "badge--success",
  },

  cancelled: {
    label: "Anulowane",
    className: "badge--danger",
  },
};

export default function OrderStatusBadge({ status }) {
  const normalized = String(status || "").toLowerCase();

  const config = STATUS_CONFIG[normalized] || {
    label: status || "-",
    className: "badge--muted",
  };

  return (
    <span className={`badge ${config.className}`}>
      {config.label}
    </span>
  );
}