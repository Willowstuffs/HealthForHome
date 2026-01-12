using System.ComponentModel.DataAnnotations;

namespace H4H_API.DTOs.Client
{
    /// <summary>
    /// Represents the data required to update an existing client record.
    /// </summary>
    /// <remarks>This data transfer object is typically used in update operations to modify client
    /// information. All properties are optional; only the fields to be updated need to be provided. Property values may
    /// be subject to validation constraints such as maximum length or format requirements.</remarks>
    public class ClientUpdateDto
    {
        [MaxLength(100, ErrorMessage = "Imię nie może przekraczać 100 znaków")]
        public string? FirstName { get; set; }

        [MaxLength(100, ErrorMessage = "Nazwisko nie może przekraczać 100 znaków")]
        public string? LastName { get; set; }

        [MaxLength(20, ErrorMessage = "Numer telefonu nie może przekraczać 20 znaków")]
        [Phone(ErrorMessage = "Nieprawidłowy numer telefonu")]
        public string? PhoneNumber { get; set; }

        public DateOnly? DateOfBirth { get; set; }

        [MaxLength(500, ErrorMessage = "Adres nie może przekraczać 500 znaków")]
        public string? Address { get; set; }

        [MaxLength(500, ErrorMessage = "Kontakt awaryjny nie może przekraczać 500 znaków")]
        public string? EmergencyContact { get; set; }
    }
}
