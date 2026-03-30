using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using H4H_API.Services.Interfaces;
using H4H_API.DTOs.Common;
using H4H_API.DTOs.Client;
using H4H_API.DTOs.Appointments;
using System.Security.Claims;
using H4H_API.DTOs.Specialist;
using H4H_API.Helpers;
using Microsoft.EntityFrameworkCore;
using H4H_API.Services.Implementations;



namespace H4H_API.Controllers
{
    /// <summary>
    /// Represents an API controller that manages client-specific operations for authenticated users with the "client"
    /// role.
    /// </summary>
    /// <remarks>This controller provides endpoints for retrieving and updating the profile of the currently
    /// authenticated client. Access to all actions is restricted to users assigned the "client" role. The controller
    /// relies on dependency injection of an implementation of <see cref="IClientService"/> to perform business logic
    /// related to client profiles.</remarks>
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = "client")] // Dostęp tylko dla użytkowników z rolą "client"
    public class ClientController : ControllerBase
    {
        private readonly IClientService _clientService;
        private readonly ISpecialistService _specialistService;
        private readonly IGeocoder _geocoder;

        public ClientController(IClientService clientService, ISpecialistService specialistService, IGeocoder geocoder)
        {
            _clientService = clientService;
            _specialistService = specialistService;
            _geocoder = geocoder; 
        }

        // Pobiera profil zalogowanego klienta
        [HttpGet("profile")]
        public async Task<ActionResult<ApiResponse<ClientProfileDto>>> GetProfile()
        {
            // Pobierz ID użytkownika z tokena JWT
            var userId = Guid.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value!);
            var profile = await _clientService.GetProfileAsync(userId);
            return Ok(ApiResponse<ClientProfileDto>.SuccessResponse(profile));
        }

        // Aktualizuje profil klienta
        [HttpPut("profile")]
        public async Task<ActionResult<ApiResponse<ClientProfileDto>>> UpdateProfile([FromBody] ClientUpdateDto dto)
        {
            var userId = Guid.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value!);
            var updatedProfile = await _clientService.UpdateProfileAsync(userId, dto);
            return Ok(ApiResponse<ClientProfileDto>.SuccessResponse(updatedProfile, "Profil zaktualizowany"));
        }

        // Pobiera listę wizyt klienta z opcjonalnym filtrowaniem po statusie
        [HttpGet("appointments")]
        public async Task<IActionResult> GetAppointments([FromQuery] PagedRequest request, [FromQuery] string? status)
        {
            var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value!);
            var result = await _clientService.GetAppointmentsAsync(userId, request, status);
            return Ok(ApiResponse<PagedResponse<AppointmentDto>>.SuccessResponse(result));
        }

        // Pobiera szczegóły konkretnej wizyty
        [HttpGet("appointments/{id}")]
        public async Task<ActionResult<ApiResponse<AppointmentDto>>> GetDetails(Guid id)
        {
            var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value!);
            var result = await _clientService.GetAppointmentDetailsAsync(userId, id);
            return Ok(ApiResponse<AppointmentDto>.SuccessResponse(result));
        }

        // Anuluje wizytę
        [HttpPost("appointments/{id}/cancel")]
        public async Task<ActionResult<ApiResponse>> Cancel(Guid id)
        {
            var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value!);
            var success = await _clientService.CancelAppointmentAsync(userId, id);

            if (success)
                return Ok(ApiResponse.SuccessResponse("Wizyta została anulowana"));

            return BadRequest(ApiResponse.ErrorResponse("Nie można anulować tej wizyty"));
        }

        // Tworzy nową prośbę o usługę (ogłoszenie) - dostępne również dla gości (niezalogowanych)
        [HttpPost("service-requests")]
        [AllowAnonymous] // Pozwala gościom dodawać ogłoszenia (bez tokena JWT)
        public async Task<ActionResult<ApiResponse<Guid>>> CreateRequest([FromBody] CreateServiceRequestDto dto)
        {
            // Jeśli token jest przesłany, wyciągamy userId, jeśli nie - null
            Guid? userId = null;
            var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;

            if (!string.IsNullOrEmpty(userIdClaim))
            {
                userId = Guid.Parse(userIdClaim);
            }

            var requestId = await _clientService.CreateServiceRequestAsync(dto, userId);
            return Ok(ApiResponse<Guid>.SuccessResponse(requestId));
        }

        // Pobiera listę ogłoszeń (prośb o usługę) utworzonych przez zalogowanego klienta.
        [HttpGet("service-requests")]
        public async Task<ActionResult<ApiResponse<List<ServiceRequestDto>>>> GetMyRequests()
        {
            var userId = Guid.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value!);
            var requests = await _clientService.GetMyServiceRequestsAsync(userId);
            return Ok(ApiResponse<List<ServiceRequestDto>>.SuccessResponse(requests));
        }




        /// <summary>
        /// Pobiera profil specjalisty (widok dla klienta)
        /// </summary>
        [HttpGet("specialist/{id}/profile")]
        [AllowAnonymous] //TODO: poprawić aby tylko zalogowani klienci mogli widzieć profil specjalisty (nie dla gości)
        public async Task<ActionResult<ApiResponse<SpecialistProfileDto>>> GetSpecialistProfile(Guid id)
        {
            var profile = await _specialistService.GetPublicProfileAsync(id); // Używamy poprawionej metody z poprzedniego kroku
            if (profile == null)
                return NotFound(ApiResponse<SpecialistProfileDto>.ErrorResponse("Specjalista nie istnieje"));

            return Ok(ApiResponse<SpecialistProfileDto>.SuccessResponse(profile));
        }

        /// <summary>
        /// Pobiera ofertę specjalisty (widok dla klienta)
        /// </summary>
        [HttpGet("specialist/{id}/full-offer")]
        [AllowAnonymous] //TODO: poprawić aby tylko zalogowani klienci mogli widzieć pełną ofertę (nie dla gości)
        public async Task<ActionResult<ApiResponse<List<SpecialistOfferDto>>>> GetSpecialistOffer(Guid id)
        {
            var services = await _specialistService.GetPublicServicesAsync(id);

            return Ok(ApiResponse<List<SpecialistOfferDto>>.SuccessResponse(services));
        }

        /// <summary>
        /// Pobiera specjalistów, którzy obsługują lokalizację klienta
        /// </summary>
        /// <param name="lat">Szerokość geograficzna klienta</param>
        /// <param name="lng">Długość geograficzna klienta</param>
        [HttpGet("specialists/nearby")]
        public async Task<ActionResult<ApiResponse<List<NearbySpecialistDto>>>> GetNearbySpecialists(
                [FromQuery] double lat,
                [FromQuery] double lng)
        {
            // Tutaj walidacja współrzędnych
            if (lat == 0 && lng == 0)
            {
                return BadRequest(ApiResponse<List<NearbySpecialistDto>>.ErrorResponse(
                    "Nieprawidłowe współrzędne", ErrorCodes.InvalidCoordinates));
            }

            var specialists = await _specialistService.GetNearbySpecialistsAsync(lat, lng);
            return Ok(ApiResponse<List<NearbySpecialistDto>>.SuccessResponse(specialists));
        }

        /// <summary>
        /// Pobiera specjalistów, którzy obsługują lokalizację klienta na podstawie adresu ustawionego w profilu klienta
        /// </summary>
        /// <returns></returns>
        [HttpGet("specialists/nearby/my-address")]
        public async Task<ActionResult<ApiResponse<List<NearbySpecialistDto>>>> GetNearbyMyAddress()
        {
            var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value!);

            // Pobieramy punkt geograficzny (współrzędne) na podstawie adresu ustawionego w profilu klienta
            var addressPoint = await _clientService.GetClientAddressPointAsync(userId);

            // Jeśli klient nie ma ustawionego adresu lub nie można go geokodować, zwracamy błąd
            if (addressPoint == null)
            {
                return BadRequest(ApiResponse<List<NearbySpecialistDto>>.ErrorResponse(
                    "Brak zapisanego adresu w profilu", ErrorCodes.AddressNotFound)); 
            }

            var specialists = await _specialistService.GetNearbySpecialistsAsync(
                addressPoint.Y, // Latitude
                addressPoint.X  // Longitude
            );

            return Ok(ApiResponse<List<NearbySpecialistDto>>.SuccessResponse(specialists));
        }

        /// <summary>
        /// Pobiera specjalistów, którzy obsługują lokalizację klienta na podstawie tekstowego adresu podanego w zapytaniu
        /// </summary>
        /// <param name="address"></param>
        /// <returns></returns>
        [HttpGet("specialists/nearby/by-address-text")]
        public async Task<ActionResult<ApiResponse<List<NearbySpecialistDto>>>> GetNearbyByAddressText([FromQuery] string address)
        {
            if (string.IsNullOrWhiteSpace(address))
            {
                return BadRequest(ApiResponse<List<NearbySpecialistDto>>.ErrorResponse(
                    "Adres nie może być pusty", ErrorCodes.ValidationError));
            }

            // 1. Używamy serwisu geokodowania, aby przekształcić tekstowy adres na współrzędne geograficzne
            var geocodeResult = await _geocoder.GeocodeAddressAsync(address);

            if (geocodeResult == null)
            {
                return NotFound(ApiResponse<List<NearbySpecialistDto>>.ErrorResponse(
                    "Nie udało się odnaleźć podanego adresu", ErrorCodes.AddressNotFound)); 
            }

            // 2. Szukamy specjalistów w tych współrzędnych
            var specialists = await _specialistService.GetNearbySpecialistsAsync(
                geocodeResult.Latitude,
                geocodeResult.Longitude
            );

            return Ok(ApiResponse<List<NearbySpecialistDto>>.SuccessResponse(specialists));
        }
    }
}