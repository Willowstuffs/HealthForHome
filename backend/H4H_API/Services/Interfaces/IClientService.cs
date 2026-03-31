using H4H_API.DTOs.Appointments;
using H4H_API.DTOs.Client;
using H4H_API.DTOs.Common;
using H4H_API.DTOs.Geolocation;
using H4H_API.DTOs.Specialist;

namespace H4H_API.Services.Interfaces
{
    public interface IClientService
    {
        // Zarządzanie profilem
        Task<ClientProfileDto> GetProfileAsync(Guid userId);
        Task<ClientProfileDto> UpdateProfileAsync(Guid userId, ClientUpdateDto dto);
        Task<bool> ChangePasswordAsync(Guid userId, string currentPassword, string newPassword);

        // Geolokalizacja
        Task<bool> GeocodeClientAddressAsync(Guid userId);
        Task<(double Latitude, double Longitude)?> GetClientCoordinatesAsync(Guid userId);
        Task<DistanceInfoDto> GetDistanceToServiceRequestAsync(Guid specialistId, Guid serviceRequestId);
        Task<bool> IsClientWithinSpecialistRangeAsync(Guid clientUserId, Guid specialistId);

        // Zarządzanie wizytami
        Task<PagedResponse<AppointmentDto>> GetAppointmentsAsync(Guid userId, PagedRequest request, string? status = null);
        Task<AppointmentDto> GetAppointmentDetailsAsync(Guid userId, Guid appointmentId);
        Task<AppointmentDto> CreateAppointmentAsync(Guid userId, CreateAppointmentDto dto);
        Task<bool> CancelAppointmentAsync(Guid userId, Guid appointmentId);

        // Wyszukiwanie specjalistów
        Task<PagedResponse<SpecialistDto>> SearchSpecialistsAsync(SearchSpecialistsDto filters, PagedRequest request);

        // Zarządzanie prośbami o usługę
        Task<Guid> CreateServiceRequestAsync(CreateServiceRequestDto dto, Guid? userId = null);
        Task<List<ServiceRequestDto>> GetMyServiceRequestsAsync(Guid userId);

        // Wyszukiwanie specjalistów na podstawie lokalizacji klienta
        Task<NetTopologySuite.Geometries.Point?> GetClientAddressPointAsync(Guid userId);
    }
}