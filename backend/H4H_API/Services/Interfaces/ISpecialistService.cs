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
    }
}
