namespace H4H_API.DTOs.Admin
{
    /// <summary>
    /// DTO zawierający szczegółowe informacje o kliencie, w tym dane osobowe, informacje kontaktowe, datę rejestracji oraz listę wizyt klienta.
    /// </summary>
    public class AdminClientDetailsDto
    {
        public Guid ClientId { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string? PhoneNumber { get; set; }
        public DateTime CreatedAt { get; set; }

        // Lista wizyt klienta
        public List<AdminClientAppointmentDto> Appointments { get; set; } = new();
    }

    /// <summary>
    /// DTO reprezentujący pojedynczą wizytę klienta, zawierający informacje o dacie i godzinie wizyty, nazwie usługi, statusie oraz cenie.
    /// </summary>
    public class AdminClientAppointmentDto
    {
        public Guid AppointmentId { get; set; }
        public DateTime ScheduledStart { get; set; }
        public string ServiceName { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
        public decimal? Price { get; set; }
    }
}