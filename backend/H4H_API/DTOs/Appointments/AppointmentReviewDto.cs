namespace H4H_API.DTOs.Appointments
{
    public class AppointmentReviewDto
    {
        public Guid Id { get; set; }
        public Guid AppointmentId { get; set; }
        public Guid ClientId { get; set; }
        public Guid SpecialistId { get; set; }
        public int Rating { get; set; }
        public string? Comment { get; set; }
        public bool IsVerified { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
    }
}
