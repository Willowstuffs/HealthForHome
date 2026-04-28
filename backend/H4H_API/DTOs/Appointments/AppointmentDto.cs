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
        public List<Guid> SpecialistServiceIds { get; set; } = new();   // Lista ID usług specjalisty (może być pusta dla ogłoszeń "open")
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
        public DateTime? FinalDate { get; set; }
        public bool IsRated { get; set; }

        // Właściwości nawigacyjne (opcjonalne - do wypełnienia jeśli potrzebne)
        public string? SpecialistName { get; set; }
        public string? ClientName { get; set; }
        public List<string> ServiceNames { get; set; } = new();
    }
}
