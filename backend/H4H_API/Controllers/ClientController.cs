using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using H4H_API.Services.Interfaces;
using H4H_API.DTOs.Common;
using H4H_API.DTOs.Client;


namespace H4H_API.Controllers
{
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
    }
}