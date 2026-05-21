namespace H4H_API.DTOs.Client
{
    public class NearbySpecialistDto
    {
        /// <summary>
        /// Wyszukiwany specjalista, który znajduje się w pobliżu klienta.
        /// </summary>
        public Guid Id { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string? ProfessionalTitle { get; set; }
        public string? AvatarUrl { get; set; }
        public string ServiceArea { get; set; } = string.Empty;
        public double DistanceKm { get; set; }
        public List<string>? ServiceNames { get; set; } = [];
    }
}
