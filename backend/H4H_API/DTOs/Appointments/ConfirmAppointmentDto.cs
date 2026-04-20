namespace H4H_API.DTOs.Appointments
{
    public class ConfirmAppointmentDto
    {
        public List<Guid> ServiceTypeIds { get; set; } = new();
        public decimal Price { get; set; }
        public DateTime ProposedDate { get; set; } // dodanie pola na propozycję pełnej daty (z godziną) 
    }
}
