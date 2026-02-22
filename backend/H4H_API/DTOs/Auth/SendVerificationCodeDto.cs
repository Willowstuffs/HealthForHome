using System.ComponentModel.DataAnnotations;

namespace H4H_API.DTOs.Auth
{
    public class SendVerificationCodeDto
    {
        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;
    }
}
