using H4H.Core.Models;

namespace H4H_API.Services.Interfaces
{
    public interface IJwtService
    {
        // Generuje token dostępu (JWT) dla użytkownika
        string GenerateAccessToken(User user);
        string GenerateRefreshToken();
        // Weryfikuje token i zwraca ID użytkownika jeśli token jest poprawny
        Guid? ValidateToken(string token);
        Task<bool> IsTokenRevoked(string token);
        Task RevokeToken(string token);
    }
}
