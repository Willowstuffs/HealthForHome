namespace H4H_API.DTOs.Auth
{
    // Proste DTO do żądania odświeżenia tokena
    public class RefreshTokenRequest
    {
        public string AccessToken { get; set; } = string.Empty;
        public string RefreshToken { get; set; } = string.Empty;
    }
}
