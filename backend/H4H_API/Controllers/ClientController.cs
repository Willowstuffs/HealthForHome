using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using H4H_API.Services.Interfaces;
using H4H_API.DTOs.Common;
using H4H_API.DTOs.Client;
using H4H_API.DTOs.Appointments;
using System.Security.Claims;


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

        public ClientController(IClientService clientService)
        {
            _clientService = clientService;
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
    }
}