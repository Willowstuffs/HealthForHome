using System.ComponentModel.DataAnnotations.Schema;

namespace H4H.Core.Models
{
    [Table("verification_codes")]
    public class VerificationCode
    {
        [Column("id")]
        public Guid Id { get; set; }

        [Column("user_id")]
        public Guid? UserId { get; set; }

        [Column("email")]
        public string Email { get; set; } = string.Empty;

        [Column("code")]
        public string Code { get; set; } = string.Empty;

        [Column("purpose")]
        public string Purpose { get; set; } = string.Empty;

        [Column("is_used")]
        public bool IsUsed { get; set; } = false;

        [Column("expires_at", TypeName = "timestamp without time zone")]
        public DateTime ExpiresAt { get; set; }

        [Column("created_at", TypeName = "timestamp without time zone")]
        public DateTime CreatedAt { get; set; } = DateTime.SpecifyKind(DateTime.Now, DateTimeKind.Unspecified);

        public virtual User? User { get; set; }
    }
}