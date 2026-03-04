using System.ComponentModel.DataAnnotations.Schema;

namespace H4H.Core.Models
{
    [Table("verification_logs")]
    public class VerificationLog
    {
        [Column("id")]
        public Guid Id { get; set; }

        [Column("specialist_id")]
        public Guid SpecialistId { get; set; }

        [Column("admin_id")]
        public Guid? AdminId { get; set; }

        [Column("action")]
        public string Action { get; set; } = string.Empty;

        [Column("notes")]
        public string? Notes { get; set; }

        [Column("created_at", TypeName = "timestamp without time zone")]
        public DateTime CreatedAt { get; set; } = DateTime.SpecifyKind(DateTime.Now, DateTimeKind.Unspecified);

        public virtual Specialist Specialist { get; set; } = null!;
        public virtual Admin? Admin { get; set; }
    }
}