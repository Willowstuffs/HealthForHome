namespace H4H_API.DTOs.Specialist
{
    public class SpecialistProfileTruncatedDto
    {
        public Guid Id { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string? ProfessionalTitle { get; set; }
        public string? Bio { get; set; }
        public string? AvatarUrl { get; set; }
        public List<string> Qualifications { get; set; } = [];
        public List<ServiceAreaManageDto> Areas { get; set; } = [];
    }
}
