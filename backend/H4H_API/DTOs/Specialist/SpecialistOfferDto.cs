namespace H4H_API.DTOs.Specialist
{
    public class SpecialistOfferDto
    {
        public Guid ServiceId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Category { get; set; } = string.Empty;
        public int DurationMinutes { get; set; }
        public decimal Price { get; set; }
        public string? Description { get; set; }
    }
}
