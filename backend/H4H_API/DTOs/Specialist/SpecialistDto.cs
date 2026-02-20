namespace H4H_API.DTOs.Specialist
{
    /// <summary>
    /// Represents a data transfer object containing profile and service information for a specialist.
    /// </summary>
    /// <remarks>This class is typically used to transfer specialist data between application layers or over
    /// service boundaries. It includes personal details, professional credentials, service offerings, and review
    /// statistics relevant to the specialist's public profile.</remarks>
    public class SpecialistDto
    {
        public Guid Id { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string? ProfessionalTitle { get; set; }
        public string? Bio { get; set; }
        public string Email { get; set; } = string.Empty;
        public string? PhoneNumber { get; set; }
        
        public decimal? HourlyRate { get; set; }
        public bool IsVerified { get; set; }
        /// <summary>Średnia ocen z tabeli reviews</summary>
        public decimal AverageRating { get; set; }
        public int TotalReviews { get; set; }
        public List<SpecialistServiceDto> Services { get; set; } = [];
        public List<ServiceAreaDto> ServiceAreas { get; set; } = [];
        public string? AvatarUrl { get; set; }

    }

    /// <summary>
    /// Represents a data transfer object for a specialist service, including details such as service name, category,
    /// duration, price, and description.
    /// </summary>
    /// <remarks>This class is typically used to transfer specialist service information between application
    /// layers or over network boundaries. It encapsulates the essential properties required to describe a service
    /// offered by a specialist, such as in scheduling or catalog scenarios.</remarks>
    public class SpecialistServiceDto
    {
        public Guid Id { get; set; }
        public string ServiceName { get; set; } = string.Empty;
        public string Category { get; set; } = string.Empty;
        public int DurationMinutes { get; set; }
        public Guid ServiceTypeId { get; set; }

        public decimal Price { get; set; }
        public string? Description { get; set; }
    }

    /// <summary>
    /// Represents a data transfer object that defines a service area, including city, postal code, maximum distance,
    /// and primary status.
    /// </summary>
    /// <remarks>Use this type to specify or retrieve information about a geographic area where a service is
    /// available. This DTO is typically used for data exchange between application layers or services.</remarks>
    public class ServiceAreaDto
    {
        public string City { get; set; } = string.Empty;
        public string? PostalCode { get; set; }
        public int MaxDistanceKm { get; set; }
        /// <summary>Czy to główny obszar działalności?</summary>
        public bool IsPrimary { get; set; }
    }
}

namespace H4H_API.DTOs.Specialist
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

//update danych specjalisty
public class UpdateSpecialistProfileDto
{
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;

    public string Email { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }

    public string? ProfessionalTitle { get; set; }
    public string? Bio { get; set; }
    public decimal? HourlyRate { get; set; }
    public IFormFile? Avatar { get; set; }
}

