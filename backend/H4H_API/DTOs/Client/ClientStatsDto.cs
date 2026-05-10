namespace H4H_API.DTOs.Client
{
    /// <summary>
    /// DTO do zwrotu statystyk klienta, takich jak liczba pozytywnych, neutralnych i negatywnych opinii.
    /// </summary>
    public class ClientStatsDto
    {
        public int GoodCount { get; set; }
        public int NeutralCount { get; set; }
        public int BadCount { get; set; }
    }
}