using H4H_API.DTOs.Common;

namespace H4H_API.DTOs.Admin
{
    public class AdminSpecialistDetailsDto : AdminSpecialistListItemDto
    {
        public string? Bio { get; set; }
        public string? PhoneNumber { get; set; }
        public bool IsVerified { get; set; }

        public string? LicenseNumber { get; set; }
        public string? LicensePhotoUrl { get; set; }
        public string? IdCardPhotoUrl { get; set; }
        public string? VerificationNotes { get; set; }
        public DateTime? LicenseValidUntil { get; set; }
    }
}