using H4H_API.DTOs.Specialist;

namespace H4H_API.Services.Interfaces
{
    /// <summary>
    /// Interfejs z logiką dla modułu Specjalisty
    /// </summary>
    public interface ISpecialistService
    {
        /// <summary>
        /// Pobiera pełny profil specjalisty na podstawie ID użytkownika
        /// </summary>
        /// <param name="userId">GUID zalogowanego użytkownika (z tokena)</param>
        /// <returns>data transfer object z danymi profilu, usługami i obszarami</returns>
        Task<SpecialistDto> GetProfileAsync(Guid userId);
        /// <summary>
        /// Pobiera listę zapytań (inquiries) dla specjalisty z opcjonalnymi filtrami
        /// </summary>
        /// <param name="filters">Parametr tener zawiera opcjonalne filtry do zastosowania przy pobieraniu zapytań</param>
        Task<List<InquiryListItemDto>> GetInquiriesAsync(Guid userId, InquiryFilterDto filters);
        /// <summary>Update numeru pozwolenia wykonywania zawodu specjalisty</summary>
        Task UpdateLicenseNumberAsync(Guid userId, string licenseNumber);
        /// <summary>Pobiera informacje o numerze PWZ do autoryzacji specjalisty</summary>
        Task<string?> GetLicenseNumberAsync(Guid userId);

        /// <summary>Dodaje usluge specjalisty</summary>
        /// <param name="dto">Obiekt DTO z danymi usługi do dodania</param>
        Task AddServiceAsync(Guid userId, SpecialistServiceManageDto dto);
        /// <summary>Aktualizuje usluge specjalisty</summary>
        Task UpdateServiceAsync(Guid userId, Guid serviceId, SpecialistServiceManageDto dto);
        /// <summary>Usuwa usluge specjalisty</summary>
        Task DeleteServiceAsync(Guid userId, Guid serviceId);
        /// <summary>Zmienia zasieg uslug specjalisty</summary>
        /// <param name="dto">Obiekt DTO z danymi zasiegu do ustawienia</param>
        Task UpdateServiceAreaAsync(Guid userId, ServiceAreaManageDto dto);
        /// <summary>
        /// Pobiera listę usług specjalisty
        /// </summary>
        /// <param name="userId"></param>
        /// <returns></returns>
        Task<List<SpecialistServiceDto>> GetServicesAsync(Guid userId);
        /// <summary>
        /// pobieranie listy typów-usług
        /// </summary>
        /// <returns></returns>
        Task<List<ServiceTypeDto>> GetServiceTypesAsync();
        /// <summary>Zmienia status wizyty u specjalisty na potwierdzony (confirmed)</summary>
        Task ConfirmAppointmentAsync(Guid userId, Guid appointmentId);
    }
}
