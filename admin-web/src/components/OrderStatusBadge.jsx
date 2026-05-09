function normalize(status) {
  return String(status || "").toLowerCase();
}

function label(status) {
  switch (normalize(status)) {
    case "pending":
      return "Oczekujące";
    case "open":
      return "Otwarte";
    case "confirmed":
      return "Potwierdzone";
    case "completed":
      return "Zakończone";
    case "cancelled":
      return "Anulowane";
    default:
      return status || "-";
  }
}

function variant(status) {
  switch (normalize(status)) {
    case "pending":
      return "badge--primary";
    case "open":
      return "badge--muted";
    case "confirmed":
      return "badge--success";
    case "completed":
      return "badge--success";
    case "cancelled":
      return "badge--danger";
    default:
      return "badge--muted";
  }
}

export default function OrderStatusBadge({ status }) {
  return <span className={`badge ${variant(status)}`}>{label(status)}</span>;
}