using System.ComponentModel.DataAnnotations;

namespace H4H_API.DTOs.Auth
{
    // DTO dla żądania logowania z walidacją danych
    public class LoginRequest
    {
        [Required(ErrorMessage = "Email jest wymagany")]
        [EmailAddress(ErrorMessage = "Nieprawidłowy format email")]
        [MaxLength(255, ErrorMessage = "Email nie może przekraczać 255 znaków")]
        public string Email { get; set; } = string.Empty;

        [Required(ErrorMessage = "Hasło jest wymagane")]
        [MinLength(8, ErrorMessage = "Hasło musi mieć minimum 8 znaków")]
        [MaxLength(100, ErrorMessage = "Hasło nie może przekraczać 100 znaków")]
        public string Password { get; set; } = string.Empty;
    }
}
