namespace H4H_API.DTOs.Appointments
{
    /// <summary>
    /// DTO do oceny klienta po zakończonej wizycie. Zawiera ocenę (good, neutral, bad) oraz opcjonalny komentarz.
    /// </summary>
    public class RateClientDto
    {
        public string Rating { get; set; } = string.Empty; // "good", "neutral", "bad"
        public string? Comment { get; set; }
    }
}
