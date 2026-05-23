namespace H4H_API.DTOs.Appointments
{
    public class AppointmentOfferDto
    {
        public Guid SpecialistId { get; set; }
        public string? AvatarUrl { get; set; } = null;
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public decimal? ProposedPrice { get; set; }
        public DateTime ProposedDate { get; set; } // dodanie pola na propozycję pełnej daty (z godziną)
        public string? Bio { get; set; }
        public List<Guid> SelectedServiceIds { get; set; } = new();
        public List<string> SelectedServiceNames { get; set; } = new();
        public decimal SpecialistRating { get; set; }
        public int TotalReviews { get; set; }
    }
}