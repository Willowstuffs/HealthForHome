namespace H4H_API.DTOs.Specialist
{
    /// <summary>
    /// Główny obiekt transferu danych reprezentujący profil specjalisty.
    /// Zawiera podstatowe informacje oraz listy usług i obszarów.
    /// </summary>
    public class SpecialistDto
    {
        public Guid Id { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string? ProfessionalTitle { get; set; }
        public string? Bio { get; set; }
        public decimal? HourlyRate { get; set; }
        public bool IsVerified { get; set; }
        /// <summary>Średnia ocen z tabeli reviews</summary>
        public decimal AverageRating { get; set; }
        public int TotalReviews { get; set; }
        public List<SpecialistServiceDto> Services { get; set; } = new();
        public List<ServiceAreaDto> ServiceAreas { get; set; } = new();
    }

    /// <summary>Reprezentuje pojedynczą usługę przypisaną do specjalisty</summary>
    public class SpecialistServiceDto
    {
        public Guid Id { get; set; }
        public string ServiceName { get; set; } = string.Empty;
        public string Category { get; set; } = string.Empty;
        public int DurationMinutes { get; set; }
        public decimal Price { get; set; }
        public string? Description { get; set; }
    }

    /// <summary>Obszar w którym specjalista przyjmuje lub dojeżdża.</summary>
    public class ServiceAreaDto
    {
        public string City { get; set; } = string.Empty;
        public string? PostalCode { get; set; }
        public int MaxDistanceKm { get; set; }
        /// <summary>Czy to główny obszar działalności?</summary>
        public bool IsPrimary { get; set; }
    }
}

namespace H4H_API.Dtos.Auth
{
    // TYMCZASOWY DTO dla rejestracji specjalisty
    public class SpecialistRegisterDto
    {
        // To tutaj moj kierownik zrobi pełną wersję
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
    }
}

namespace H4H_API.Dtos.Client
{
    // DTO do wyszukiwania specjalistów
    public class SearchSpecialistsDto
    {
        public string? City { get; set; }
        public string? Profession { get; set; } // "nurse" lub "physiotherapist"
        public string? ServiceType { get; set; }
        public decimal? MinRating { get; set; }
        public decimal? MaxPrice { get; set; }
        public DateTime? AvailableFrom { get; set; }
        public DateTime? AvailableTo { get; set; }
    }
}
