using H4H_API.DTOs.Common;

namespace H4H_API.DTOs.Admin
{
    /// <summary>
    /// DTO dla filtrowania listy umówionych wizyt w panelu administratora, umożliwiający filtrowanie po statusie wizyty oraz zakresie dat.
    /// </summary>
    public class AdminAppointmentFilterDto : PagedRequest
    {
        public string? Status { get; set; } // np. 'pending', 'confirmed', 'cancelled'
        public DateTime? FromDate { get; set; }
        public DateTime? ToDate { get; set; }
    }
}