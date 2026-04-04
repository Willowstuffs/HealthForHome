function label(status){
  switch(status){
    case "NEW": return "Nowe";
    case "IN_PROGRESS": return "W trakcie";
    case "DONE": return "Zrealizowane";
    case "CANCELLED": return "Anulowane";
    default: return status || "-";
  }
}

function variant(status){
  switch(status){
    case "NEW": return "badge--primary";
    case "IN_PROGRESS": return "badge--muted";
    case "DONE": return "badge--success";
    case "CANCELLED": return "badge--danger";
    default: return "badge--muted";
  }
}

export default function OrderStatusBadge({ status }){
  return <span className={`badge ${variant(status)}`}>{label(status)}</span>;
}
