using System.ComponentModel.DataAnnotations;

namespace H4H_API.DTOs.Client
{
    /// <summary>
    /// Represents the data required to register a new client account.
    /// </summary>
    /// <remarks>This data transfer object is typically used to collect and validate user input during the
    /// client registration process. All required fields must be provided and meet the specified validation criteria for
    /// successful registration.</remarks>
    public class ClientRegisterDto
    {
        [Required(ErrorMessage = "Email jest wymagany")]
        [EmailAddress(ErrorMessage = "Nieprawidłowy format email")]
        [MaxLength(255)]
        public string Email { get; set; } = string.Empty;

        [Required(ErrorMessage = "Hasło jest wymagane")]
        [MinLength(8, ErrorMessage = "Hasło musi mieć minimum 8 znaków")]
        [MaxLength(100)]
        // Walidacja złożoności hasła: wielka litera, mała litera, cyfra, znak specjalny
        [RegularExpression(@"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^\da-zA-Z]).{8,}$",
            ErrorMessage = "Hasło musi zawierać wielką literę, małą literę, cyfrę i znak specjalny")]
        public string Password { get; set; } = string.Empty;

        [Required(ErrorMessage = "Imię jest wymagane")]
        [MaxLength(100)]
        public string FirstName { get; set; } = string.Empty;

        [Required(ErrorMessage = "Nazwisko jest wymagane")]
        [MaxLength(100)]
        public string LastName { get; set; } = string.Empty;

        [MaxLength(20)]
        [Phone(ErrorMessage = "Nieprawidłowy numer telefonu")]
        public string? PhoneNumber { get; set; } // Opcjonalny numer telefonu

        public DateOnly? DateOfBirth { get; set; } // Data urodzenia w formacie DateOnly

        [MaxLength(500)]
        public string? Address { get; set; } // Adres zamieszkania

        [MaxLength(500)]
        public string? EmergencyContact { get; set; } // Kontakt awaryjny
    }
}
