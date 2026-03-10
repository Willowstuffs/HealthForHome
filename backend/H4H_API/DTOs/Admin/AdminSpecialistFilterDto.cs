using H4H_API.DTOs.Common;

namespace H4H_API.DTOs.Admin
{
    public class AdminSpecialistFilterDto : PagedRequest
    {
        public string? VerificationStatus { get; set; } // np. 'pending', 'approved', 'rejected'
        public DateTime? RegisteredFrom { get; set; }
        public DateTime? RegisteredTo { get; set; }
    }
}
