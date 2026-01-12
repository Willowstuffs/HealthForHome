using H4H_API.DTOs.Common;
using H4H_API.DTOs.Specialist;
using H4H_API.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;
using NetTopologySuite.Geometries;

namespace H4H_API.Controllers
{
    /// <summary>
    /// Kontroler do wyszukiwania specjalistów z wykorzystaniem geolokalizacji
    /// </summary>
    /// <remarks>
    /// Wymaga skonfigurowanego PostGIS w bazie danych i wypełnionych współrzędnych
    /// w tabelach clients.address_point i service_areas.location
    /// </remarks>
    [ApiController]
    [Route("api/[controller]")]
    public class SearchController : ControllerBase
    {
        private readonly ISpecialistService _specialistService;
        private readonly IGeocoder _geocoder;
        private readonly ILogger<SearchController> _logger;

        /// <summary>
        /// Konstruktor kontrolera wyszukiwania
        /// </summary>
        public SearchController(
            ISpecialistService specialistService,
            IGeocoder geocoder,
            ILogger<SearchController> logger)
        {
            _specialistService = specialistService;
            _geocoder = geocoder;
            _logger = logger;
        }

        /// <summary>
        /// Wyszukuje specjalistów w promieniu od podanego adresu klienta
        /// </summary>
        /// <param name="address">Adres klienta (np. "Warszawa, ul. Marszałkowska 1")</param>
        /// <param name="maxDistanceKm">Maksymalna odległość w kilometrach (domyślnie 20)</param>
        /// <param name="filters">Opcjonalne filtry dla specjalistów</param>
        /// <param name="paging">Parametry stronicowania</param>
        /// <returns>Lista specjalistów w podanym promieniu</returns>
        /// <response code="200">Znaleziono specjalistów</response>
        /// <response code="400">Nieprawidłowy adres lub błąd geokodowania</response>
        /// <response code="404">Brak specjalistów w podanym promieniu</response>
        [HttpGet("specialists/nearby")]
        [ProducesResponseType(typeof(ApiResponse<PagedResponse<SpecialistDto>>), 200)]
        [ProducesResponseType(typeof(ApiResponse<object>), 400)]
        [ProducesResponseType(typeof(ApiResponse<object>), 404)]
        public async Task<ActionResult<ApiResponse<PagedResponse<SpecialistDto>>>> SearchNearby(
            [FromQuery] string address,
            [FromQuery] int maxDistanceKm = 20,
            [FromQuery] SearchSpecialistsDto? filters = null,
            [FromQuery] PagedRequest? paging = null)
        {
            _logger.LogInformation("Wyszukiwanie specjalistów w promieniu {Distance}km od: {Address}",
                maxDistanceKm, address);

            try
            {
                // 1. Geokoduj adres klienta na współrzędne
                var clientPoint = await _geocoder.GeocodeAddressAsync(address);
                if (clientPoint == null)
                {
                    _logger.LogWarning("Nie udało się zlokalizować adresu: {Address}", address);
                    return BadRequest(ApiResponse<PagedResponse<SpecialistDto>>
                        .ErrorResponse(
                            message: "Nie udało się zlokalizować podanego adresu. Sprawdź poprawność adresu.",
                            errorCode: "GEO_001"
                        ));
                }

                _logger.LogDebug("Adres '{Address}' zgeokodowany na: {Lat}, {Lon}",
                    address, clientPoint.Y, clientPoint.X);

                // 2. Wyszukaj specjalistów w promieniu (kolega implementuje)
                var result = await _specialistService.SearchNearbyAsync(
                    clientPoint,
                    maxDistanceKm,
                    filters ?? new SearchSpecialistsDto(),
                    paging ?? new PagedRequest { Page = 1, PageSize = 10 });

                if (result.Items.Count == 0)
                {
                    _logger.LogInformation("Brak specjalistów w promieniu {Distance}km od {Address}",
                        maxDistanceKm, address);

                    return Ok(ApiResponse<PagedResponse<SpecialistDto>>
                        .SuccessResponse(
                            data: result,
                            message: $"Brak specjalistów w promieniu {maxDistanceKm}km od podanego adresu"
                        ));
                }

                _logger.LogInformation("Znaleziono {Count} specjalistów w promieniu {Distance}km od {Address}",
                    result.Items.Count, maxDistanceKm, address);

                return Ok(ApiResponse<PagedResponse<SpecialistDto>>
                    .SuccessResponse(
                        data: result,
                        message: $"Znaleziono {result.Items.Count} specjalistów w Twojej okolicy"
                    ));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Błąd podczas wyszukiwania specjalistów dla adresu: {Address}", address);
                return BadRequest(ApiResponse<PagedResponse<SpecialistDto>>
                    .ErrorResponse(
                        message: $"Błąd wyszukiwania: {ex.Message}",
                        errorCode: "SRCH_001"
                    ));
            }
        }

