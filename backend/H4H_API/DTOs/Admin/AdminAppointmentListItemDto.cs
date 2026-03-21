namespace H4H_API.DTOs.Admin
{
    /// <summary>
    /// Reprezentuje pojedynczą pozycję na liście umówionych wizyt w panelu administratora, zawierającą kluczowe informacje o wizycie
    /// </summary>
    public class AdminAppointmentListItemDto
    {
        public Guid AppointmentId { get; set; }
        public string ContactName { get; set; } = string.Empty;
        public string ServiceName { get; set; } = string.Empty;
        public DateTime ScheduledStart { get; set; }
        public string Status { get; set; } = string.Empty;
        public decimal? TotalPrice { get; set; }
        public string? ClientAddress { get; set; }
        public string? ContactEmail { get; set; }
        public string? ContactPhoneNumber { get; set; }
        public string? ClientNotes { get; set; }
        public DateTime CreatedAt { get; set; }
        public string? SpecialistName { get; set; }
    }
}