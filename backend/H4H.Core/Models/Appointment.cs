using System.ComponentModel.DataAnnotations.Schema;

namespace H4H.Core.Models
{
    [Table("appointments")]
    public class Appointment
    {
        [Column("id")]
        public Guid Id { get; set; }

        [Column("client_id")]
        public Guid ClientId { get; set; }

        [Column("specialist_id")]
        public Guid SpecialistId { get; set; }

        [Column("specialist_service_id")]
        public Guid? SpecialistServiceId { get; set; }

        [Column("appointment_status")]
        public string AppointmentStatus { get; set; } = "pending";

        [Column("scheduled_start", TypeName = "timestamp without time zone")]
        public DateTime ScheduledStart { get; set; }

        [Column("scheduled_end", TypeName = "timestamp without time zone")]
        public DateTime ScheduledEnd { get; set; }

        [Column("total_price")]
        public decimal? TotalPrice { get; set; }

        [Column("client_address")]
        public string? ClientAddress { get; set; }

        [Column("client_notes")]
        public string? ClientNotes { get; set; }

        [Column("specialist_notes")]
        public string? SpecialistNotes { get; set; }

        [Column("created_at", TypeName = "timestamp without time zone")]
        public DateTime CreatedAt { get; set; } = DateTime.SpecifyKind(DateTime.Now, DateTimeKind.Unspecified);

        [Column("updated_at", TypeName = "timestamp without time zone")]
        public DateTime UpdatedAt { get; set; } = DateTime.SpecifyKind(DateTime.Now, DateTimeKind.Unspecified);

        [Column("cancelled_at", TypeName = "timestamp without time zone")]
        public DateTime? CancelledAt { get; set; }

        [Column("selected_specialist_id")]
        public Guid? SelectedSpecialistId { get; set; }


        public virtual Client Client { get; set; } = null!;
        public virtual Specialist Specialist { get; set; } = null!;
        public virtual SpecialistService? SpecialistService { get; set; }
        public virtual Payment? Payment { get; set; }
        public virtual Review? Review { get; set; }
        public virtual ICollection<Message> Messages { get; set; } = new List<Message>();
        public virtual ICollection<AppointmentSpecialist> AppointmentSpecialists { get; set; } = new List<AppointmentSpecialist>();
    }
}