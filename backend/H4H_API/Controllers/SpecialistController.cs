using H4H_API.DTOs.Common;
using H4H_API.DTOs.Specialist;
using H4H_API.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace H4H_API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = "specialist")] //Wpuszcza tylko tych z rolą specjalisty
    public class SpecialistController : ControllerBase
    {
        private readonly ISpecialistService _specialistService;

        public SpecialistController(ISpecialistService specialistService)
        {
            _specialistService = specialistService;
        }

        /// <summary>
        /// Pobiera profil zalogowanego specjalisty
        /// GET: api/specialist/profile
        /// </summary>
        /// <remarks> Endpoint wymaga tokena JWT z rolą specialist.</remarks>
        /// <returns>ApiResponse z SpecialistDTO</returns>
        /// <response code="200">Zwraca profil specjalisty</response>
        /// <response code="401">Brak autoryzacji lub błędny token</response>
        [HttpGet("profile")]
        [ProducesResponseType(typeof(ApiResponse<SpecialistDto>), 200)]
        [ProducesResponseType(typeof(ApiResponse<object>), 401)]
        [ProducesResponseType(typeof(ApiResponse<object>), 404)]
        public async Task<ActionResult<ApiResponse<SpecialistDto>>> GetProfile()
        {
            // Najpierw wyciagamy id zalogowanego klienta z tokena
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userIdClaim))
            {
                return Unauthorized(ApiResponse<object>.ErrorResponse("Blad tokena: Brak identyfikatora uzytkownika."));
            }
            var userId = Guid.Parse(userIdClaim);
            //Nastepnie Pobieramy dane z serwisu
            var profile = await _specialistService.GetProfileAsync(userId);
            //i zwracamy odpowiedź w formacie ApiResponse
            return Ok(ApiResponse<SpecialistDto>.SuccessResponse(profile));
        }
        /// <summary>Pobiera listę zapytań dla zalogowanego specjalisty</summary>
        [HttpGet("inquiries")]
        [ProducesResponseType(typeof(ApiResponse<List<InquiryListItemDto>>), 200)]
        public async Task<ActionResult<ApiResponse<List<InquiryListItemDto>>>> GetInquiries([FromQuery] InquiryFilterDto filters)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim)) return Unauthorized(ApiResponse<object>.ErrorResponse("Błąd autoryzacji."));

            var userId = Guid.Parse(userIdClaim);
            var inquiries = await _specialistService.GetInquiriesAsync(userId, filters);

            return Ok(ApiResponse<List<InquiryListItemDto>>.SuccessResponse(inquiries, "Pobrano listę zapytań."));
        }
        /// <summary>
        /// Aktualizuje numer PWZ/licencji specjalisty
        /// </summary>
        [HttpPost("license")]
        public async Task<ActionResult<ApiResponse<object?>>> UpdateLicense([FromBody] string licenseNumber)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim)) return Unauthorized(ApiResponse<object>.ErrorResponse("Błąd autoryzacji."));

            var userId = Guid.Parse(userIdClaim);
            await _specialistService.UpdateLicenseNumberAsync(userId, licenseNumber);

            return Ok(ApiResponse<object?>.SuccessResponse(data: null, message: "Numer licencji został zapisany i oczekuje na weryfikację."));
        }
    }
}
