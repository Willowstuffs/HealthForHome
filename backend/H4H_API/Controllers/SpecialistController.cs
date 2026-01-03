using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using H4H_API.Services.Interfaces;
using H4H_API.DTOs.Common;
using H4H_API.DTOs.Specialist;
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

            if(string.IsNullOrEmpty(userIdClaim))
            {
                return Unauthorized(ApiResponse<object>.ErrorResponse("Blad tokena: Brak identyfikatora uzytkownika."));
            }
            try
            {
                var userId = Guid.Parse(userIdClaim);
                //Nastepnie Pobieramy dane z serwisu
                var profile = await _specialistService.GetProfileAsync(userId);
                //i zwracamy odpowiedź w formacie ApiResponse
                return Ok(ApiResponse<SpecialistDto>.SuccessResponse(profile));
            }
            catch (KeyNotFoundException ex)
            {
                return NotFound(ApiResponse<object>.ErrorResponse(ex.Message));
            }
            catch (Exception ex)
            {
                return StatusCode(500, ApiResponse<object>.ErrorResponse("Wystapil nieoczekiwany blad serwera", new List<string> { ex.Message }));
            }
        }
    }
}
