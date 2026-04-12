namespace H4H_API.DTOs.Specialist
{
    public class SpecialistProfileDto
    {
        public Guid Id { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string? ProfessionalTitle { get; set; }
        public string? Bio { get; set; }
        public string? AvatarUrl { get; set; }
        public string? PhoneNumber { get; set; }
        public string? Profession { get; set; }
        public List<ServiceAreaManageDto> Areas { get; set; } = new ();
    }
}
