function label(status){
  switch(status){
    case "PENDING": return "Oczekuje";
    case "APPROVED": return "Zaakceptowany";
    case "REJECTED": return "Odrzucony";
    default: return status || "-";
  }
}

function variant(status){
  switch(status){
    case "PENDING": return "badge--primary";
    case "APPROVED": return "badge--success";
    case "REJECTED": return "badge--danger";
    default: return "badge--muted";
  }
}

export default function StatusBadge({ status }){
  return <span className={`badge ${variant(status)}`}>{label(status)}</span>;
}
