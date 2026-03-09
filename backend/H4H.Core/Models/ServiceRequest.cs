using NetTopologySuite.Geometries;
using System.ComponentModel.DataAnnotations.Schema;

namespace H4H.Core.Models
{
    [Table("service_requests")] // nazwa tabeli w DB
    public class ServiceRequest
    {
        [Column("id")] // mapowanie kolumny id
        public Guid Id { get; set; }

        [Column("client_id")]
        public Guid? ClientId { get; set; }
        public virtual Client? Client { get; set; }

        [Column("service_type_id")]
        public Guid ServiceTypeId { get; set; }
        public virtual ServiceType ServiceType { get; set; } = null!;

        [Column("contact_name")]
        public string? ContactName { get; set; }

        [Column("phone_number")]
        public string? PhoneNumber { get; set; }

        [Column("email")]
        public string? Email { get; set; }

        [Column("description")]
        public string Description { get; set; } = string.Empty;

        [Column("date_from")]
        public DateTime DateFrom { get; set; }

        [Column("date_to")]
        public DateTime DateTo { get; set; }

        [Column("max_price")]
        public decimal? MaxPrice { get; set; }

        [Column("address")]
        public string Address { get; set; } = string.Empty;

        [Column("location")]
        public Point? Location { get; set; }

        [Column("status")]
        public string Status { get; set; } = "open";

        [Column("created_at")]
        public DateTime CreatedAt { get; set; } = DateTime.SpecifyKind(DateTime.UtcNow, DateTimeKind.Unspecified);

        [Column("updated_at")]
        public DateTime UpdatedAt { get; set; } = DateTime.SpecifyKind(DateTime.UtcNow, DateTimeKind.Unspecified);
    }
}
