namespace H4H_API.DTOs.Appointments
{
    public class AppointmentOfferDto
    {
        public Guid SpecialistId { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public decimal? ProposedPrice { get; set; }
        public string? Bio { get; set; }
    }
}