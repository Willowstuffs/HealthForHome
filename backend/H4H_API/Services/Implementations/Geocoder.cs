using System.Security.Cryptography;
using System.Text;
using H4H.Core.Helpers;
using H4H.Core.Models;
using H4H.Data;
using H4H_API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using NetTopologySuite.Geometries;

namespace H4H_API.Services.Implementations
{
    /// <summary>
    /// Implementacja serwisu geokodującego wykorzystująca OpenStreetMap Nominatim
    /// Zapisuje wyniki do cache'u w bazie danych (tabela address_geocache)
    /// </summary>
    /// <remarks>
    /// UWAGA: Nominatim ma ograniczenia rate (1 req/s). Dla produkcji rozważ Google Maps API.
    /// Wymaga atrybucji: © OpenStreetMap contributors
    /// </remarks>
    public class Geocoder : IGeocoder
    {
        private readonly ApplicationDbContext _context;
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly IConfiguration _configuration;
        private readonly ILogger<Geocoder> _logger;

        /// <summary>
        /// Konstruktor serwisu geokodującego
        /// </summary>
        /// <param name="context">DbContext dla dostępu do cache'u</param>
        /// <param name="httpClientFactory">Factory do tworzenia klientów HTTP</param>
        /// <param name="configuration">Konfiguracja aplikacji</param>
        /// <param name="logger">Logger dla diagnostyki</param>
        public Geocoder(
            ApplicationDbContext context,
            IHttpClientFactory httpClientFactory,
            IConfiguration configuration,
            ILogger<Geocoder> logger)
        {
            _context = context;
            _httpClientFactory = httpClientFactory;
            _configuration = configuration;
            _logger = logger;
        }

        /// <inheritdoc/>
        public async Task<Point?> GeocodeAddressAsync(string address)
        {
            if (string.IsNullOrWhiteSpace(address))
            {
                _logger.LogWarning("Próba geokodowania pustego adresu");
                return null;
            }

            // 1. Sprawdź czy mamy w cache'u
            var cached = await CheckCacheAsync(address);
            if (cached != null)
            {
                _logger.LogDebug("Użyto cache'owanego adresu: {Address}", address);
                return new Point((double)cached.Longitude, (double)cached.Latitude) { SRID = 4326 };
            }

            try
            {
                // 2. Geokoduj przez API
                var point = await GeocodeWithNominatimAsync(address);
                if (point != null)
                {
                    // 3. Zapisz do cache'u dla przyszłych zapytań
                    await SaveToCacheAsync(address, point.Y, point.X, $"Geokodowane: {address}");
                }

                return point;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Błąd geokodowania adresu: {Address}", address);
                return null;
            }
        }

        /// <inheritdoc/>
        public async Task<Point?> GeocodeCityAsync(string city, string? postalCode = null)
        {
            var address = postalCode != null ? $"{postalCode} {city}" : city;
            return await GeocodeAddressAsync(address);
        }

        /// <summary>
        /// Sprawdza cache geokodowania w bazie danych
        /// </summary>
        /// <param name="address">Adres do sprawdzenia</param>
        /// <returns>Rekord cache lub null jeśli nie znaleziono</returns>
        private async Task<AddressGeocache?> CheckCacheAsync(string address)
        {
            var hash = ComputeSha256Hash(address);
            return await _context.address_geocache
                .AsNoTracking()
                .FirstOrDefaultAsync(c => c.AddressHash == hash);
        }

        /// <summary>
        /// Geokoduje adres przy użyciu Nominatim (OpenStreetMap)
        /// </summary>
        /// <param name="address">Adres do geokodowania</param>
        /// <returns>Punkt geograficzny lub null</returns>
        private async Task<Point?> GeocodeWithNominatimAsync(string address)
        {
            try
            {
                var client = _httpClientFactory.CreateClient();
                var encodedAddress = Uri.EscapeDataString(address);

                // POPRAWIONY URL - dodaj &countrycodes=pl dla Polski
                var url = $"https://nominatim.openstreetmap.org/search?format=json&q={encodedAddress}&countrycodes=pl&limit=1";

                // BARDZIEJ SZCZEGÓŁOWY User-Agent (wymagany!)
                client.DefaultRequestHeaders.Clear();
                client.DefaultRequestHeaders.UserAgent.ParseAdd("Mozilla/5.0 (compatible; Health4Home/1.0; +contact@health4home.pl)");
                client.DefaultRequestHeaders.Accept.ParseAdd("application/json");

                _logger.LogInformation("Geokodowanie: {Address}", address);

                // Dodaj timeout i retry
                using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(10));
                var response = await client.GetAsync(url, cts.Token);

                if (response.IsSuccessStatusCode)
                {
                    var json = await response.Content.ReadAsStringAsync();
                    var results = System.Text.Json.JsonSerializer.Deserialize<List<NominatimResult>>(json);

                    if (results?.Count > 0)
                    {
                        var result = results[0];
                        _logger.LogDebug("Znaleziono: {Lat}, {Lon} dla {Address}",
                            result.lat, result.lon, address);

                        return new Point(double.Parse(result.lon), double.Parse(result.lat))
                        {
                            SRID = 4326
                        };
                    }
                    else
                    {
                        _logger.LogWarning("Brak wyników dla: {Address}", address);
                    }
                }
                else
                {
                    _logger.LogError("Nominatim error {StatusCode}: {Reason}",
                        response.StatusCode, response.ReasonPhrase);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Błąd geokodowania: {Address}", address);
            }

            return null;
        }

        /// <summary>
        /// Zapisuje wynik geokodowania do cache'u w bazie danych
        /// </summary>
        private async Task SaveToCacheAsync(string address, double latitude, double longitude, string formattedAddress)
        {
            try
            {
                var hash = ComputeSha256Hash(address);

                var cache = new AddressGeocache
                {
                    Id = Guid.NewGuid(),
                    AddressHash = hash,
                    Address = address,
                    Latitude = (decimal)latitude,
                    Longitude = (decimal)longitude,
                    FormattedAddress = formattedAddress,
                    CreatedAt = DateTimeHelper.NowUnspecified
                };

                _context.address_geocache.Add(cache);
                await _context.SaveChangesAsync();

                _logger.LogDebug("Zapisano do cache'u: {Address} -> {Lat}, {Lon}",
                    address, latitude, longitude);
            }
            catch (Exception ex)
            {
                // Logujemy ale nie przerywamy - cache to optymalizacja
                _logger.LogWarning(ex, "Błąd zapisywania do cache'u geokodowania");
            }
        }

        /// <summary>
        /// Oblicza hash SHA256 adresu dla indeksowania cache'u
        /// </summary>
        private static string ComputeSha256Hash(string input)
        {
            using var sha256 = SHA256.Create();
            var bytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(input.Trim().ToLower()));
            return BitConverter.ToString(bytes).Replace("-", "").ToLower();
        }

        /// <summary>
        /// Model odpowiedzi Nominatim API
        /// </summary>
        private class NominatimResult
        {
            public string lat { get; set; } = string.Empty;
            public string lon { get; set; } = string.Empty;
            public string display_name { get; set; } = string.Empty;
            public string type { get; set; } = string.Empty;
        }
    }
}