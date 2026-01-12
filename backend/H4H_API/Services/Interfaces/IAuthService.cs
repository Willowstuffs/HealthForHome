using H4H_API.Dtos.Auth;
using H4H_API.DTOs.Auth;
using H4H_API.DTOs.Client;
using H4H_API.DTOs.Specialist;

namespace H4H_API.Services.Interfaces
{
    // Interfejs serwisu uwierzytelniania
    public interface IAuthService
    {
        Task<LoginResponse> LoginAsync(LoginRequest request);
        Task<RegisterResponse> RegisterClientAsync(ClientRegisterDto request);
        Task<RegisterResponse> RegisterSpecialistAsync(SpecialistRegisterDto request); // Tymczasowe
        Task<LoginResponse> RefreshTokenAsync(RefreshTokenRequest request);
        Task<bool> LogoutAsync(string accessToken);
        Task<bool> ChangePasswordAsync(Guid userId, string currentPassword, string newPassword);
        Task<bool> RequestPasswordResetAsync(string email);
        Task<bool> ResetPasswordAsync(string token, string newPassword);
    }
}
