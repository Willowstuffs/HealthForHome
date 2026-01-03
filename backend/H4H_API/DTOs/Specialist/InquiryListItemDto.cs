namespace H4H_API.DTOs.Specialist
{
    public class InquiryListItemDto
    {
        public Guid AppointmentId { get; set; }
        public DateTime ScheduledStart { get; set; }
        public DateTime ScheduledEnd { get; set; }
        public string PatientName { get; set; } = string.Empty;
        public string ServiceName { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty; // np. pending, accepted, rejected, completed
        public string PatientAddress { get; set; } = string.Empty;
        public decimal Price { get; set; }
    }
}
