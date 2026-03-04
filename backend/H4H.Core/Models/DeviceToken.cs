using System.ComponentModel.DataAnnotations.Schema;

namespace H4H.Core.Models
{
    [Table("device_tokens")]
    public class DeviceToken
    {
        [Column("id")]
        public Guid Id { get; set; }

        [Column("user_id")]
        public Guid UserId { get; set; }

        [Column("fcm_token")]
        public string FcmToken { get; set; } = string.Empty;

        [Column("last_used_at", TypeName = "timestamp without time zone")]
        public DateTime LastUsedAt { get; set; } = DateTime.SpecifyKind(DateTime.UtcNow, DateTimeKind.Unspecified);

        [Column("created_at", TypeName = "timestamp without time zone")]
        public DateTime CreatedAt { get; set; } = DateTime.SpecifyKind(DateTime.UtcNow, DateTimeKind.Unspecified);

        // Nawigacja do użytkownika
        public virtual User User { get; set; } = null!;
    }
}
