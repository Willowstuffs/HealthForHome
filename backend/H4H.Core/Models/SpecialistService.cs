using System.ComponentModel.DataAnnotations.Schema;

namespace H4H.Core.Models
{
    [Table("specialist_services")]
    public class SpecialistService
    {
        [Column("id")]
        public Guid Id { get; set; }

        [Column("specialist_id")]
        public Guid SpecialistId { get; set; }

        [Column("service_type_id")]
        public Guid ServiceTypeId { get; set; }

        [Column("duration_minutes")]
        public int DurationMinutes { get; set; }

        [Column("price")]
        public decimal Price { get; set; }

        [Column("description")]
        public string? Description { get; set; }

        [Column("is_active")]
        public bool IsActive { get; set; } = true;

        [Column("created_at", TypeName = "timestamp without time zone")]
        public DateTime CreatedAt { get; set; } = DateTime.SpecifyKind(DateTime.Now, DateTimeKind.Unspecified);

        public virtual Specialist Specialist { get; set; } = null!;
        public virtual ServiceType ServiceType { get; set; } = null!;
        // public virtual ICollection<Appointment> Appointments { get; set; } = new List<Appointment>();
    }
}