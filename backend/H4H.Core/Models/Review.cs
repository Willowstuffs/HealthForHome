using System.ComponentModel.DataAnnotations.Schema;

namespace H4H.Core.Models
{
    [Table("reviews")]
    public class Review
    {
        [Column("id")]
        public Guid Id { get; set; }

        [Column("appointment_id")]
        public Guid AppointmentId { get; set; }

        [Column("client_id")]
        public Guid ClientId { get; set; }

        [Column("specialist_id")]
        public Guid SpecialistId { get; set; }

        [Column("rating")]
        public int Rating { get; set; }

        [Column("comment")]
        public string? Comment { get; set; }

        [Column("is_verified")]
        public bool IsVerified { get; set; } = true;

        [Column("created_at", TypeName = "timestamp without time zone")]
        public DateTime CreatedAt { get; set; } = DateTime.SpecifyKind(DateTime.Now, DateTimeKind.Unspecified);

        [Column("updated_at", TypeName = "timestamp without time zone")]
        public DateTime UpdatedAt { get; set; } = DateTime.SpecifyKind(DateTime.Now, DateTimeKind.Unspecified);

        public virtual Appointment Appointment { get; set; } = null!;
        public virtual Client Client { get; set; } = null!;
        public virtual Specialist Specialist { get; set; } = null!;
    }
}