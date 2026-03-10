namespace H4H_API.DTOs.Auth
{
    /// <summary>
    /// Represents the response returned after a successful user login, including authentication tokens and user
    /// information.
    /// </summary>
    /// <remarks>This class contains the access and refresh tokens required for authenticated API requests,
    /// along with their expiration times and details about the authenticated user. The tokens should be securely stored
    /// and used according to best practices for authentication and session management.</remarks>
    public class LoginResponse
    {
        public string AccessToken { get; set; } = string.Empty;     // Token JWT do autoryzacji
        public string RefreshToken { get; set; } = string.Empty;    // Token do odświeżania sesji
        public DateTime AccessTokenExpires { get; set; }            // Data wygaśnięcia tokena dostępu
        public DateTime RefreshTokenExpires { get; set; }           // Data wygaśnięcia tokena odświeżającego
        public UserInfoDto User { get; set; } = null!;              // Informacje o zalogowanym użytkowniku
    }

    /// <summary>
    /// Represents user profile information for data transfer between application layers or services.
    /// </summary>
    /// <remarks>This data transfer object (DTO) is typically used to encapsulate user details such as
    /// identifiers, contact information, and user type for operations like authentication, authorization, or user
    /// management. The class is intended for use in scenarios where exposing only essential user data is required,
    /// rather than the full domain model.</remarks>
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