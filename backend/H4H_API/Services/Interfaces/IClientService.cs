using H4H_API.DTOs.Appointments;
using H4H_API.Dtos.Client;
using H4H_API.DTOs.Client;
using H4H_API.DTOs.Common;
using H4H_API.DTOs.Specialist;
namespace H4H_API.Services.Interfaces
{
    public interface IClientService
    {
        // Zarządzanie profilem
        Task<ClientProfileDto> GetProfileAsync(Guid userId);
        Task<ClientProfileDto> UpdateProfileAsync(Guid userId, ClientUpdateDto dto);
        Task<bool> ChangePasswordAsync(Guid userId, string currentPassword, string newPassword);

        // Zarządzanie wizytami
        Task<PagedResponse<AppointmentDto>> GetAppointmentsAsync(Guid userId, PagedRequest request, string? status = null);
        Task<AppointmentDto> GetAppointmentDetailsAsync(Guid userId, Guid appointmentId);
        Task<AppointmentDto> CreateAppointmentAsync(Guid userId, CreateAppointmentDto dto);
        Task<bool> CancelAppointmentAsync(Guid userId, Guid appointmentId);

        // Wyszukiwanie specjalistów
        Task<PagedResponse<SpecialistDto>> SearchSpecialistsAsync(SearchSpecialistsDto filters, PagedRequest request);
    }
}