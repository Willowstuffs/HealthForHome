using System.ComponentModel.DataAnnotations.Schema;

namespace H4H.Core.Models
{
    [Table("service_types")]
    public class ServiceType
    {
        [Column("id")]
        public Guid Id { get; set; }

        [Column("name")]
        public string Name { get; set; } = string.Empty;

        [Column("category")]
        public string Category { get; set; } = string.Empty;

        [Column("default_duration")]
        public int? DefaultDuration { get; set; }

        [Column("description")]
        public string? Description { get; set; }

        [Column("created_at", TypeName = "timestamp without time zone")]
        public DateTime CreatedAt { get; set; } = DateTime.SpecifyKind(DateTime.Now, DateTimeKind.Unspecified);

        public virtual ICollection<SpecialistService> SpecialistServices { get; set; } = new List<SpecialistService>();
    }
}