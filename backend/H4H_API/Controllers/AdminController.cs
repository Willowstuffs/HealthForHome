using H4H_API.DTOs.Admin;
using H4H_API.DTOs.Common;
using H4H_API.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;

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
            var userId = Guid.Parse(
                User.FindFirstValue(ClaimTypes.NameIdentifier)!
            );

            await _adminService.ApproveSpecialistAsync(id, userId);

            return Ok(ApiResponse<object?>.SuccessResponse(
                null,
                "Specjalista został zatwierdzony."
            ));
        }

        /// <summary>Odrzuca specjaliste zmieniajac status weryfikacji na rejected i logujac akcje wykonana przez admina z powodem odrzucenia.</summary>
        [HttpPost("specialists/{id}/reject")]
        public async Task<ActionResult<ApiResponse<object?>>> RejectSpecialist(Guid id, [FromBody] RejectSpecialistDto dto)
        {
            var userId = Guid.Parse(
               User.FindFirstValue(ClaimTypes.NameIdentifier)!
            );


            await _adminService.RejectSpecialistAsync(id, userId, dto.Reason);
            return Ok(ApiResponse<object?>.SuccessResponse(null, "Specjalista został odrzucony."));
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

        /// <summary>Zapisuje datę ważności licencji specjalisty</summary>
        [HttpPut("specialists/{id}/license-validity")]
        public async Task<IActionResult> UpdateLicenseValidity(Guid id, [FromBody] UpdateLicenseDto dto)
        {
            await _adminService.UpdateLicenseValidityAsync(id, dto.ValidUntil);
            return Ok(ApiResponse<object?>.SuccessResponse(null, "Data ważności licencji została zaktualizowana."));
        }

        /// <summary>Zawieszenie konta specjalisty</summary>
        [HttpPost("specialists/{id}/suspend")]
        public async Task<IActionResult> SuspendSpecialist(Guid id)
        {
            await _adminService.SuspendSpecialistAsync(id);
            return Ok(ApiResponse<object?>.SuccessResponse(null, "Konto specjalisty zostało zawieszone."));
        }

        /// <summary>Odwieszenie konta specjalisty</summary>
        [HttpPost("specialists/{id}/unsuspend")]
        public async Task<IActionResult> UnsuspendSpecialist(Guid id)
        {
            await _adminService.UnsuspendSpecialistAsync(id);
            return Ok(ApiResponse<object?>.SuccessResponse(null, "Konto specjalisty zostało odwieszone."));
        }

        /// <summary>Pobiera szczegóły zamówienia/wizyty</summary>
        [HttpGet("appointments/{id}")]
        public async Task<ActionResult<AdminAppointmentDetailsDto>> GetAppointmentDetails(Guid id)
        {
            var details = await _adminService.GetAppointmentDetailsAsync(id);
            return Ok(details);
        }
    }
}