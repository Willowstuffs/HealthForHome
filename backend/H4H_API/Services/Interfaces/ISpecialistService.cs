using H4H_API.DTOs.Specialist;
using H4H_API.DTOs.Client;


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
        /// <summary>
        /// Zmienia zasieg uslug specjalisty
        /// </summary>
        /// <param name="userId"></param>
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
        Task ConfirmAppointmentAsync(Guid userId, Guid appointmentId, List<Guid> serviceTypeIds, decimal price);
        /// <summary>
        /// Pobiera listę nadchodzących usług (inquiries) dla specjalisty z opcjonalnymi filtrami
        /// </summary>
        /// <param name="filters">Parametr tener zawiera opcjonalne filtry do zastosowania przy pobieraniu zapytań</param>
        Task<List<InquiryListItemDto>> GetCommingInquiriesAsync(Guid userId, InquiryFilterDto filters);
        /// <summary>
        /// Pobiera listę zakończonych usług (inquiries) dla specjalisty z opcjonalnymi filtrami
        /// </summary>
        /// <param name="filters">Parametr tener zawiera opcjonalne filtry do zastosowania przy pobieraniu zapytań</param>
        Task<List<InquiryListItemDto>> GetArchiveInquiriesAsync(Guid userId, InquiryFilterDto filters);
        /// <summary>
        /// Pozwala na edycje danych osobowych zdjęcia itd
        /// </summary>
        /// <param name="userId"> przyjmuje id urzytkownika</param>
        /// <param name="dto"> przyjmuje parametry do zmiany</param>
        /// <returns></returns>
        Task UpdateProfileAsync(Guid userId, UpdateSpecialistProfileDto dto);




        /// <summary>
        /// Pobiera publiczny profil specjalisty na podstawie ID specjalisty (nie użytkownika) - do wyświetlania dla klientów
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        Task<SpecialistProfileDto?> GetPublicProfileAsync(Guid id);
        Task<List<SpecialistOfferDto>> GetPublicServicesAsync(Guid id);
        Task<List<NearbySpecialistDto>> GetNearbySpecialistsAsync(double lat, double lng);

    }
}
