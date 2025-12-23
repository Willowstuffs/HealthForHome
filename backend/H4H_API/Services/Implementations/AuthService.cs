using H4H_API.DTOs.Auth;
using H4H.Core.Models;
using H4H_API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using H4H.Data;
using H4H_API.DTOs.Client;
using H4H_API.Dtos.Auth;
using H4H_API.DTOs.Specialist;

namespace H4H_API.Services.Implementations
{
    public class AuthService : IAuthService
    {
        private readonly ApplicationDbContext _context;
        private readonly IJwtService _jwtService;

        public AuthService(ApplicationDbContext context, IJwtService jwtService)
        {
            _context = context;
            _jwtService = jwtService;
        }

        public async Task<LoginResponse> LoginAsync(LoginRequest request)
        {
            // Pobierz użytkownika z bazy danych wraz z powiązanymi danymi klienta/specjalisty
            var user = await _context.users
                .Include(u => u.Client)
                .Include(u => u.Specialist)
                .FirstOrDefaultAsync(u => u.Email == request.Email && u.IsActive);

            // Sprawdź czy użytkownik istnieje i czy hasło jest poprawne
            if (user == null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
                throw new UnauthorizedAccessException("Nieprawidłowy email lub hasło");

            // Aktualizuj last login
            user.LastLoginAt = DateTime.Now;
            await _context.SaveChangesAsync();

            // Generuj tokeny
            var accessToken = _jwtService.GenerateAccessToken(user);
            var refreshToken = _jwtService.GenerateRefreshToken();

            // TODO: Zapisz refresh token do bazy (do implementacji

            // Przygotuj informacje o użytkowniku do odpowiedzi
            var userInfo = new UserInfoDto
            {
                Id = user.Id,
                Email = user.Email,
                UserType = user.UserType, // "client" lub "specialist"
                PhoneNumber = user.PhoneNumber,
                AvatarUrl = user.AvatarUrl
            };

            // Pobierz imię i nazwisko w zależności od typu użytkownika
            if (user.UserType == "client" && user.Client != null)
            {
                userInfo.FirstName = user.Client.FirstName;
                userInfo.LastName = user.Client.LastName;
            }
            else if (user.UserType == "specialist" && user.Specialist != null)
            {
                userInfo.FirstName = user.Specialist.FirstName;
                userInfo.LastName = user.Specialist.LastName;
            }

            // Zwróć odpowiedź z tokenami i danymi użytkownika
            return new LoginResponse
            {
                AccessToken = accessToken,
                RefreshToken = refreshToken,
                AccessTokenExpires = DateTime.Now.AddMinutes(15), // Token dostępowy ważny 15 minut
                RefreshTokenExpires = DateTime.Now.AddDays(7), // Token odświeżający ważny 7 dni
                User = userInfo
            };
        }

        public async Task<RegisterResponse> RegisterClientAsync(ClientRegisterDto request)
        {
            // Sprawdź czy email już istnieje
            if (await _context.users.AnyAsync(u => u.Email == request.Email))
                throw new ArgumentException("Użytkownik o podanym emailu już istnieje");

            // Utwórz użytkownika
            var user = new User
            {
                Id = Guid.NewGuid(),
                Email = request.Email,
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
                UserType = "client",
                PhoneNumber = request.PhoneNumber,
                IsActive = true,
                CreatedAt = DateTime.Now,
                UpdatedAt = DateTime.Now
            };

            _context.users.Add(user);

            // Utwórz klienta
            var client = new Client
            {
                Id = Guid.NewGuid(),
                UserId = user.Id,
                FirstName = request.FirstName,
                LastName = request.LastName,
                DateOfBirth = request.DateOfBirth,
                Address = request.Address,
                EmergencyContact = request.EmergencyContact,
                CreatedAt = DateTime.Now
            };

            _context.clients.Add(client);

            await _context.SaveChangesAsync();

            return new RegisterResponse
            {
                Message = "Rejestracja zakończona sukcesem. Sprawdź email w celu weryfikacji.",
                UserId = user.Id,
                RequiresEmailVerification = true
            };
        }

        public async Task<RegisterResponse> RegisterSpecialistAsync(SpecialistRegisterDto request)
        {
            // PODSTAWOWA IMPLEMENTACJA - DRUGA OSOBA ROZWINIE
            if (await _context.users.AnyAsync(u => u.Email == request.Email))
                throw new ArgumentException("Użytkownik o podanym emailu już istnieje");

            // Utwórz użytkownika
            var user = new User
            {
                Id = Guid.NewGuid(),
                Email = request.Email,
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
                UserType = "specialist",
                IsActive = true,
                CreatedAt = DateTime.Now,
                UpdatedAt = DateTime.Now
            };

            _context.users.Add(user);

            // Utwórz specjalistę (tylko podstawowe dane)
            var specialist = new Specialist
            {
                Id = Guid.NewGuid(),
                UserId = user.Id,
                FirstName = request.FirstName,
                LastName = request.LastName,
                IsVerified = false,
                VerificationStatus = "pending",
                AverageRating = 0,
                TotalReviews = 0,
                CreatedAt = DateTime.Now
            };

            _context.specialists.Add(specialist);

            await _context.SaveChangesAsync();

            return new RegisterResponse
            {
                Message = "Rejestracja specjalisty rozpoczęta. Wymagana weryfikacja dokumentów.",
                UserId = user.Id,
                RequiresEmailVerification = true
            };
        }

        public async Task<LoginResponse> RefreshTokenAsync(RefreshTokenRequest request)
        {
            var userId = _jwtService.ValidateToken(request.AccessToken);
            if (!userId.HasValue)
                throw new UnauthorizedAccessException("Nieprawidłowy token");

            var user = await _context.users.FindAsync(userId.Value);
            if (user == null || !user.IsActive)
                throw new UnauthorizedAccessException("Użytkownik nie istnieje lub jest nieaktywny");

            // Tutaj sprawdź refresh token w bazie (do zrobienia)

            var newAccessToken = _jwtService.GenerateAccessToken(user);
            var newRefreshToken = _jwtService.GenerateRefreshToken();

            // Zaktualizuj refresh token w bazie (do zrobienia)

            var userInfo = new UserInfoDto
            {
                Id = user.Id,
                Email = user.Email,
                UserType = user.UserType
            };

            return new LoginResponse
            {
                AccessToken = newAccessToken,
                RefreshToken = newRefreshToken,
                AccessTokenExpires = DateTime.Now.AddMinutes(15),
                RefreshTokenExpires = DateTime.Now.AddDays(7),
                User = userInfo
            };
        }

        public async Task<bool> LogoutAsync(string accessToken)
        {
            await _jwtService.RevokeToken(accessToken);
            return true;
        }

        public async Task<bool> ChangePasswordAsync(Guid userId, string currentPassword, string newPassword)
        {
            var user = await _context.users.FindAsync(userId);
            if (user == null)
                throw new ArgumentException("Użytkownik nie istnieje");

            if (!BCrypt.Net.BCrypt.Verify(currentPassword, user.PasswordHash))
                throw new UnauthorizedAccessException("Bieżące hasło jest nieprawidłowe");

            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(newPassword);
            user.UpdatedAt = DateTime.Now;

            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> RequestPasswordResetAsync(string email)
        {
            // Implementacja resetu hasła
            return await Task.FromResult(true);
        }

        public async Task<bool> ResetPasswordAsync(string token, string newPassword)
        {
            // Implementacja resetu hasła
            return await Task.FromResult(true);
        }
    }
}
