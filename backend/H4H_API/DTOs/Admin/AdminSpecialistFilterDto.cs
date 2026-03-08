using H4H_API.DTOs.Common;

namespace H4H_API.DTOs.Admin
{
    public class AdminSpecialistFilterDto : PagedRequest
    {
        public string? VerificationStatus { get; set; }
        public string? Specialization { get; set; }
        public DateTime? RegisteredFrom { get; set; }
        public DateTime? RegisteredTo { get; set; }
        public bool SortDescending { get; set; } = true;
    }
}