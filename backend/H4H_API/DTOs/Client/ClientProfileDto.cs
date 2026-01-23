namespace H4H_API.DTOs.Client
{
    /// <summary>
    /// Represents a data transfer object containing profile information for a client.
    /// </summary>
    /// <remarks>This class is typically used to transfer client profile data between application layers or
    /// services. It includes personal details, contact information, and metadata about the profile's creation and last
    /// update.</remarks>
    public class ClientProfileDto
    {
        public Guid Id { get; set; }     // ID klienta
        public Guid UserId { get; set; } // ID powiązanego użytkownika
        public string Email { get; set; } = string.Empty;
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string? PhoneNumber { get; set; }
        public DateOnly? DateOfBirth { get; set; } // Data urodzenia jako DateOnly
        public string? Address { get; set; }
        public string? EmergencyContact { get; set; }
        public DateTime CreatedAt { get; set; } // Data utworzenia profilu
        public DateTime UpdatedAt { get; set; } // Data ostatniej aktualizacji
    }
}
