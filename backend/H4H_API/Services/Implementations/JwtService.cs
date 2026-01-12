using H4H.Core.Models;
using H4H.Data;
using H4H_API.Services.Interfaces;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace H4H_API.Services.Implementations
{
    public class JwtService : IJwtService
    {
        private readonly IConfiguration _configuration;
        private readonly ApplicationDbContext _context;

        public JwtService(IConfiguration configuration, ApplicationDbContext context)
        {
            _configuration = configuration;
            _context = context;
        }

        public string GenerateAccessToken(User user)
        {
            var tokenHandler = new JwtSecurityTokenHandler();
            var key = Encoding.UTF8.GetBytes(_configuration["Jwt:Key"]!); // Pobierz klucz JWT z konfiguracji

            // Zdefiniuj dane które będą zawarte w tokenie
            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),   // ID użytkownika
                new Claim(ClaimTypes.Email, user.Email),                    // Email użytkownika
                new Claim(ClaimTypes.Role, user.UserType)                   // Typ użytkownika (rola)
            };

            // Skonfiguruj parametry tokena
            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(claims),
                Expires = DateTime.Now.AddMinutes(
                    Convert.ToDouble(_configuration["Jwt:AccessTokenExpiresMinutes"] ?? "60")), // Czas ważności
                Issuer = _configuration["Jwt:Issuer"],      // Wydawca tokena
                Audience = _configuration["Jwt:Audience"],  // Odbiorca tokena
                SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256Signature) // Algorytm podpisu
            };

            var token = tokenHandler.CreateToken(tokenDescriptor);
            return tokenHandler.WriteToken(token); // Zwróć token jako string
        }

        public string GenerateRefreshToken()
        {
            var randomNumber = new byte[32];
            using var rng = System.Security.Cryptography.RandomNumberGenerator.Create();
            rng.GetBytes(randomNumber);
            return Convert.ToBase64String(randomNumber);
        }

        public Guid? ValidateToken(string token)
        {
            if (string.IsNullOrEmpty(token))
                return null;

            var tokenHandler = new JwtSecurityTokenHandler();
            var key = Encoding.UTF8.GetBytes(_configuration["Jwt:Key"]!);

            try
            {
                tokenHandler.ValidateToken(token, new TokenValidationParameters
                {
                    ValidateIssuerSigningKey = true,
                    IssuerSigningKey = new SymmetricSecurityKey(key),
                    ValidateIssuer = true,
                    ValidateAudience = true,
                    ValidIssuer = _configuration["Jwt:Issuer"],
                    ValidAudience = _configuration["Jwt:Audience"],
                    ValidateLifetime = true,
                    ClockSkew = TimeSpan.Zero
                }, out SecurityToken validatedToken);

                var jwtToken = (JwtSecurityToken)validatedToken;
                var userId = jwtToken.Claims.First(x => x.Type == ClaimTypes.NameIdentifier).Value;
                return Guid.Parse(userId);
            }
            catch
            {
                return null;
            }
        }

        public async Task<bool> IsTokenRevoked(string token)
        {
            // Sprawdzanie czy token jest na czarnej liście
            return await Task.FromResult(false); // Na razie prosty przykład
        }

        public async Task RevokeToken(string token)
        {
            // Dodawanie tokena do czarnej listy
            await Task.CompletedTask;
        }
    }
}
