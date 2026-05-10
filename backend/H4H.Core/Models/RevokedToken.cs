using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.ComponentModel.DataAnnotations.Schema;

namespace H4H.Core.Models
{
    [Table("revoked_tokens")]
    public class RevokedToken
    {
        [Column("id")]
        public Guid Id { get; set; }

        [Column("token")]
        public string Token { get; set; } = string.Empty;

        [Column("expires_at")]
        public DateTime ExpiresAt { get; set; }
    }
}