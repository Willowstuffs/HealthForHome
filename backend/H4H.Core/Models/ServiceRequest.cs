using System.ComponentModel.DataAnnotations.Schema;
using NetTopologySuite.Geometries;

namespace H4H.Core.Models
{
    [Table("service_requests")]
    public class ServiceRequest
    {
        [Column("id")]
        public Guid Id { get; set; }

        // Opcjonalne dla gości
        [Column("client_id")]
        public Guid? ClientId { get; set; }

        [Column("service_type_id")]
        public Guid ServiceTypeId { get; set; }

        // Dane kontaktowe
        [Column("contact_name")]
        public string ContactName { get; set; }

        [Column("phone_number")]
        public string PhoneNumber { get; set; }

        [Column("email")]
        public string Email { get; set; }

        // Szczegóły zlecenia
        [Column("description")]
        public string Description { get; set; }

        [Column("date_from")]
        public DateTime DateFrom { get; set; }

        [Column("date_to")]
        public DateTime DateTo { get; set; }

        [Column("max_price")]
        public decimal? MaxPrice { get; set; }

        // Lokalizacja
        [Column("address")]
        public string Address { get; set; }

        [Column("location")]
        public Point Location { get; set; }

        [Column("status")]
        public string Status { get; set; } = "open";

        [Column("created_at")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [Column("updated_at")]
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        // Nawigacja (bez atrybutu Column, bo to nie jest kolumna w bazie)
        public virtual Client Client { get; set; }
        [ForeignKey("ServiceTypeId")]
        public virtual ServiceType ServiceType { get; set; }
    }
}