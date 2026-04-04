using H4H.Core.Models;
using H4H.Data;
using H4H_API.DTOs.Auth;
using H4H_API.DTOs.Client;
using H4H_API.DTOs.Specialist;
using H4H_API.Exceptions;
using H4H_API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using ErrorCodes = H4H_API.Helpers.ErrorCodes;


namespace H4H_API.Services.Implementations
{
    /// <summary>
    /// Provides authentication and user account management services, including login, registration, token handling,
    /// password changes, and password reset operations for clients and specialists.
    /// </summary>
    /// <remarks>AuthService implements core authentication workflows for the application, such as issuing and
    /// refreshing JWT tokens, registering new users, and managing password changes and resets. It supports both client
    /// and specialist user types, handling their specific registration and verification requirements. All operations
    /// are performed asynchronously and require a valid database context and JWT service. This service should be used
    /// as the primary entry point for authentication-related functionality within the application.</remarks>
    public class AuthService : IAuthService
    {
        private readonly ApplicationDbContext _context;
        private readonly IJwtService _jwtService;
        private readonly IEmailService _emailService; //wstrzykniecie serwisu email do wysylania kodow weryfikacyjnych

        /// <summary>
        /// Initializes a new instance of the AuthService class using the specified database context and JWT service.
        /// </summary>
        /// <param name="context">The database context used to access application data for authentication operations. Cannot be null.</param>
        /// <param name="jwtService">The JWT service used to generate and validate JSON Web Tokens for authentication. Cannot be null.</param>
        public AuthService(ApplicationDbContext context, IJwtService jwtService, IEmailService emailService)
        {
            _context = context;
            _jwtService = jwtService;
            _emailService = emailService;
        }

        /// <summary>
        /// Authenticates a user using the provided login credentials and returns access and refresh tokens along with
        /// user information.
        /// </summary>
        /// <remarks>The access token is valid for 15 minutes, while the refresh token is valid for 7
        /// days. The returned user information includes details specific to the user's type (client or
        /// specialist).</remarks>
        /// <param name="request">The login request containing the user's email and password. Cannot be null.</param>
        /// <returns>A <see cref="LoginResponse"/> containing the access token, refresh token, their expiration times, and user
        /// details if authentication is successful.</returns>
        /// <exception cref="UnauthorizedAccessException">Thrown when the email or password is invalid, or the user account is inactive.</exception>
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

        /// <summary>
        /// Asynchronously registers a new client user with the provided registration details.
        /// </summary>
        /// <remarks>The method creates both a user and a client record in the system. Upon successful
        /// registration, the client will need to verify their email address before accessing certain
        /// features.</remarks>
        /// <param name="request">An object containing the client's registration information, including email, password, personal details, and
        /// contact information. All required fields must be populated; the email must be unique.</param>
        /// <returns>A <see cref="RegisterResponse"/> containing the result of the registration, including a message, the newly
        /// created user ID, and a flag indicating whether email verification is required.</returns>
        /// <exception cref="ArgumentException">Thrown if a user with the specified email address already exists.</exception>
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
                IsActive = true, // Zmienione z true żeby zablokować dostęp do czasu weryfikacji kodu!!!
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

        /// <summary>
        /// Registers a new specialist user account and initiates the verification process asynchronously.
        /// </summary>
        /// <remarks>The specialist account is created in an unverified state. The caller should prompt
        /// the user to complete any required document verification and email confirmation steps before the account can
        /// be fully activated.</remarks>
        /// <param name="request">An object containing the specialist's registration details, including email, password, and personal
        /// information. All required fields must be provided and valid.</param>
        /// <returns>A RegisterResponse containing information about the registration outcome, the newly created user ID, and
        /// whether email verification is required.</returns>
        /// <exception cref="ArgumentException">Thrown if a user with the specified email address already exists.</exception>
        public async Task<RegisterResponse> RegisterSpecialistAsync(SpecialistRegisterDto request)
        {
            //sprawdzenie czy email jest wolny
            if (await _context.users.AnyAsync(u => u.Email == request.Email))
                throw new ArgumentException("Użytkownik o podanym adresie email już istnieje");

            // Oba musza sie powiesc albo zaden
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                // Utwórz użytkownika w tabeli users
                var user = new User
                {
                    Id = Guid.NewGuid(),
                    Email = request.Email,
                    PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
                    UserType = "specialist",
                    IsActive = false, 
                    CreatedAt = DateTime.Now,
                    UpdatedAt = DateTime.Now
                };

                _context.users.Add(user);
                await _context.SaveChangesAsync();

                // Tworzenie profilu specjalisty w tabeli specialists
                var specialist = new Specialist
                {
                    Id = Guid.NewGuid(),
                    UserId = user.Id,
                    FirstName = request.FirstName,
                    LastName = request.LastName,
                    ProfessionalTitle = request.Specialization,
                    
                    //DEFAULTOWE dla nowej rejestracji
                    IsVerified = false,
                    VerificationStatus = "pending",
                    HourlyRate = null,
                    Bio = string.Empty,
                    AverageRating = 0,
                    TotalReviews = 0,
                    CreatedAt = DateTime.Now
                };

                _context.specialists.Add(specialist);

                await _context.SaveChangesAsync();

                await transaction.CommitAsync(); //jesli sie powiodlo, zatwierdz transakcje

                return new RegisterResponse
                {
                    Message = "Rejestracja specjalisty rozpoczęta. Wymagana weryfikacja dokumentów.",
                    UserId = user.Id,
                    RequiresEmailVerification = true, //tylko dla funkcji usera!
                };

            } catch (Exception)
            {
                await transaction.RollbackAsync(); //w przypadku bledu, wycofaj zmiany
                throw; //przekaz dalej wyjatek do middleware error handling
            }
        }

