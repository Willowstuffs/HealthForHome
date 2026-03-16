using H4H_API.DTOs.Admin;
using H4H_API.DTOs.Common;

namespace H4H_API.Services.Interfaces
{
    public interface IAdminService
    {
        Task<PagedResponse<AdminSpecialistListItemDto>> GetSpecialistsAsync(AdminSpecialistFilterDto filter);
        Task<AdminSpecialistDetailsDto> GetSpecialistDetailsAsync(Guid specialistId);

        // Tymczasowo Guid adminId, dopóki nie wdrożymy JWT dla admina
        Task ApproveSpecialistAsync(Guid specialistId, Guid adminId);
        Task RejectSpecialistAsync(Guid specialistId, Guid adminId, string reason);


        Task<PagedResponse<AdminClientListItemDto>> GetClientsAsync(AdminClientFilterDto filter);
        Task<AdminClientDetailsDto> GetClientDetailsAsync(Guid clientId);
        Task<AdminDashboardStatsDto> GetDashboardStatsAsync();
        Task<PagedResponse<AdminAppointmentListItemDto>> GetAppointmentsAsync(AdminAppointmentFilterDto filter);
    }
}