using System.ComponentModel.DataAnnotations;

namespace H4H_API.DTOs.Appointments
{
    /// <summary>
    /// Represents the data transfer object for an appointment, including scheduling, participant, and status
    /// information.
    /// </summary>
    /// <remarks>This DTO is typically used to transfer appointment data between application layers or over
    /// service boundaries. It contains identifiers for the client, specialist, and optionally the service, as well as
    /// scheduling details, status, pricing, and related notes. Navigation properties such as names are included for
    /// convenience in presentation scenarios.</remarks>
    public class AppointmentDto
    {
        public Guid Id { get; set; }
        public Guid ClientId { get; set; }                              // ID klienta
        public Guid SpecialistId { get; set; }                          // ID specjalisty
        public Guid? SpecialistServiceId { get; set; }                  // ID usługi specjalisty (opcjonalne)
        public string AppointmentStatus { get; set; } = string.Empty;   // Status wizyty
        public DateTime ScheduledStart { get; set; }                    // Planowany czas rozpoczęcia
        public DateTime ScheduledEnd { get; set; }                      // Planowany czas zakończenia
        public decimal? TotalPrice { get; set; }                        // Całkowita cena
        public string? ClientAddress { get; set; }                      // Adres klienta (dla wizyt domowych)
        public string? ClientNotes { get; set; }                        // Notatki od klienta
        public string? SpecialistNotes { get; set; }                    // Notatki od specjalisty
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public DateTime? CancelledAt { get; set; }                      // Data anulowania (jeśli anulowane)


        // Właściwości nawigacyjne (opcjonalne - do wypełnienia jeśli potrzebne)
        public string? SpecialistName { get; set; }
        public string? ClientName { get; set; }
        public string? ServiceName { get; set; }
    }

    /// <summary>
    /// Represents the data required to create a new appointment.
    /// </summary>
    /// <remarks>This data transfer object is typically used when submitting appointment creation requests
    /// from a client application. All required fields must be provided for the appointment to be created
    /// successfully.</remarks>
    public class CreateAppointmentDto
    {
        [Required]
        public Guid ClientId { get; set; }

        public Guid? SpecialistId { get; set; }

        public Guid? SpecialistServiceId { get; set; }

        public Guid? ServiceTypeId { get; set; }

        [Required]
        public DateTime ScheduledStart { get; set; }

        [Required]
        public DateTime ScheduledEnd { get; set; }

        public decimal? TotalPrice { get; set; }

        [MaxLength(500)]
        public string? ClientAddress { get; set; }

        [Required]
        [MaxLength(150)]
        public string ContactName { get; set; } = string.Empty;

        [Required]
        [MaxLength(30)]
        public string ContactPhoneNumber { get; set; } = string.Empty;

        [Required]
        [MaxLength(150)]
        [EmailAddress]
        public string ContactEmail { get; set; } = string.Empty;

        [MaxLength(1000)]
        public string? ClientNotes { get; set; }

        [MaxLength(1000)]
        public string? SpecialistNotes { get; set; }

        public Guid? SelectedSpecialistId { get; set; }
    }

    /// <summary>
    /// Represents the data required to update an existing appointment, including optional client notes and address
    /// information.
    /// </summary>
    public class UpdateAppointmentDto
    {
        [MaxLength(1000)]
        public string? ClientNotes { get; set; }

        [MaxLength(1000)]
        public string? ClientAddress { get; set; }
    }
}