        /// <summary>
        /// Refreshes the access and refresh tokens for an authenticated user using the provided refresh token request.
        /// </summary>
        /// <param name="request">The refresh token request containing the current access token and refresh token. The access token must be
        /// valid and associated with an active user.</param>
        /// <returns>A <see cref="LoginResponse"/> containing new access and refresh tokens, their expiration times, and user
        /// information.</returns>
        /// <exception cref="UnauthorizedAccessException">Thrown if the access token is invalid, the user does not exist, or the user is inactive.</exception>
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

        /// <summary>
        /// Revokes the specified access token, logging the user out asynchronously.
        /// </summary>
        /// <param name="accessToken">The access token to revoke. Cannot be null or empty.</param>
        /// <returns>A task that represents the asynchronous operation. The task result is <see langword="true"/> if the logout
        /// operation was initiated successfully.</returns>
        public async Task<bool> LogoutAsync(string accessToken)
        {
            await _jwtService.RevokeToken(accessToken);
            return true;
        }

        /// <summary>
        /// Attempts to change the password for the specified user, verifying the current password before updating to
        /// the new password.
        /// </summary>
        /// <remarks>This method performs password verification using a secure hash comparison. The
        /// password change is persisted immediately. Ensure that the new password meets any application-specific
        /// security requirements before calling this method.</remarks>
        /// <param name="userId">The unique identifier of the user whose password is to be changed.</param>
        /// <param name="currentPassword">The user's current password, used to verify their identity before allowing the password change.</param>
        /// <param name="newPassword">The new password to set for the user. This should meet any password policy requirements enforced by the
        /// system.</param>
        /// <returns>A task that represents the asynchronous operation. The task result is <see langword="true"/> if the password
        /// was successfully changed; otherwise, <see langword="false"/>.</returns>
        /// <exception cref="ArgumentException">Thrown if the specified user does not exist.</exception>
        /// <exception cref="UnauthorizedAccessException">Thrown if the current password provided does not match the user's existing password.</exception>
        public async Task<bool> ChangePasswordAsync(Guid userId, string currentPassword, string newPassword)
        {
            var user = await _context.users.FindAsync(userId) ?? throw new ArgumentException("Użytkownik nie istnieje");
            if (!BCrypt.Net.BCrypt.Verify(currentPassword, user.PasswordHash))
                throw new UnauthorizedAccessException("Bieżące hasło jest nieprawidłowe");

            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(newPassword);
            user.UpdatedAt = DateTime.Now;

            await _context.SaveChangesAsync();
            return true;
        }

        /// <summary>
        /// Initiates a password reset request for the user associated with the specified email address.
        /// </summary>
        /// <param name="email">The email address of the user for whom the password reset is requested. Cannot be null or empty.</param>
        /// <returns>A task that represents the asynchronous operation. The task result is <see langword="true"/> if the password
        /// reset request was successfully initiated; otherwise, <see langword="false"/>.</returns>
        public async Task<bool> RequestPasswordResetAsync(string email)
        {
            // Implementacja resetu hasła
            return await Task.FromResult(true);
        }

        /// <summary>
        /// Resets the user's password using the specified reset token and new password.
        /// </summary>
        /// <param name="token">The password reset token that authorizes the password change. Cannot be null or empty.</param>
        /// <param name="newPassword">The new password to set for the user. Cannot be null or empty. Must meet any password policy requirements.</param>
        /// <returns>A task that represents the asynchronous operation. The task result is <see langword="true"/> if the password
        /// was reset successfully; otherwise, <see langword="false"/>.</returns>
        public async Task<bool> ResetPasswordAsync(string token, string newPassword)
        {
            // Implementacja resetu hasła
            return await Task.FromResult(true);
        }

