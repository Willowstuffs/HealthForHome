using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace H4H_API.Dtos
{
    public class ChangePasswordDto
    {
        [Required]
        [JsonPropertyName("currentPassword")]
        public string CurrentPassword { get; set; } = string.Empty;

        [Required]
        [MinLength(6, ErrorMessage = "Hasło musi mieć co najmniej 6 znaków.")]
        [JsonPropertyName("newPassword")]
        public string NewPassword { get; set; } = string.Empty;
    }
}