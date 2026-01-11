using System.ComponentModel.DataAnnotations;

namespace H4H_API.DTOs.Specialist
{
    /// <summary>
    /// Reprezentuje dane potrzebne do tworzenia lub aktualizacji uslug specjalisty.
    /// </summary>
    public class SpecialistServiceManageDto
    {
        // ID Typu usługi (np. "Masaż leczniczy" z tabeli słownikowej service_types)
        [Required]
        public Guid ServiceTypeId { get; set; }

        [Required]
        [Range(1, 10000)]
        public decimal Price { get; set; }

        [Required]
        [Range(5, 720)] // od 5 minut do 12 godzin
        public int DurationMinutes { get; set; }

        [MaxLength(500)]
        public string? Description { get; set; }
    }
    public class ServiceTypeDto
    {
        public Guid Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Category { get; set; } = string.Empty;
        public int DefaultDuration { get; set; } // w minutach
        public string? Description { get; set; }
    }
}
