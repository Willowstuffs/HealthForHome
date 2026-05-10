using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using H4H.Core.Models;
using H4H.Data;
using H4H_API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;

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

        public Guid? ValidateToken(string token, bool validateLifetime = true) // Dodany parametr validateLifetime, aby umożliwić weryfikację tokena bez sprawdzania jego ważności (przydatne np. przy odświeżaniu tokena)
        {
            if (string.IsNullOrEmpty(token)) return null;
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
                    ValidateLifetime = validateLifetime, // Używamy przekazanego parametru do decydowania o weryfikacji ważności tokena
                    ClockSkew = TimeSpan.Zero
                }, out SecurityToken validatedToken);

                var jwtToken = (JwtSecurityToken)validatedToken;

                // Bezpieczniejsze pobieranie claima
                var userIdClaim = jwtToken.Claims.FirstOrDefault(x =>
                    x.Type == ClaimTypes.NameIdentifier || x.Type == "nameid");

                return userIdClaim != null ? Guid.Parse(userIdClaim.Value) : null;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[JWT Validation Error]: {ex.Message}");
                return null;
            }
        }

        public async Task<bool> IsTokenRevoked(string token)
        {
            // Sprawdzanie czy token jest na czarnej liście
            return await _context.Set<RevokedToken>().AnyAsync(t => t.Token == token);
        }

        public async Task RevokeToken(string token)
        {
            var handler = new JwtSecurityTokenHandler();
            var jwtToken = handler.ReadJwtToken(token);

            _context.Set<RevokedToken>().Add(new RevokedToken
            {
                Id = Guid.NewGuid(),
                Token = token,
                ExpiresAt = jwtToken.ValidTo // Do kiedy musimy przechowywać token na czarnej liście (do momentu wygaśnięcia)
            });

            await _context.SaveChangesAsync();
        }
    }
}
