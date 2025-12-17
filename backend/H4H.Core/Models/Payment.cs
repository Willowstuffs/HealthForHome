using System.ComponentModel.DataAnnotations.Schema;

namespace H4H.Core.Models
{
    [Table("payments")]
    public class Payment
    {
        [Column("id")]
        public Guid Id { get; set; }

        [Column("appointment_id")]
        public Guid AppointmentId { get; set; }

        [Column("payment_method")]
        public string PaymentMethod { get; set; } = "cash";

        [Column("payment_status")]
        public string PaymentStatus { get; set; } = "pending";

        [Column("cash_received")]
        public bool CashReceived { get; set; } = false;

        [Column("received_at", TypeName = "timestamp without time zone")]
        public DateTime? ReceivedAt { get; set; }

        [Column("created_at", TypeName = "timestamp without time zone")]
        public DateTime CreatedAt { get; set; } = DateTime.SpecifyKind(DateTime.Now, DateTimeKind.Unspecified);

        [Column("updated_at", TypeName = "timestamp without time zone")]
        public DateTime UpdatedAt { get; set; } = DateTime.SpecifyKind(DateTime.Now, DateTimeKind.Unspecified);

        public virtual Appointment Appointment { get; set; } = null!;
    }
}