using System.ComponentModel.DataAnnotations.Schema;

namespace H4H.Core.Models
{
    [Table("service_areas")]
    public class ServiceArea
    {
        [Column("id")]
        public Guid Id { get; set; }

        [Column("specialist_id")]
        public Guid SpecialistId { get; set; }

        [Column("city")]
        public string City { get; set; } = string.Empty;

        [Column("postal_code")]
        public string? PostalCode { get; set; }

        [Column("max_distance_km")]
        public int MaxDistanceKm { get; set; } = 20;

        [Column("is_primary")]
        public bool IsPrimary { get; set; } = false;

        [Column("created_at", TypeName = "timestamp without time zone")]
        public DateTime CreatedAt { get; set; } = DateTime.SpecifyKind(DateTime.Now, DateTimeKind.Unspecified);

        public virtual Specialist Specialist { get; set; } = null!;
    }
}