namespace H4H_API.DTOs.Admin
{
    public class AdminSpecialistListItemDto
    {
        //Element listy specjalistów w panelu admina
        public Guid SpecialistId { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string ProfessionalTitle { get; set; } = string.Empty;
        public string VerificationStatus { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
    }
}
