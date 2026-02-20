namespace H4H_API.DTOs.Client
{
    public class ServiceRequestDto
    {
        public Guid Id { get; set; }
        public string ServiceTypeName { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public DateTime DateFrom { get; set; }
        public DateTime DateTo { get; set; }

        public decimal? MaxPrice { get; set; }
        public string Address { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }

        // Opcjonalnie dane kontaktowe, jeśli klient chce je widzieć w podglądzie
        public string? ContactName { get; set; }
    }
}
