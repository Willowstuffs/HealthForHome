using H4H_API.DTOs.Auth;
using H4H_API.DTOs.Client;
using H4H_API.DTOs.Common;
using H4H_API.DTOs.Specialist;
using H4H_API.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using H4H.Core.Models;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace H4H_API.Controllers
{
    /// <summary>
    /// Provides endpoints for user authentication, registration, token management, and logout operations for client
    /// applications.
    /// </summary>
    /// <remarks>This controller exposes API endpoints for handling user authentication workflows, including
    /// client registration, login, token refresh, and logout. All endpoints are accessible via routes prefixed with
    /// 'api/auth'. Some actions require authentication, as indicated by the presence of the <see
    /// cref="AuthorizeAttribute"/>.</remarks>
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly IAuthService _authService;

        /// <summary>
        /// Initializes a new instance of the AuthController class with the specified authentication service.
        /// </summary>
        /// <param name="authService">The authentication service used to handle authentication operations. Cannot be null.</param>
        public AuthController(IAuthService authService)
        {
            _authService = authService;
        }

    ////Rejestracja specjalisty - endpoint publiczny
    [HttpPost("register/specialist")]
    public async Task<ActionResult<ApiResponse<RegisterResponse>>> RegisterSpecialist([FromBody] SpecialistRegisterDto request)
    {
        var result = await _authService.RegisterSpecialistAsync(request);
        return Ok(ApiResponse<RegisterResponse>.SuccessResponse(result, "Zarejestrowano pomyślnie. Oczekiwanie na weryfikacje."));
    }


        /// <summary>
        /// Registers a new client account using the provided registration details.
        /// </summary>
        /// <remarks>This endpoint is typically used during client onboarding to create a new user account. The
        /// response includes information about the registration result and any relevant messages.</remarks>
        /// <param name="request">The client registration data to use for creating the new account. Cannot be null.</param>
        /// <returns>A task that represents the asynchronous operation. The task result contains an <see cref="ActionResult{T}"/>
        /// with an <see cref="ApiResponse{RegisterResponse}"/> indicating the outcome of the registration. Returns a
        /// success response if registration is successful; otherwise, returns an error response with details.</returns>
        [HttpPost("register/client")]
        public async Task<ActionResult<ApiResponse<RegisterResponse>>> RegisterClient([FromBody] ClientRegisterDto request)
        {
            try
            {
                var result = await _authService.RegisterClientAsync(request);
                return Ok(ApiResponse<RegisterResponse>.SuccessResponse(result, "Rejestracja zakończona sukcesem"));
            }
            catch (Exception ex)
            {
                return BadRequest(ApiResponse<RegisterResponse>.ErrorResponse(ex.Message));
            }
        }

        /// <summary>
        /// Authenticates a user with the provided credentials and returns a response containing authentication details if
        /// successful.
        /// </summary>
        /// <remarks>Returns HTTP 200 (OK) with authentication details on success, HTTP 401 (Unauthorized) if the
        /// credentials are invalid, or HTTP 400 (Bad Request) for other errors.</remarks>
        /// <param name="request">The login request containing the user's credentials. Cannot be null.</param>
        /// <returns>An <see cref="ActionResult{T}"/> containing an <see cref="ApiResponse{T}"/> with the authentication result.
        /// Returns a successful response with authentication details if the credentials are valid; otherwise, returns an
        /// error response indicating the reason for failure.</returns>
        [HttpPost("login")]
        public async Task<ActionResult<ApiResponse<LoginResponse>>> Login([FromBody] LoginRequest request)
        {
            try
            {
                var result = await _authService.LoginAsync(request);
                return Ok(ApiResponse<LoginResponse>.SuccessResponse(result));
            }
            catch (UnauthorizedAccessException ex) // Błąd autoryzacji - niepoprawne dane
            {
                return Unauthorized(ApiResponse<LoginResponse>.ErrorResponse(ex.Message));
            }
            catch (Exception ex) // Inne błędy
            {
                return BadRequest(ApiResponse<LoginResponse>.ErrorResponse(ex.Message));
            }
        }

        /// <summary>
        /// Exchanges a valid refresh token for a new access token and refresh token pair.
        /// </summary>
        /// <remarks>This endpoint should be called when the current access token has expired and a valid refresh
        /// token is available. The client must provide a valid, unexpired refresh token in the request body. If the refresh
        /// token is invalid or expired, the response will indicate an unauthorized error.</remarks>
        /// <param name="request">The refresh token request containing the current refresh token and related information. Cannot be null.</param>
        /// <returns>An <see cref="ActionResult{T}"/> containing an <see cref="ApiResponse{T}"/> with the new access and refresh
        /// tokens if the request is valid; otherwise, an error response indicating the reason for failure.</returns>
        [HttpPost("refresh-token")]
        public async Task<ActionResult<ApiResponse<LoginResponse>>> RefreshToken([FromBody] RefreshTokenRequest request)
        {
            try
            {
                var result = await _authService.RefreshTokenAsync(request);
                return Ok(ApiResponse<LoginResponse>.SuccessResponse(result));
            }
            catch (UnauthorizedAccessException ex) // Token nieprawidłowy lub wygasły
            {
                return Unauthorized(ApiResponse<LoginResponse>.ErrorResponse(ex.Message));
            }
        }

        /// <summary>
        /// Logs out the currently authenticated user by invalidating their authentication token.
        /// </summary>
        /// <remarks>This endpoint requires the user to be authenticated. After a successful logout, the user's
        /// authentication token is invalidated and cannot be used for subsequent requests.</remarks>
        /// <returns>An <see cref="ActionResult{ApiResponse}"/> indicating the result of the logout operation. Returns a success
        /// response if the user was logged out successfully.</returns>
        [HttpPost("logout")]
        [Authorize] // Wymaga zalogowanego użytkownika
        public async Task<ActionResult<ApiResponse>> Logout()
        {
            // Pobierz token z nagłówka Authorization
            var token = Request.Headers["Authorization"].ToString().Replace("Bearer ", "");
            await _authService.LogoutAsync(token);
            return Ok(ApiResponse.SuccessResponse("Wylogowano pomyślnie"));
        }

        /// <summary>
        /// Aktualizuje token urządzenia dla zalogowanego użytkownika, umożliwiając otrzymywanie powiadomień push
        /// </summary>
        /// <param name="dto"></param>
        /// <returns></returns>
        [Authorize]
        [HttpPost("device-token")]
        public async Task<IActionResult> UpdateDeviceToken([FromBody] DeviceTokenDto dto)
        {
            try
            {
                var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value!);
                await _authService.UpdateDeviceTokenAsync(userId, dto.Token);
                return Ok(ApiResponse<string>.SuccessResponse("Token updated"));
            }
            catch (Exception ex)
            {
                return BadRequest(ApiResponse<string>.ErrorResponse(ex.Message));
            }
        }

        /// <summary>
        /// Wysyła 6-cyfrowy kod weryfikacyjny na podany adres e-mail (jeśli konto jest nieaktywne).
        /// </summary>
        [HttpPost("send-verification-code")]
        public async Task<ActionResult<ApiResponse>> SendVerificationCode([FromBody] SendVerificationCodeDto request)
        {
            await _authService.SendVerificationCodeAsync(request.Email);
            return Ok(ApiResponse.SuccessResponse("Kod weryfikacyjny został wysłany. Sprawdź swoją skrzynkę (również folder SPAM)."));
        }

        /// <summary>
        /// Weryfikuje 6-cyfrowy kod i aktywuje konto użytkownika.
        /// </summary>
        [HttpPost("verify-code")]
        public async Task<ActionResult<ApiResponse>> VerifyCode([FromBody] VerifyCodeDto request)
        {
            await _authService.VerifyCodeAsync(request);
            return Ok(ApiResponse.SuccessResponse("Konto zostało pomyślnie zweryfikowane i aktywowane. Możesz się teraz zalogować."));
        }

    }
}