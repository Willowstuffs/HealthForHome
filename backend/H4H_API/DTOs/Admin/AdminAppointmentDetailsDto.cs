namespace H4H_API.DTOs.Admin
{
    public class AdminAppointmentDetailsDto
    {
        public Guid AppointmentId { get; set; }
        public string Status { get; set; } = string.Empty;
        public DateTime ScheduledStart { get; set; }
        public DateTime ScheduledEnd { get; set; }
        public DateTime CreatedAt { get; set; } //prosze Ania
        public decimal? TotalPrice { get; set; }
        public string? ClientNotes { get; set; }
        public string? ContactName { get; set; }
        public string? ContactPhone { get; set; }
        public string ServiceName { get; set; } = string.Empty;

        public AdminClientListItemDto? Client { get; set; }
        public AdminSpecialistListItemDto? Specialist { get; set; }
    }
}