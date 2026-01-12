using NetTopologySuite.Geometries;

namespace H4H_API.Services.Interfaces
{
    /// <summary>
    /// Interfejs serwisu geokodującego - zamienia adresy tekstowe na współrzędne geograficzne
    /// </summary>
    /// <remarks>
    /// Implementacja wykorzystuje OpenStreetMap Nominatim i cache w bazie danych
    /// </remarks>
    public interface IGeocoder
    {
        /// <summary>
        /// Geokoduje adres (np. "Warszawa, ul. Marszałkowska 1") na punkt geograficzny
        /// </summary>
        /// <param name="address">Pełny adres tekstowy do geokodowania</param>
        /// <returns>Punkt geograficzny (Point) z współrzędnymi lub null jeśli nie udało się znaleźć</returns>
        Task<Point?> GeocodeAddressAsync(string address);

        /// <summary>
        /// Geokoduje miasto (z opcjonalnym kodem pocztowym) na punkt geograficzny
        /// </summary>
        /// <param name="city">Nazwa miasta</param>
        /// <param name="postalCode">Opcjonalny kod pocztowy</param>
        /// <returns>Punkt geograficzny reprezentujący środek miasta</returns>
        Task<Point?> GeocodeCityAsync(string city, string? postalCode = null);
    }
}