        /// <summary>
        /// Wyszukuje specjalistów w promieniu od podanych współrzędnych GPS
        /// </summary>
        /// <param name="latitude">Szerokość geograficzna (np. 52.2297 dla Warszawy)</param>
        /// <param name="longitude">Długość geograficzna (np. 21.0122 dla Warszawy)</param>
        /// <param name="maxDistanceKm">Maksymalna odległość w kilometrach</param>
        /// <param name="filters">Opcjonalne filtry dla specjalistów</param>
        /// <param name="paging">Parametry stronicowania</param>
        /// <returns>Lista specjalistów w podanym promieniu</returns>
        /// <remarks>
        /// Użyj tego endpointu jeśli masz już współrzędne GPS (np. z geolokalizacji przeglądarki)
        /// </remarks>
        [HttpGet("specialists/nearby/coordinates")]
        [ProducesResponseType(typeof(ApiResponse<PagedResponse<SpecialistDto>>), 200)]
        public async Task<ActionResult<ApiResponse<PagedResponse<SpecialistDto>>>> SearchNearbyByCoordinates(
            [FromQuery] double latitude,
            [FromQuery] double longitude,
            [FromQuery] int maxDistanceKm = 20,
            [FromQuery] SearchSpecialistsDto? filters = null,
            [FromQuery] PagedRequest? paging = null)
        {
            _logger.LogInformation("Wyszukiwanie specjalistów w promieniu {Distance}km od współrzędnych: {Lat}, {Lon}",
                maxDistanceKm, latitude, longitude);

            // Tworzymy punkt z podanych współrzędnych
            var clientPoint = new Point(longitude, latitude) { SRID = 4326 };

            var result = await _specialistService.SearchNearbyAsync(
                clientPoint,
                maxDistanceKm,
                filters ?? new SearchSpecialistsDto(),
                paging ?? new PagedRequest { Page = 1, PageSize = 10 });

            return Ok(ApiResponse<PagedResponse<SpecialistDto>>
                .SuccessResponse(
                    data: result,
                    message: $"Znaleziono {result.Items.Count} specjalistów w promieniu {maxDistanceKm}km"
                ));
        }

        /// <summary>
        /// Oblicza odległość między specjalistą a adresem klienta
        /// </summary>
        /// <param name="specialistId">ID specjalisty</param>
        /// <param name="clientAddress">Adres klienta</param>
        /// <returns>Odległość w kilometrach</returns>
        /// <response code="200">Obliczono odległość</response>
        /// <response code="404">Nie znaleziono specjalisty</response>
        [HttpGet("distance")]
        [ProducesResponseType(typeof(ApiResponse<DistanceDto>), 200)]
        [ProducesResponseType(typeof(ApiResponse<object>), 404)]
        public async Task<ActionResult<ApiResponse<DistanceDto>>> CalculateDistance(
            [FromQuery] Guid specialistId,
            [FromQuery] string clientAddress)
        {
            _logger.LogInformation("Obliczanie odległości specjalisty {SpecialistId} od adresu: {Address}",
                specialistId, clientAddress);

            try
            {
                // 1. Geokoduj adres klienta
                var clientPoint = await _geocoder.GeocodeAddressAsync(clientAddress);
                if (clientPoint == null)
                {
                    return BadRequest(ApiResponse<DistanceDto>
                        .ErrorResponse("Nieprawidłowy adres klienta", "GEO_002"));
                }

                // 2. Oblicz odległość (kolega implementuje)
                var distanceKm = await _specialistService.CalculateDistanceAsync(specialistId, clientPoint);

                if (distanceKm < 0)
                {
                    return NotFound(ApiResponse<DistanceDto>
                        .ErrorResponse("Specjalista nie ma zdefiniowanej lokalizacji", "SRCH_002"));
                }

                _logger.LogDebug("Odległość specjalisty {SpecialistId} od {Address}: {Distance}km",
                    specialistId, clientAddress, distanceKm);

                return Ok(ApiResponse<DistanceDto>.SuccessResponse(
                    data: new DistanceDto
                    {
                        SpecialistId = specialistId,
                        DistanceKm = Math.Round(distanceKm, 1),
                        ClientAddress = clientAddress
                    },
                    message: $"Odległość: {Math.Round(distanceKm, 1)} km"
                ));
            }
            catch (KeyNotFoundException)
            {
                return NotFound(ApiResponse<DistanceDto>
                    .ErrorResponse($"Nie znaleziono specjalisty o ID {specialistId}", "SRCH_003"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Błąd obliczania odległości dla specjalisty {SpecialistId}", specialistId);
                return BadRequest(ApiResponse<DistanceDto>
                    .ErrorResponse($"Błąd obliczania odległości: {ex.Message}", "SRCH_004"));
            }
        }
    }

    /// <summary>
    /// DTO z informacją o odległości między specjalistą a klientem
    /// </summary>
    public class DistanceDto
    {
        /// <summary>
        /// ID specjalisty
        /// </summary>
        public Guid SpecialistId { get; set; }

        /// <summary>
        /// Odległość w kilometrach
        /// </summary>
        public double DistanceKm { get; set; }

        /// <summary>
        /// Adres klienta (dla informacji zwrotnej)
        /// </summary>
        public string? ClientAddress { get; set; }
    }




    /// <summary>
    /// Tymczasowa implementacja dopóki nie zostanie doana implementacja metod do ISpecialistService
    /// TODO: Usunąć gdy dodane prawdziwe implementacje
    /// </summary>
    public static class SpecialistServiceExtensions
    {
        public static Task<PagedResponse<SpecialistDto>> SearchNearbyAsync(
            this ISpecialistService service,
            NetTopologySuite.Geometries.Point clientLocation,
            int maxDistanceKm,
            SearchSpecialistsDto filters,
            PagedRequest paging)
        {
            // Tymczasowo zwracamy pustą listę
            return Task.FromResult(new PagedResponse<SpecialistDto>
            {
                Items = new List<SpecialistDto>(),
                Page = paging.Page,
                PageSize = paging.PageSize,
                TotalCount = 0
            });
        }

        public static Task<double> CalculateDistanceAsync(
            this ISpecialistService service,
            Guid specialistId,
            NetTopologySuite.Geometries.Point clientLocation)
        {
            // Tymczasowo zwracamy -1 (błąd)
            // ta metoda zostanie zastąpiona po doadaniu impweaneacji
            return Task.FromResult(-1.0);
        }
    }
}