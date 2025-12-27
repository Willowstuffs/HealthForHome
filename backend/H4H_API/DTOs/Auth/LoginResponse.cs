namespace H4H_API.DTOs.Auth
{
    // Klasa odpowiedzi po udanym logowaniu
    public class LoginResponse
    {
        public string AccessToken { get; set; } = string.Empty;     // Token JWT do autoryzacji
        public string RefreshToken { get; set; } = string.Empty;    // Token do odświeżania sesji
        public DateTime AccessTokenExpires { get; set; }            // Data wygaśnięcia tokena dostępu
        public DateTime RefreshTokenExpires { get; set; }           // Data wygaśnięcia tokena odświeżającego
        public UserInfoDto User { get; set; } = null!;              // Informacje o zalogowanym użytkowniku
    }

    // DTO z informacjami o użytkowniku
    public class UserInfoDto
    {
        public Guid Id { get; set; }
        public string Email { get; set; } = string.Empty;
        public string UserType { get; set; } = string.Empty; // "client" lub "specialist"
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? PhoneNumber { get; set; }
        public string? AvatarUrl { get; set; }
    }
}