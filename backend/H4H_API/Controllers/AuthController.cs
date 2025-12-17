using Microsoft.AspNetCore.Mvc;
using H4H.Core.Interfaces;

namespace H4H_API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly IUserRepository _userRepository;

        public AuthController(IUserRepository userRepository)
        {
            _userRepository = userRepository;
        }

        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterRequest request)
        {
            if (await _userRepository.EmailExistsAsync(request.Email))
            {
                return BadRequest(new { message = "Email already exists" });
            }

            var user = await _userRepository.CreateUserAsync(
                request.Email,
                request.Password,
                request.FirstName,
                request.LastName,
                "client");

            return Ok(new
            {
                message = "Registration successful",
                userId = user.Id,
                requiresVerification = true
            });
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            var user = await _userRepository.AuthenticateAsync(request.Email, request.Password);

            if (user == null)
                return Unauthorized(new { message = "Invalid email or password" });

            // TODO: Dodać JWT token później
            var token = "temp-token-until-jwt-implementation";

            return Ok(new
            {
                token,
                user = new
                {
                    id = user.Id,
                    email = user.Email,
                    userType = user.UserType,
                    firstName = user.UserType == "client" ? user.Client?.FirstName : user.Specialist?.FirstName
                }
            });
        }
    }

    // DTOs
    public class RegisterRequest
    {
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
    }

    public class LoginRequest
    {
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
    }
}