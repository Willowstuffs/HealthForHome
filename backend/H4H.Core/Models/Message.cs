using System.ComponentModel.DataAnnotations.Schema;

namespace H4H.Core.Models
{
    [Table("messages")]
    public class Message
    {
        [Column("id")]
        public Guid Id { get; set; }

        [Column("sender_id")]
        public Guid SenderId { get; set; }

        [Column("receiver_id")]
        public Guid ReceiverId { get; set; }

        [Column("appointment_id")]
        public Guid? AppointmentId { get; set; }

        [Column("content")]
        public string Content { get; set; } = string.Empty;

        [Column("is_read")]
        public bool IsRead { get; set; } = false;

        [Column("created_at", TypeName = "timestamp without time zone")]
        public DateTime CreatedAt { get; set; } = DateTime.SpecifyKind(DateTime.Now, DateTimeKind.Unspecified);

        [Column("updated_at", TypeName = "timestamp without time zone")]
        public DateTime UpdatedAt { get; set; } = DateTime.SpecifyKind(DateTime.Now, DateTimeKind.Unspecified);

        public virtual User Sender { get; set; } = null!;
        public virtual User Receiver { get; set; } = null!;
        public virtual Appointment? Appointment { get; set; }
    }
}