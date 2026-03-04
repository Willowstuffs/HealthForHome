using System.ComponentModel.DataAnnotations.Schema;

namespace H4H.Core.Models
{
    [Table("admins")]
    public class Admin
    {
        [Column("id")]
        public Guid Id { get; set; }

        [Column("email")]
        public string Email { get; set; } = string.Empty;

        [Column("password_hash")]
        public string PasswordHash { get; set; } = string.Empty;

        [Column("role")]
        public string? Role { get; set; } = "support";

        [Column("full_name")]
        public string? FullName { get; set; }

        [Column("is_active")]
        public bool? IsActive { get; set; } = true;

        [Column("created_at", TypeName = "timestamp without time zone")]
        public DateTime? CreatedAt { get; set; } = DateTime.SpecifyKind(DateTime.Now, DateTimeKind.Unspecified);

        [Column("last_login_at", TypeName = "timestamp without time zone")]
        public DateTime? LastLoginAt { get; set; }

        public virtual ICollection<SpecialistQualification> VerifiedQualifications { get; set; } = new List<SpecialistQualification>();
        public virtual ICollection<VerificationLog> VerificationLogs { get; set; } = new List<VerificationLog>();
    }
}