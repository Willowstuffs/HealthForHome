using System.Globalization; 
using System.Text.Json;
using H4H.Data;
using H4H_API.DTOs.Geolocation;
using H4H_API.Exceptions;
using H4H_API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using NetTopologySuite;
using NetTopologySuite.Geometries;
using NetTopologySuite.IO;

namespace H4H_API.Services.Implementations
{
    public class Geocoder : IGeocoder
    {
        private readonly ApplicationDbContext _context;
        private readonly IConfiguration _configuration;
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly GeometryFactory _geometryFactory;
        private readonly ILogger<Geocoder> _logger;

        // Użyj invariant culture dla parsowania liczb (kropka zamiast przecinka)
        private readonly CultureInfo _invariantCulture = CultureInfo.InvariantCulture;

        public Geocoder(
            ApplicationDbContext context,
            IConfiguration configuration,
            IHttpClientFactory httpClientFactory,
            ILogger<Geocoder> logger)
        {
            _context = context;
            _configuration = configuration;
            _httpClientFactory = httpClientFactory;
            _logger = logger;

            _geometryFactory = NtsGeometryServices.Instance.CreateGeometryFactory(4326);
        }

        public async Task<GeocodingResultDto?> GeocodeAddressAsync(string address)
        {
            if (string.IsNullOrWhiteSpace(address))
                return null;

            try
            {
                // 1. Sprawdź cache
                var cacheKey = HashAddress(address);
                var cached = await _context.address_geocache
                    .FirstOrDefaultAsync(c => c.AddressHash == cacheKey);

                if (cached != null)
                {
                    _logger.LogInformation($"Address found in cache: {address}");
                    return new GeocodingResultDto
                    {
                        Address = address,
                        Latitude = (double)cached.Latitude,
                        Longitude = (double)cached.Longitude,
                        FormattedAddress = cached.FormattedAddress,
                        FromCache = true
                    };
                }

                _logger.LogInformation($"Geocoding address: {address}");

                // 2. Użyj OpenStreetMap Nominatim
                var result = await GeocodeWithNominatimAsync(address);
                if (result != null)
                {
                    // Zapisz w cache
                    await CacheGeocodingResultAsync(address, result);
                    _logger.LogInformation($"Address geocoded successfully: {result.Latitude}, {result.Longitude}");
                    return result;
                }
                else
                {
                    _logger.LogWarning($"Geocoding returned no results for address: {address}");
                    return null;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Geocoding error for address: {address}");
                throw new AppException($"Błąd geokodowania: {ex.Message}", H4H_API.Helpers.ErrorCodes.GeocodingFailed);
            }
        }

        public async Task<string?> ReverseGeocodeAsync(double latitude, double longitude)
        {
            try
            {
                _logger.LogInformation($"Reverse geocoding coordinates: {latitude}, {longitude}");

                var httpClient = _httpClientFactory.CreateClient("Nominatim");


                // UŻYJ KROPEK zamiast przecinków

                var url = $"https://nominatim.openstreetmap.org/reverse?format=json" +
                         $"&lat={latitude.ToString(_invariantCulture)}" +
                         $"&lon={longitude.ToString(_invariantCulture)}" +
                         $"&zoom=18&addressdetails=1";

                // Rate limiting
                await Task.Delay(1000);

                var response = await httpClient.GetStringAsync(url);
                var json = JsonDocument.Parse(response);

                if (json.RootElement.TryGetProperty("error", out _))
                {
                    _logger.LogWarning($"Reverse geocoding error for coordinates {latitude}, {longitude}");
                    return null;
                }

                var displayName = json.RootElement.GetProperty("display_name").GetString();
                _logger.LogInformation($"Reverse geocoding result: {displayName}");

                return displayName;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Reverse geocoding error for coordinates: {latitude}, {longitude}");
                return null;
            }
        }

        public Point CreatePoint(double longitude, double latitude)
        {
            return _geometryFactory.CreatePoint(new Coordinate(longitude, latitude));
        }

        public double CalculateDistance(Point point1, Point point2)
        {
            if (point1 == null || point2 == null)
                return double.MaxValue;

            // Oblicz odległość w metrach używając formuły haversine
            var distanceInMeters = point1.Distance(point2) * 111319.9;

            return distanceInMeters / 1000; // km
        }

        public async Task<bool> IsWithinServiceAreaAsync(Guid clientId, Guid specialistId)
        {
            try
            {
                var client = await _context.clients
                    .FirstOrDefaultAsync(c => c.Id == clientId);

                var serviceArea = await _context.service_areas
                    .FirstOrDefaultAsync(sa => sa.SpecialistId == specialistId && sa.IsPrimary);

                if (client?.AddressPoint == null || serviceArea?.Location == null)
                {
                    _logger.LogWarning($"Missing coordinates for distance calculation. Client: {clientId}, Specialist: {specialistId}");
                    return false;
                }

                var distance = CalculateDistance(client.AddressPoint, serviceArea.Location);
                var isWithinRange = distance <= serviceArea.MaxDistanceKm;

                _logger.LogInformation($"Distance calculation: {distance:F2} km, Max: {serviceArea.MaxDistanceKm} km, Within range: {isWithinRange}");

                return isWithinRange;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error checking service area for client {clientId} and specialist {specialistId}");
                return false;
            }
        }

        #region Private Methods

        private string HashAddress(string address)
        {
            using var sha256 = System.Security.Cryptography.SHA256.Create();
            var hash = sha256.ComputeHash(System.Text.Encoding.UTF8.GetBytes(address.ToLower()));
            return Convert.ToHexString(hash);
        }

        private async Task<GeocodingResultDto?> GeocodeWithNominatimAsync(string address)
        {
            try
            {
                var httpClient = _httpClientFactory.CreateClient("Nominatim");
                var encodedAddress = Uri.EscapeDataString(address);
                var url = $"https://nominatim.openstreetmap.org/search?format=json&q={encodedAddress}&limit=1&addressdetails=1";

                // Rate limiting dla Nominatim (1 request na sekundę)
                await Task.Delay(1000);

                var response = await httpClient.GetStringAsync(url);
                var json = JsonDocument.Parse(response);

                if (json.RootElement.GetArrayLength() == 0)
                {
                    _logger.LogWarning($"No results found for address: {address}");

                    // Spróbuj z prostszym adresem (tylko miasto)
                    if (address.Contains(','))
                    {
                        var cityOnly = address.Split(',')[0].Trim();
                        _logger.LogInformation($"Trying simpler address: {cityOnly}");
                        return await GeocodeWithNominatimAsync(cityOnly);
                    }

                    return null;
                }

                var firstResult = json.RootElement[0];

                // PARSOWANIE Z KULTURĄ INVARIANT (kropka zamiast przecinka!)
                var latString = firstResult.GetProperty("lat").GetString();
                var lonString = firstResult.GetProperty("lon").GetString();

                if (!double.TryParse(latString, _invariantCulture, out double latitude) ||
                    !double.TryParse(lonString, _invariantCulture, out double longitude))
                {
                    _logger.LogError($"Failed to parse coordinates: lat={latString}, lon={lonString}");
                    return null;
                }

                return new GeocodingResultDto
                {
                    Address = address,
                    Latitude = latitude,
                    Longitude = longitude,
                    FormattedAddress = firstResult.GetProperty("display_name").GetString(),
                    FromCache = false
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Nominatim geocoding error for address: {address}");
                return null;
            }
        }

        private async Task CacheGeocodingResultAsync(string address, GeocodingResultDto result)
        {
            try
            {
                var cacheEntry = new H4H.Core.Models.AddressGeocache
                {
                    Id = Guid.NewGuid(),
                    AddressHash = HashAddress(address),
                    Address = address,
                    Latitude = (decimal)result.Latitude,
                    Longitude = (decimal)result.Longitude,
                    FormattedAddress = result.FormattedAddress,
                    CreatedAt = DateTime.SpecifyKind(DateTime.UtcNow, DateTimeKind.Unspecified)
                };

                _context.address_geocache.Add(cacheEntry);
                await _context.SaveChangesAsync();

                _logger.LogInformation($"Cached geocoding result for address: {address}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error caching geocoding result for address: {address}");
            }
        }

        #endregion
    }
}