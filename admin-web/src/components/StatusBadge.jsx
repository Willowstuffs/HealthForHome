function label(status){
  switch(status){
    case "PENDING":
      return "Oczekuje";

    case "APPROVED":
      return "Zaakceptowany";

    case "REJECTED":
      return "Odrzucony";

    case "SUSPENDED":
      return "Zawieszony";

    default:
      return status || "-";
  }
}

function style(status){
  switch(status){
    case "PENDING":
      return {
        background: "#e0f2fe",
        color: "#0369a1",
        border: "1px solid #bae6fd",
      };

    case "APPROVED":
      return {
        background: "#dcfce7",
        color: "#166534",
        border: "1px solid #bbf7d0",
      };

    case "REJECTED":
      return {
        background: "#fee2e2",
        color: "#991b1b",
        border: "1px solid #fecaca",
      };

    case "SUSPENDED":
      return {
        background: "#fff3cd",
        color: "#856404",
        border: "1px solid #ffe69c",
      };

    default:
      return {
        background: "#f1f5f9",
        color: "#475569",
        border: "1px solid #e2e8f0",
      };
  }
}

export default function StatusBadge({ status }){
  return (
    <span
      className="badge"
      style={style(status)}
    >
      {label(status)}
    </span>
  );
}