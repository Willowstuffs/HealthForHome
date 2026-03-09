using H4H_API.DTOs.Admin;
using H4H_API.DTOs.Common;
using H4H_API.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;

namespace H4H_API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Roles = "admin")]
    // TODO: Dodać [Authorize(Roles = "admin")] gdy wdrożymy JWT dla admina
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
            // Tymczasowo generujemy fake'owy Guid dla admina na potrzeby testów postman/swagger
            var tempAdminId = Guid.NewGuid();

            await _adminService.ApproveSpecialistAsync(id, tempAdminId);
            return Ok(ApiResponse<object?>.SuccessResponse(null, "Specjalista został zatwierdzony."));
        }


        /// <summary>Odrzuca specjaliste zmieniajac status weryfikacji na rejected i logujac akcje wykonana przez admina z powodem odrzucenia.</summary>
        [HttpPost("specialists/{id}/reject")]
        public async Task<ActionResult<ApiResponse<object?>>> RejectSpecialist(Guid id, [FromBody] RejectSpecialistDto dto)
        {
            var tempAdminId = Guid.NewGuid();

            await _adminService.RejectSpecialistAsync(id, tempAdminId, dto.Reason);
            return Ok(ApiResponse<object?>.SuccessResponse(null, "Specjalista został odrzucony."));
        }
        /// <summary>Zawiesza specjalistę (blokuje możliwość przyjmowania zleceń)</summary>
        [HttpPost("specialists/{id}/suspend")]
        public async Task<ActionResult<ApiResponse<object?>>> SuspendSpecialist(Guid id)
        {
            var tempAdminId = Guid.NewGuid();

            await _adminService.SuspendSpecialistAsync(id, tempAdminId);

            return Ok(ApiResponse<object?>.SuccessResponse(null, "Specjalista został zawieszony."));
        }

        /// <summary>Przywraca zawieszonego specjalistę</summary>
        [HttpPost("specialists/{id}/unsuspend")]
        public async Task<ActionResult<ApiResponse<object?>>> UnsuspendSpecialist(Guid id)
        {
            var tempAdminId = Guid.NewGuid();

            await _adminService.UnsuspendSpecialistAsync(id, tempAdminId);

            return Ok(ApiResponse<object?>.SuccessResponse(null, "Specjalista został odwieszony."));
        }
        [HttpPut("specialists/{id}/license-validity")]
        public async Task<ActionResult<ApiResponse<object?>>> UpdateLicenseValidity(
            Guid id,
            [FromBody] UpdateLicenseValidityDto dto)
        {
            await _adminService.UpdateLicenseValidityAsync(id, dto.LicenseValidUntil);
            return Ok(ApiResponse<object?>.SuccessResponse(null, "Data ważności licencji została zapisana."));
        }

    }
}