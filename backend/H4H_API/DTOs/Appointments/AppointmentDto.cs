using System.ComponentModel.DataAnnotations;

namespace H4H_API.DTOs.Appointments
{
    // DTO z informacjami o wizycie
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

    // DTO do tworzenia nowej wizyty
    public class CreateAppointmentDto
    {
        [Required]
        public Guid SpecialistId { get; set; }

        [Required]
        public Guid? SpecialistServiceId { get; set; }

        [Required]
        public DateTime ScheduledStart { get; set; }

        [Required]
        public DateTime ScheduledEnd { get; set; }

        [MaxLength(500)]
        public string? ClientAddress { get; set; } // Adres dla wizyty domowej

        [MaxLength(1000)]
        public string? ClientNotes { get; set; }  // Dodatkowe uwagi klienta
    }

    // DTO do aktualizacji wizyty
    public class UpdateAppointmentDto
    {
        [MaxLength(1000)]
        public string? ClientNotes { get; set; }

        [MaxLength(1000)]
        public string? ClientAddress { get; set; }
    }
}
