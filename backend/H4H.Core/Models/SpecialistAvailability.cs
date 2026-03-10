using System.ComponentModel.DataAnnotations.Schema;

namespace H4H.Core.Models
{
    [Table("specialist_availability")]
    public class SpecialistAvailability
    {
        [Column("id")]
        public Guid Id { get; set; }

        [Column("specialist_id")]
        public Guid SpecialistId { get; set; }

        [Column("date", TypeName = "date")]
        public DateOnly Date { get; set; }

        [Column("start_time", TypeName = "time")]
        public TimeOnly StartTime { get; set; }

        [Column("end_time", TypeName = "time")]
        public TimeOnly EndTime { get; set; }

        [Column("is_available")]
        public bool IsAvailable { get; set; } = true;

        [Column("recurrence_pattern")]
        public string? RecurrencePattern { get; set; }

        [Column("created_at", TypeName = "timestamp without time zone")]
        public DateTime CreatedAt { get; set; } = DateTime.SpecifyKind(DateTime.Now, DateTimeKind.Unspecified);

        public virtual Specialist Specialist { get; set; } = null!;
    }
}