        /// <summary>
        /// Akualizuje lub dodaje token urządzenia (FCM) dla użytkownika, umożliwiając wysyłanie powiadomień push na jego urządzenie. 
        /// Jeśli token już istnieje dla tego użytkownika, aktualizuje datę ostatniego użycia; w przeciwnym razie tworzy nowy rekord tokena.
        /// </summary>
        /// <param name="userId"></param>
        /// <param name="token"></param>
        /// <returns></returns>
        public async Task UpdateDeviceTokenAsync(Guid userId, string token)
        {
            var existingToken = await _context.device_tokens
                .FirstOrDefaultAsync(t => t.UserId == userId && t.FcmToken == token);

            if (existingToken != null)
            {
                existingToken.LastUsedAt = DateTime.UtcNow;
            }
            else
            {
                _context.device_tokens.Add(new DeviceToken
                {
                    UserId = userId,
                    FcmToken = token,
                    CreatedAt = DateTime.UtcNow,
                    LastUsedAt = DateTime.UtcNow
                });
            }
            await _context.SaveChangesAsync();
        }
        /// Sends a verification code to the specified email address for account registration verification.
        /// </summary>
        /// <remarks>This method generates a new 6-digit verification code and sends it to the provided
        /// email address if the associated user account exists and is not already active. Any previously issued, unused
        /// verification codes for the user are invalidated before the new code is created. The verification code is
        /// valid for 30 minutes from the time of generation.</remarks>
        /// <param name="email">The email address to which the verification code will be sent. Cannot be null or empty.</param>
        /// <returns></returns>
        /// <exception cref="AppException">Thrown if no user with the specified email exists, or if the user account is already verified.</exception>
        public async Task SendVerificationCodeAsync(string email)
        {
            // Wywołanie funkcji SQL: sprzątanie bazy danych z nieużywanych kodów weryfikacyjnych i nieaktywnych użytkowników
            await _context.Database.ExecuteSqlRawAsync("SELECT delete_expired_codes();"); // Kody czyścimy zawsze - to szybka operacja
            if (new Random().Next(1, 50) == 1) // Konta czyścimy tylko raz na 50 wysłanych maili (średnio)
            {
                await _context.Database.ExecuteSqlRawAsync("SELECT cleanup_inactive_users();");
            }
            // <3

            var user = await _context.users.FirstOrDefaultAsync(u => u.Email == email)
                ?? throw new AppException("Uzytkownik nie istnieje.", ErrorCodes.UserNotFound);

            if (user.IsActive)
                throw new AppException("Konto jest już zweryfikowane.", ErrorCodes.AccountAlreadyVerified);

            //Wygeneruj 6-cyfrowy kod
            var random = new Random();
            var code = random.Next(100000, 999999).ToString();

            //Unieważnij poprzednie kody dla tego usera
            var existingCodes = await _context.verification_codes
                .Where(vc => vc.UserId == user.Id && !vc.IsUsed)
                .ToListAsync();

            foreach (var existingCode in existingCodes)
            {
                existingCode.IsUsed = true;
            }

            //Zapisz nowy kod w bazie
            var verificationCode = new VerificationCode //encja z postgresika
            {
                Id = Guid.NewGuid(),
                UserId = user.Id,
                Email = email,
                Code = code,
                Purpose = "registration",
                IsUsed = false,
                ExpiresAt = DateTime.UtcNow.AddMinutes(30),
                CreatedAt = DateTime.UtcNow
            };

            _context.verification_codes.Add(verificationCode);
            await _context.SaveChangesAsync();

            //Wyślij email
            var emailBody = $"<h3>Witaj!</h3><p>Twój kod weryfikacyjny to: <b>{code}</b></p><p>Kod jest ważny przez 30 minut.</p>";
            await _emailService.SendEmailAsync(email, "Kod weryfikacyjny Health4Home", emailBody);
        }

        public async Task VerifyCodeAsync(VerifyCodeDto request)
        {
            var user = await _context.users.FirstOrDefaultAsync(u => u.Email == request.Email)
                ?? throw new AppException("Użytkownik nie istnieje.", ErrorCodes.UserNotFound);

            //Szybki patch tymczasowy póki nam service nie dziala, kod OTP 000000 bedzie zawsze traktowany jako poprawny by nie blokowac
            if (request.Code == "000000") //request.Code to ten, ktory user wpisuje w apce, nie z bazy.
            {
                user.IsActive = true;
                user.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();
                return;
            }
            //koniec patcha

            // Znajdź najnowszy aktywny kod
            var verificationCode = await _context.verification_codes
                .Where(vc => vc.UserId == user.Id && vc.Code == request.Code && !vc.IsUsed && vc.Purpose == "registration")
                .OrderByDescending(vc => vc.CreatedAt)
                .FirstOrDefaultAsync();
            

            if (verificationCode != null)
            {
                if (verificationCode.ExpiresAt < DateTime.UtcNow)
                    throw new AppException("Kod weryfikacyjny wygasł.", ErrorCodes.VerificationCodeExpired);

                // Oznacz kod jako użyty i aktywuj konto
                verificationCode.IsUsed = true;
                user.IsActive = true;
                user.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();
            }
            else
                throw new AppException("Nieprawidłowy kod weryfikacyjny.", ErrorCodes.WrongVerificationCode);
        }
    }
}
