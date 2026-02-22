using System.ComponentModel.DataAnnotations.Schema;

namespace H4H.Core.Models
{
    [Table("booked_slots")]
    public class BookedSlot
    {
        [Column("id")]
        public Guid Id { get; set; }

        [Column("specialist_id")]
        public Guid SpecialistId { get; set; }

        [Column("start_datetime", TypeName = "timestamp without time zone")]
        public DateTime StartDateTime { get; set; }

        [Column("end_datetime", TypeName = "timestamp without time zone")]
        public DateTime EndDateTime { get; set; }

        [Column("is_blocked")]
        public bool IsBlocked { get; set; } = true;

        [Column("notes")]
        public string? Notes { get; set; }

        [Column("created_at", TypeName = "timestamp without time zone")]
        public DateTime CreatedAt { get; set; } = DateTime.SpecifyKind(DateTime.Now, DateTimeKind.Unspecified);

        public virtual Specialist Specialist { get; set; } = null!;
    }
}