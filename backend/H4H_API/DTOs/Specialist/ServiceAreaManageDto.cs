using System.ComponentModel.DataAnnotations;
namespace H4H_API.DTOs.Specialist
{
    /// <summary>
    /// Reprezentuje dane potrzebne do ustalania zasiegu obszaru usług specjalisty.
    /// </summary>
    public class ServiceAreaManageDto
    {
        [Required]
        public string City { get; set; } = string.Empty;

        // Kod pocztowy może być przydatny
        public string? PostalCode { get; set; }

        [Required]
        [Range(0, 500)] // Maksymalny zasieg uslugi w kilometrach. 500 chyba wystarczy.
        public int MaxDistanceKm { get; set; }
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }

    }
}