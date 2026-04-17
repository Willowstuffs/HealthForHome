using System.ComponentModel.DataAnnotations;

namespace H4H_API.DTOs.Specialist
{
    /// <summary>
    /// Reprezentuje dane potrzebne do tworzenia lub aktualizacji uslug specjalisty.
    /// </summary>
    public class SpecialistServiceManageDto
    {
        public Guid? ServiceTypeId { get; set; }

        // Nowe pola dla "ręcznego" wpisywania
        [MaxLength(100)]
        public string? ServiceName { get; set; }

        [MaxLength(50)]
        public string? Category { get; set; }

        [Required]
        [Range(1, 10000)]
        public decimal Price { get; set; }

        [Required]
        [Range(5, 720)]
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
