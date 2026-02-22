using H4H_API.DTOs.Geolocation;
using NetTopologySuite.Geometries;

namespace H4H_API.Services.Interfaces
{
    public interface IGeocoder
    {
        /// <summary>
        /// Geokoduje adres na współrzędne geograficzne
        /// </summary>
        Task<GeocodingResultDto?> GeocodeAddressAsync(string address);

        /// <summary>
        /// Odwrotne geokodowanie - współrzędne na adres
        /// </summary>
        Task<string?> ReverseGeocodeAsync(double latitude, double longitude);

        /// <summary>
        /// Tworzy punkt geometryczny z współrzędnych
        /// </summary>
        Point CreatePoint(double longitude, double latitude);

        /// <summary>
        /// Oblicza odległość między dwoma punktami (w km)
        /// </summary>
        double CalculateDistance(Point point1, Point point2);

        /// <summary>
        /// Sprawdza czy klient jest w zasięgu specjalisty
        /// </summary>
        Task<bool> IsWithinServiceAreaAsync(Guid clientId, Guid specialistId);
    }
}