using System.ComponentModel.DataAnnotations;

namespace H4H_API.DTOs.Auth
{
    // Starsze/generyczne DTO rejestracji (może być używane alternatywnie)
    public class RegisterRequest
    {
        [Required(ErrorMessage = "Email jest wymagany")]
        [EmailAddress(ErrorMessage = "Nieprawidłowy format email")]
        [MaxLength(255, ErrorMessage = "Email nie może przekraczać 255 znaków")]
        public string Email { get; set; } = string.Empty;

        [Required(ErrorMessage = "Hasło jest wymagane")]
        [MinLength(8, ErrorMessage = "Hasło musi mieć minimum 8 znaków")]
        [MaxLength(100, ErrorMessage = "Hasło nie może przekraczać 100 znaków")]
        [RegularExpression(@"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^\da-zA-Z]).{8,}$",
            ErrorMessage = "Hasło musi zawierać wielką literę, małą literę, cyfrę i znak specjalny")]
        public string Password { get; set; } = string.Empty;

        [Required(ErrorMessage = "Imię jest wymagane")]
        [MaxLength(100, ErrorMessage = "Imię nie może przekraczać 100 znaków")]
        public string FirstName { get; set; } = string.Empty;

        [Required(ErrorMessage = "Nazwisko jest wymagane")]
        [MaxLength(100, ErrorMessage = "Nazwisko nie może przekraczać 100 znaków")]
        public string LastName { get; set; } = string.Empty;

        [MaxLength(20, ErrorMessage = "Numer telefonu nie może przekraczać 20 znaków")]
        [Phone(ErrorMessage = "Nieprawidłowy numer telefonu")]
        public string? PhoneNumber { get; set; }

        public string UserType { get; set; } = "client"; // Domyślnie "client", może być "specialist"
    }
}
