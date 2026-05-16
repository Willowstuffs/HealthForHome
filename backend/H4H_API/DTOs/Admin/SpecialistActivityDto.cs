namespace H4H_API.DTOs.Admin
{
    public class SpecialistActivityDto
    {
        public Guid Id { get; set; }
        public string Type { get; set; } = string.Empty; // np. "appointment_created"
        public string Description { get; set; } = string.Empty; // np. "Dodano nowe zamówienie"
        public DateTime CreatedAt { get; set; }
    }
}
