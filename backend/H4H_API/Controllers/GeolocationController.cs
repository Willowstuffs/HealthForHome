using H4H.Data;
using H4H_API.DTOs.Common;
using H4H_API.DTOs.Geolocation;
using H4H_API.Exceptions;
using H4H_API.Helpers;
using H4H_API.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace H4H_API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class GeolocationController : ControllerBase
    {
        private readonly IGeocoder _geocoder;
        private readonly IClientService _clientService;
        private readonly ApplicationDbContext _context;

        public GeolocationController(
            IGeocoder geocoder,
            IClientService clientService,
            ApplicationDbContext context)
        {
            _geocoder = geocoder;
            _clientService = clientService;
            _context = context;
        }

        /// <summary>
        /// Geokoduje adres na współrzędne
        /// </summary>
        [HttpPost("geocode")]
        public async Task<ActionResult<ApiResponse<GeocodingResultDto>>> Geocode([FromBody] string address)
        {
            try
            {
                var result = await _geocoder.GeocodeAddressAsync(address);
                if (result == null)
                    return NotFound(ApiResponse<GeocodingResultDto>.ErrorResponse(
                        "Nie znaleziono adresu",
                        ErrorCodes.AddressNotFound
                    ));

                return Ok(ApiResponse<GeocodingResultDto>.SuccessResponse(result, "Adres zgeokodowany"));
            }
            catch (Exception ex)
            {
                return BadRequest(ApiResponse<GeocodingResultDto>.ErrorResponse(
                    ex.Message,
                    ErrorCodes.GeocodingFailed
                ));
            }
        }

        /// <summary>
        /// Odwrotne geokodowanie - współrzędne na adres
        /// </summary>
        [HttpPost("reverse-geocode")]
        public async Task<ActionResult<ApiResponse<string>>> ReverseGeocode([FromBody] CoordinatesDto coordinates)
        {
            try
            {
                var address = await _geocoder.ReverseGeocodeAsync(
                    coordinates.Latitude,
                    coordinates.Longitude
                );

                return Ok(ApiResponse<string>.SuccessResponse(
                    address ?? "Nie znaleziono adresu dla podanych współrzędnych"
                ));
            }
            catch
            {
                return BadRequest(ApiResponse<string>.ErrorResponse(
                    "Błąd odwrotnego geokodowania",
                    ErrorCodes.GeocodingFailed
                ));
            }
        }

        /// <summary>
        /// Oblicza odległość między konkretnym ogłoszeniem a obszarem pracy specjalisty
        /// </summary>
        [HttpGet("distance/{specialistId}")]
        [Authorize(Roles = "client")] // nie zezwalamy juz na anonimowosc - gosci
        public async Task<ActionResult<ApiResponse<DistanceInfoDto>>> CalculateDistanceToSpecialist(
            Guid specialistId,
            [FromQuery] Guid serviceRequestId)
        {
            try
            {
                // Sprawdź, czy klient jest w zasięgu specjalisty
                var result = await _clientService.GetDistanceToServiceRequestAsync(specialistId, serviceRequestId);

                return Ok(ApiResponse<DistanceInfoDto>.SuccessResponse(result, "Dystans obliczony pomyślnie"));
            }
            catch (AppException ex)
            {
                return BadRequest(ApiResponse<DistanceInfoDto>.ErrorResponse(ex.Message, ex.ErrorCode));
            }
            catch (Exception ex)
            {
                return BadRequest(ApiResponse<DistanceInfoDto>.ErrorResponse(ex.Message, ErrorCodes.DistanceCalculationFailed));
            }
        }

        /// <summary>
        /// Ręczne geokodowanie adresu klienta
        /// </summary>
        [HttpPost("geocode-my-address")]
        [Authorize(Roles = "client")]
        public async Task<ActionResult<ApiResponse>> GeocodeMyAddress()
        {
            try
            {
                var userId = Guid.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value!);
                var success = await _clientService.GeocodeClientAddressAsync(userId);

                if (!success)
                    return BadRequest(ApiResponse.ErrorResponse(
                        "Nie można zgeokodować adresu",
                        ErrorCodes.GeocodingFailed
                    ));

                return Ok(ApiResponse.SuccessResponse("Adres zgeokodowany pomyślnie"));
            }
            catch (Exception ex)
            {
                return BadRequest(ApiResponse.ErrorResponse(
                    ex.Message,
                    ErrorCodes.GeocodingFailed
                ));
            }
        }

        /// <summary>
        /// Pobiera współrzędne klienta
        /// </summary>
        [HttpGet("my-coordinates")]
        [Authorize(Roles = "client")]
        public async Task<ActionResult<ApiResponse<CoordinatesDto>>> GetMyCoordinates()
        {
            try
            {
                var userId = Guid.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value!);
                var coordinates = await _clientService.GetClientCoordinatesAsync(userId);

                if (!coordinates.HasValue)
                    return NotFound(ApiResponse<CoordinatesDto>.ErrorResponse(
                        "Brak współrzędnych dla klienta",
                        ErrorCodes.GeocodingFailed
                    ));

                return Ok(ApiResponse<CoordinatesDto>.SuccessResponse(new CoordinatesDto
                {
                    Latitude = coordinates.Value.Latitude,
                    Longitude = coordinates.Value.Longitude
                }));
            }
            catch (Exception ex)
            {
                return BadRequest(ApiResponse<CoordinatesDto>.ErrorResponse(
                    ex.Message,
                    ErrorCodes.GeocodingFailed
                ));
            }
        }

        /// <summary>
        /// Pobiera identyfikator klienta na podstawie identyfikatora użytkownika
        /// </summary>
        /// <param name="userId"></param>
        /// <returns></returns>
        /// <exception cref="KeyNotFoundException"></exception>
        private async Task<Guid> GetClientIdFromUserId(Guid userId)
        {
            var client = await _context.clients
                .FirstOrDefaultAsync(c => c.UserId == userId);
            return client?.Id ?? throw new KeyNotFoundException("Klient nie znaleziony");
        }
    }
}