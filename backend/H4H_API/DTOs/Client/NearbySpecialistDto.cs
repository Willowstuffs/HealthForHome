namespace H4H_API.DTOs.Client
{
    public class NearbySpecialistDto
    {
        /// <summary>
        /// Wyszukiwany specjalista, który znajduje się w pobliżu klienta. Zawiera podstawowe informacje o specjaliście, takie jak imię, nazwisko, tytuł zawodowy, stawka godzinowa oraz odległość od klienta. Ten DTO jest używany do prezentacji listy specjalistów w pobliżu klienta, umożliwiając mu łatwe porównanie i wybór odpowiedniego specjalisty do umówienia wizyty.
        /// </summary>
        public Guid Id { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string? ProfessionalTitle { get; set; }
        public string? AvatarUrl { get; set; }
        public decimal HourlyRate { get; set; }
        public double DistanceKm { get; set; } // Dystans od klienta do punktu bazowego specjalisty
    }
}
