using H4H_API.DTOs.Appointments;
using H4H_API.DTOs.Common;
using H4H_API.DTOs.Specialist;
using H4H_API.Services.Implementations;
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

        /// <summary> Pobiera aktualny numer PWZ z systemu weryfikacji specjalisty </summary>
        [HttpGet("license")]
        public async Task<ActionResult<ApiResponse<string?>>> GetLicense()
        {
            var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value!);
            var license = await _specialistService.GetLicenseNumberAsync(userId);

            // Zwracamy null success, jeśli nie ma licencji (to nie błąd, po prostu jeszcze nie dodał)
            return Ok(ApiResponse<string?>.SuccessResponse(license, "Pobrano numer licencji."));
        }
        /// <summary>Pobiera listę usług wykonywanych przez specjalistę</summary>
        [HttpGet("services")]
        public async Task<ActionResult<ApiResponse<List<SpecialistServiceDto>>>> GetServices()
        {
            var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

            var services = await _specialistService.GetServicesAsync(userId);

            return Ok(ApiResponse<List<SpecialistServiceDto>>
                .SuccessResponse(services, "Pobrano usługi specjalisty."));
        }
        /// <summary>
        /// Pobiera listę wszystkich typów usług (słownikowych)
        /// </summary>
        [HttpGet("service-types")]
        [ProducesResponseType(typeof(ApiResponse<List<ServiceTypeDto>>), 200)]
        public async Task<ActionResult<ApiResponse<List<ServiceTypeDto>>>> GetServiceTypes()
        {
            var types = await _specialistService.GetServiceTypesAsync();
            return Ok(ApiResponse<List<ServiceTypeDto>>.SuccessResponse(types, "Pobrano listę typów usług."));
        }

        /// <summary>Dodaje nową usługę do oferty specjalisty</summary>
        /// <param name="dto">Parametr DTO zawierający dane usługi do dodania</param>
        [HttpPost("services")]
        public async Task<ActionResult<ApiResponse<object>>> AddService([FromBody] SpecialistServiceManageDto dto)
        {
            var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value!);
            await _specialistService.AddServiceAsync(userId, dto);
            return Ok(ApiResponse<object?>.SuccessResponse(null, "Usługa została dodana."));
        }

        /// <summary>Edytuje istniejącą usługę</summary>
        /// <param name="id">ID usługi (SpecialistServiceId)</param>
        [HttpPut("services/{id}")]
        public async Task<ActionResult<ApiResponse<object>>> UpdateService(Guid id, [FromBody] SpecialistServiceManageDto dto)
        {
            var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value!);
            await _specialistService.UpdateServiceAsync(userId, id, dto);
            return Ok(ApiResponse<object?>.SuccessResponse(null, "Usługa została zaktualizowana."));
        }

        /// <summary>Usuwa usługę z oferty.</summary>
        /// <param name="id">ID usługi</param>
        [HttpDelete("services/{id}")]
        public async Task<ActionResult<ApiResponse<object>>> DeleteService(Guid id)
        {
            var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value!);
            await _specialistService.DeleteServiceAsync(userId, id);
            return Ok(ApiResponse<object?>.SuccessResponse(null, "Usługa została usunięta."));
        }

        /// <summary>Ustawia główny obszar działania i zasięg dojazdu.</summary>
        [HttpPut("area")]
        public async Task<ActionResult<ApiResponse<object>>> UpdateArea([FromBody] ServiceAreaManageDto dto)
        {
            var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value!);
            await _specialistService.UpdateServiceAreaAsync(userId, dto);
            return Ok(ApiResponse<object?>.SuccessResponse(null, "Zasięg został zaktualizowany."));
        }

        /// <summary>Potwierdza oczekującą wizytę przez specjalistę. 
        /// !!! DO POPRAWIENIA GDY BEDZIE UPDATE BAZY !!!
        /// </summary>
        [HttpPatch("appointments/{id}/confirm")]
        public async Task<ActionResult<ApiResponse<object?>>> ConfirmAppointment(Guid id, [FromBody] ConfirmAppointmentDto dto)
        {
            var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value!);
            await _specialistService.ConfirmAppointmentAsync(userId, id, dto.ServiceTypeIds, dto.Price);
            return Ok(ApiResponse<object?>.SuccessResponse(null, "Wizyta została potwierdzona."));
        }

        /// <summary>Pobiera listę nadchodzących wizyt dla zalogowanego specjalisty</summary>
        [HttpGet("inquiries/comming")]
        [ProducesResponseType(typeof(ApiResponse<List<InquiryListItemDto>>), 200)]
        public async Task<ActionResult<ApiResponse<List<InquiryListItemDto>>>> GetCommingInquiries([FromQuery] InquiryFilterDto filters)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim)) return Unauthorized(ApiResponse<object>.ErrorResponse("Błąd autoryzacji."));

            var userId = Guid.Parse(userIdClaim);
            var inquiries = await _specialistService.GetCommingInquiriesAsync(userId, filters);

            return Ok(ApiResponse<List<InquiryListItemDto>>.SuccessResponse(inquiries, "Pobrano listę zapytań."));
        }
        /// <summary>Pobiera listę nadchodzących wizyt dla zalogowanego specjalisty</summary>
        [HttpGet("inquiries/archive")]
        [ProducesResponseType(typeof(ApiResponse<List<InquiryListItemDto>>), 200)]
        public async Task<ActionResult<ApiResponse<List<InquiryListItemDto>>>> GetArchiveInquiries([FromQuery] InquiryFilterDto filters)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim)) return Unauthorized(ApiResponse<object>.ErrorResponse("Błąd autoryzacji."));

            var userId = Guid.Parse(userIdClaim);
            var inquiries = await _specialistService.GetArchiveInquiriesAsync(userId, filters);

            return Ok(ApiResponse<List<InquiryListItemDto>>.SuccessResponse(inquiries, "Pobrano listę zapytań."));
        }
        
      
        /// <summary>
        /// Aktualizuje wszystkie dane profilu specjalisty
        /// </summary>
        [HttpPut("profile")]
        public async Task<ActionResult<ApiResponse<object>>> UpdateProfile([FromForm] UpdateSpecialistProfileDto dto)
        {
            var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value!);

            await _specialistService.UpdateProfileAsync(userId, dto);

            return Ok(ApiResponse<object?>
                .SuccessResponse(null, "Profil został zaktualizowany."));
        }

    }
}
