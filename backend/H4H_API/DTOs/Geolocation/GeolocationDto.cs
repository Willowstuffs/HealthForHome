using System.ComponentModel.DataAnnotations;

namespace H4H_API.DTOs.Geolocation
{
    /// <summary>
    /// Reprezentuje koordynaty geograficzne
    /// </summary>
    public class CoordinatesDto
    {
        [Range(-90, 90, ErrorMessage = "Szerokość geograficzna musi być między -90 a 90")]
        public double Latitude { get; set; }

        [Range(-180, 180, ErrorMessage = "Długość geograficzna musi być między -180 a 180")]
        public double Longitude { get; set; }
    }

    /// <summary>
    /// DTO do aktualizacji adresu z możliwością geokodowania
    /// </summary>
    public class AddressUpdateDto
    {
        [MaxLength(500, ErrorMessage = "Adres nie może przekraczać 500 znaków")]
        public string? Address { get; set; }

        public double? Latitude { get; set; }
        public double? Longitude { get; set; }

        public bool ShouldGeocode { get; set; } = true; // Czy automatycznie geokodować adres
    }

    /// <summary>
    /// Rezultat geokodowania
    /// </summary>
    public class GeocodingResultDto
    {
        public string Address { get; set; } = string.Empty;
        public double Latitude { get; set; }
        public double Longitude { get; set; }
        public string? FormattedAddress { get; set; }
        public bool FromCache { get; set; }
    }

    /// <summary>
    /// Informacje o odległości między punktami
    /// </summary>
    public class DistanceInfoDto
    {
        public double DistanceKm { get; set; }
        public double DistanceMiles { get; set; }
        public bool IsWithinRange { get; set; }
        public string EstimatedTravelTime { get; set; } = string.Empty; // np. "25 minut"
    }
}