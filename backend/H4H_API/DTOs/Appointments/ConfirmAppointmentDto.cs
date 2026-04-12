namespace H4H_API.DTOs.Appointments
{
    public class ConfirmAppointmentDto
    {
        public List<Guid> ServiceTypeIds { get; set; } = new();
        public decimal Price { get; set; }
    }
}
