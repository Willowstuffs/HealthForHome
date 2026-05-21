namespace H4H_API.DTOs.Admin
{
    public class AdminAppointmentReviewDto
    {
        public Guid Id { get; set; }
        public int Rating { get; set; }
        public string? Comment { get; set; }
        public bool IsVerified { get; set; }
    }
}
