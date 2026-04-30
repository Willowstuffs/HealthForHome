using H4H_API.DTOs.Common;

namespace H4H_API.DTOs.Admin
{
    // Szczegóły specjalisty (wraz z danymi weryfikacyjnymi)
    public class AdminSpecialistDetailsDto : AdminSpecialistListItemDto
    {
        public string? Bio { get; set; }
        public string? PhoneNumber { get; set; }
        public bool IsVerified { get; set; }
        public List<AdminClientAppointmentDto> Appointments { get; set; } = new();
        public List<AdminClientListItemDto> AcceptedClients { get; set; } = new(); // Lub inne pasujące DTO
        public List<SpecialistActivityDto> Activities { get; set; } = new();

        // Dane z tabeli specialist_qualifications
        public string? LicenseNumber { get; set; }
        public string? LicensePhotoUrl { get; set; }
        public string? IdCardPhotoUrl { get; set; }
        public string? VerificationNotes { get; set; }
    }
}
