using H4H_API.DTOs.Admin;
using H4H_API.DTOs.Appointments;
using H4H_API.DTOs.Common;
using H4H_API.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;
using H4H_API.Exceptions;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;

namespace H4H_API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Roles = "admin")]
    public class AdminController : ControllerBase
    {
        private readonly IAdminService _adminService;

        public AdminController(IAdminService adminService)
        {
            _adminService = adminService;
        }

        //duplikaty opisów w xml z AdminService
        /// <summary>
        /// Otrzymuje liste specjalistow z mozliwoscia filtrowania po statusie weryfikacji i dacie rejestracji,
        /// sortowania po dacie rejestracji oraz paginacji. Ta metoda jest przeznaczona dla administratorów do 
        /// przeglądania i zarządzania zgłoszeniami specjalistów oczekujących na weryfikację.</summary>
        /// <param name="filter">
        /// Obiekt zawierający opcje filtrowania, sortowania i paginacji do zastosowania przy wyborze specjalistów. Nie może być nullem.</param>
        /// <returns>
        /// Zwraca paged response zawierający listę specjalistów, którzy spełniają kryteria filtrowania, wraz z informacjami o paginacji 
        /// (aktualna strona, rozmiar strony, łączna liczba elementów).</returns>
        [HttpGet("specialists")]
        public async Task<ActionResult<ApiResponse<PagedResponse<AdminSpecialistListItemDto>>>> GetSpecialists([FromQuery] AdminSpecialistFilterDto filter)
        {
            var result = await _adminService.GetSpecialistsAsync(filter);
            return Ok(ApiResponse<PagedResponse<AdminSpecialistListItemDto>>.SuccessResponse(result));
        }

        /// <summary>
        /// Asynchronicznie pobiera szczegółowe informacje o specjaliście do celów administracyjnych, 
        /// w tym dane osobowe, informacje kontaktowe, status weryfikacji, oraz aktywne kwalifikacje.</summary>
        /// <remarks>
        /// Zwracane szczegóły obejmują zarówno podstawowy profil specjalisty, jak i jego aktywne kwalifikacje, 
        /// jeśli są dostępne. Pola dotyczące kwalifikacji mogą być nullem, jeśli specjalista nie posiada aktywnych kwalifikacji. 
        /// Ta metoda jest przeznaczona do użytku administracyjnego i może ujawniać wrażliwe informacje.</remarks>
        [HttpGet("specialists/{id}")]
        public async Task<ActionResult<ApiResponse<AdminSpecialistDetailsDto>>> GetSpecialistDetails(Guid id)
        {
            var result = await _adminService.GetSpecialistDetailsAsync(id);
            return Ok(ApiResponse<AdminSpecialistDetailsDto>.SuccessResponse(result));
        }

        /// <summary>Zatwierdza specjaliste aktualizując status weryfikacji i logując akcje wykonaną przez admina</summary>
        [HttpPost("specialists/{id}/approve")]
        public async Task<ActionResult<ApiResponse<object?>>> ApproveSpecialist(Guid id)
        {
            var adminIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(adminIdClaim))
                throw new UnauthorizedAccessException("Brak identyfikatora administratora w tokenie.");

            var adminId = Guid.Parse(adminIdClaim);

            await _adminService.ApproveSpecialistAsync(id, adminId);
            return Ok(ApiResponse<object?>.SuccessResponse(null, "Specjalista został zatwierdzony."));
        }

        /// <summary>Odrzuca specjaliste zmieniajac status weryfikacji na rejected i logujac akcje wykonana przez admina z powodem odrzucenia.</summary>
        [HttpPost("specialists/{id}/reject")]
        public async Task<ActionResult<ApiResponse<object?>>> RejectSpecialist(Guid id, [FromBody] RejectSpecialistDto dto)
        {
            var adminIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(adminIdClaim))
                throw new UnauthorizedAccessException("Brak identyfikatora administratora w tokenie.");

            var adminId = Guid.Parse(adminIdClaim);

            await _adminService.RejectSpecialistAsync(id, adminId, dto.Reason);
            return Ok(ApiResponse<object?>.SuccessResponse(null, "Specjalista został odrzucony."));
        }
        [HttpPut("specialists/{id}/license-validity")]
        public async Task<ActionResult<ApiResponse<object?>>> UpdateLicenseValidity(Guid id, [FromBody] UpdateLicenseValidityDto dto)
        {
            if (!dto.LicenseValidUntil.HasValue)
                throw new AppException("Data ważności licencji jest wymagana.", "INVALID_LICENSE_DATE");

            await _adminService.UpdateLicenseValidityAsync(id, dto.LicenseValidUntil.Value);

            return Ok(ApiResponse<object?>.SuccessResponse(null, "Data ważności licencji została zaktualizowana."));
        }


        /// <summary>
        /// Otrzymuje liste klientow z mozliwoscia filtrowania po dacie rejestracji, sortowania po dacie rejestracji oraz paginacji.
        /// </summary>
        /// <param name="filter"></param>
        /// <returns></returns>
        [HttpGet("clients")]
        public async Task<ActionResult<ApiResponse<PagedResponse<AdminClientListItemDto>>>> GetClients([FromQuery] AdminClientFilterDto filter)
        {
            var result = await _adminService.GetClientsAsync(filter);
            return Ok(ApiResponse<PagedResponse<AdminClientListItemDto>>.SuccessResponse(result));
        }

        /// <summary>
        /// Pobiera szczegółowe informacje o kliencie, w tym dane osobowe, informacje kontaktowe oraz historię wizyt.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [HttpGet("clients/{id}")]
        public async Task<ActionResult<ApiResponse<AdminClientDetailsDto>>> GetClientDetails(Guid id)
        {
            var result = await _adminService.GetClientDetailsAsync(id);
            return Ok(ApiResponse<AdminClientDetailsDto>.SuccessResponse(result));
        }

        /// <summary>
        /// Pobiera ogólne statystyki systemu dla głównego ekranu panelu administratora.
        /// </summary>
        [HttpGet("dashboard/stats")]
        public async Task<ActionResult<ApiResponse<AdminDashboardStatsDto>>> GetDashboardStats()
        {
            var result = await _adminService.GetDashboardStatsAsync();
            return Ok(ApiResponse<AdminDashboardStatsDto>.SuccessResponse(result));
        }

        /// <summary>
        /// Pobiera listę wszystkich wizyt w systemie z możliwością filtrowania i paginacji.
        /// </summary>
        [HttpGet("appointments")]
        public async Task<ActionResult<ApiResponse<PagedResponse<AdminAppointmentListItemDto>>>> GetAppointments([FromQuery] AdminAppointmentFilterDto filter)
        {
            var result = await _adminService.GetAppointmentsAsync(filter);
            return Ok(ApiResponse<PagedResponse<AdminAppointmentListItemDto>>.SuccessResponse(result));
        }
        /// <summary>
        /// Tworzy nową wizytę w systemie.
        /// </summary>
        [HttpPost("appointments")]
        public async Task<ActionResult<ApiResponse<object>>> CreateAppointment([FromBody] CreateAppointmentDto dto)
        {
            var appointmentId = await _adminService.CreateAppointmentAsync(dto);

            return Ok(ApiResponse<object>.SuccessResponse(new
            {
                appointmentId
            }, "Wizyta została utworzona."));
        }
        [HttpGet("appointments/{id}")]
        public async Task<ActionResult<ApiResponse<AdminAppointmentListItemDto>>> GetAppointment(Guid id)
        {
            var result = await _adminService.GetAppointmentByIdAsync(id);
            return Ok(ApiResponse<AdminAppointmentListItemDto>.SuccessResponse(result));
        }

    }
}