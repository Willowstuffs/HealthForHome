namespace H4H_API.DTOs.Appointments
{
    /// <summary>
    /// Represents a request to rate a specialist for a completed appointment.
    /// </summary>
    public class RateSpecialistDto
    {
        /// <summary>
        /// Gets or sets the rating value (0-5 scale).
        /// </summary>
        public int Rating { get; set; }

        /// <summary>
        /// Gets or sets optional comment/review text.
        /// </summary>
        public string? Comment { get; set; }
    }
}
