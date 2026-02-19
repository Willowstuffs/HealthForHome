using System.ComponentModel.DataAnnotations.Schema;

namespace H4H.Core.Models
{
    [Table("notifications")]
    public class Notification
    {
        [Column("id")]
        public Guid Id { get; set; }

        [Column("user_id")]
        public Guid UserId { get; set; }

        [Column("type")]
        public string Type { get; set; } = string.Empty;

        [Column("title")]
        public string Title { get; set; } = string.Empty;

        [Column("content")]
        public string? Content { get; set; }

        [Column("is_read")]
        public bool IsRead { get; set; } = false;

        [Column("related_id")]
        public Guid? RelatedId { get; set; }

        [Column("created_at", TypeName = "timestamp without time zone")]
        public DateTime CreatedAt { get; set; } = DateTime.SpecifyKind(DateTime.Now, DateTimeKind.Unspecified);

        public virtual User User { get; set; } = null!;
    }
}