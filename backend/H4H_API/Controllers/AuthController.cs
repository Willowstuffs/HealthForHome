using H4H_API.DTOs.Auth;
using H4H_API.DTOs.Common;
using H4H_API.DTOs.Client;
using H4H_API.DTOs.Specialist;
using H4H_API.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;

    public AuthController(IAuthService authService)
    {
        _authService = authService;
    }

    // Rejestracja klienta - endpoint publiczny
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

    //Rejestracja specjalisty - endpoint publiczny
    [HttpPost("register/specialist")]
    public async Task<ActionResult<ApiResponse<RegisterResponse>>> RegisterSpecialist([FromBody] SpecialistRegisterDto request)
    {
        var result = await _authService.RegisterSpecialistAsync(request);
        return Ok(ApiResponse<RegisterResponse>.SuccessResponse(result, "Zarejestrowano pomyślnie. Oczekiwanie na weryfikacje."));
    }

    // Logowanie - endpoint publiczny
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

    // Odświeżanie tokena - używa starego tokena do uzyskania nowego
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

    // Wylogowanie - wymaga autoryzacji
    [HttpPost("logout")]
    [Authorize] // Wymaga zalogowanego użytkownika
    public async Task<ActionResult<ApiResponse>> Logout()
    {
        // Pobierz token z nagłówka Authorization
        var token = Request.Headers["Authorization"].ToString().Replace("Bearer ", "");
        await _authService.LogoutAsync(token);
        return Ok(ApiResponse.SuccessResponse("Wylogowano pomyślnie"));
    }
}