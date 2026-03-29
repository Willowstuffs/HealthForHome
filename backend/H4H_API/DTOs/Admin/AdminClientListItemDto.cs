namespace H4H_API.DTOs.Admin
{
    public class AdminClientListItemDto
    {
        // Element listy klientów w panelu admina
        public Guid ClientId { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public int TotalAppointments { get; set; }
    }
}
