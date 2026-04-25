using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace H4H.Core.Models
{
    /// <summary>
    /// Model reprezentujący odświeżający token (refresh token) używany do przedłużania sesji użytkownika bez konieczności ponownego logowania.
    /// </summary>
    [Table("refresh_tokens")]
    public class RefreshToken
    {
        [Column("id")]
        public Guid Id { get; set; }

        [Column("token")]
        public string Token { get; set; } = string.Empty;

        [Column("user_id")]
        public Guid UserId { get; set; }

        [Column("created_at")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [Column("expires_at")]
        public DateTime ExpiresAt { get; set; }

        [Column("revoked_at")]
        public DateTime? RevokedAt { get; set; }

        public virtual User User { get; set; } = null!;
    }
}
