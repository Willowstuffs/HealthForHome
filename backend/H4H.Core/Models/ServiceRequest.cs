using NetTopologySuite.Geometries;

namespace H4H.Core.Models
{
    public class ServiceRequest
    {
        public Guid Id { get; set; }

        // Opcjonalne dla gości
        public Guid? ClientId { get; set; }
        public virtual Client? Client { get; set; }

        public Guid ServiceTypeId { get; set; }
        public virtual ServiceType ServiceType { get; set; } = null!;

        // Dane kontaktowe
        public string? ContactName { get; set; }
        public string? PhoneNumber { get; set; }
        public string? Email { get; set; }

        // Szczegóły zlecenia
        public string Description { get; set; } = string.Empty; // "Uwagi"
        public DateTime DateFrom { get; set; } // "Data od"
        public DateTime DateTo { get; set; }   // "Data do"
        public decimal? MaxPrice { get; set; }

        // Lokalizacja
        public string Address { get; set; } = string.Empty;
        public Point? Location { get; set; } // PostGIS Point do wyszukiwania

        public string Status { get; set; } = "open";
        public DateTime CreatedAt { get; set; } = DateTime.SpecifyKind(DateTime.UtcNow, DateTimeKind.Unspecified);
        public DateTime UpdatedAt { get; set; } = DateTime.SpecifyKind(DateTime.UtcNow, DateTimeKind.Unspecified);
    }
}