namespace H4H_API.DTOs.Auth
{
    /// <summary>
    /// Represents a request to obtain a new access token using an existing refresh token.
    /// </summary>
    public class RefreshTokenRequest
    {
        public string AccessToken { get; set; } = string.Empty;
        public string RefreshToken { get; set; } = string.Empty;
    }
}
