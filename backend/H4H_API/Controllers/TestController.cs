using Microsoft.AspNetCore.Mvc;
using H4H.Data;
using Microsoft.EntityFrameworkCore;

namespace H4H_API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class TestController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<TestController> _logger;

        public TestController(ApplicationDbContext context, ILogger<TestController> logger)
        {
            _context = context;
            _logger = logger;
        }

        // Endpoint 1: Sprawdź połączenie z bazą
        [HttpGet("database")]
        public IActionResult CheckDatabase()
        {
            try
            {
                _logger.LogInformation("Testing database connection...");

                // Test połączenia
                var canConnect = _context.Database.CanConnect();

                // Pobierz informacje o tabelach
                var connection = _context.Database.GetDbConnection();
                connection.Open();

                var command = connection.CreateCommand();
                command.CommandText = @"
                    SELECT 
                        COUNT(*) as table_count,
                        STRING_AGG(table_name, ', ' ORDER BY table_name) as tables
                    FROM information_schema.tables 
                    WHERE table_schema = 'public'";

                var reader = command.ExecuteReader();
                reader.Read();

                var tableCount = reader.GetInt32(0);
                var tablesList = reader.GetString(1);

                reader.Close();
                connection.Close();

                return Ok(new
                {
                    Status = "SUCCESS",
                    Database = connection.Database,
                    IsConnected = canConnect,
                    TablesCount = tableCount,
                    Tables = tablesList,
                    Timestamp = DateTime.Now
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Database connection test failed");
                return BadRequest(new
                {
                    Status = "ERROR",
                    Message = ex.Message,
                    Details = ex.InnerException?.Message
                });
            }
        }

        // Endpoint 2: Dodaj testowego użytkownika
        [HttpPost("test-user")]
        public async Task<IActionResult> CreateTestUser()
        {
            try
            {
                // Sprawdź czy już istnieje testowy użytkownik
                var existingUser = await _context.users
    .AsNoTracking()
    .FirstOrDefaultAsync(u => u.Email == "test@health4home.pl");

                if (existingUser != null)
                {
                    return Ok(new
                    {
                        Message = "Test user already exists",
                        UserId = existingUser.Id,
                        Email = existingUser.Email
                    });
                }

                // Stwórz nowego użytkownika
                var user = new H4H.Core.Models.User
                {
                    Id = Guid.NewGuid(),
                    Email = "test@health4home.pl",
                    PasswordHash = BCrypt.Net.BCrypt.HashPassword("Test123!"),
                    UserType = "client",
                    PhoneNumber = "+48123456789",
                    IsActive = true,
                    CreatedAt = DateTime.Now,
                    UpdatedAt = DateTime.Now
                };

                _context.users.Add(user);
                await _context.SaveChangesAsync();

                _logger.LogInformation($"Test user created: {user.Email}");

                return Ok(new
                {
                    Message = "Test user created successfully",
                    UserId = user.Id,
                    Email = user.Email,
                    CreatedAt = user.CreatedAt
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to create test user");
                return BadRequest(new { Error = ex.Message });
            }
        }

        // Endpoint 3: Pobierz listę użytkowników
        [HttpGet("users")]
        public async Task<IActionResult> GetUsers()
        {
            try
            {
                var users = await _context.users
                    .Select(u => new
                    {
                        u.Id,
                        u.Email,
                        u.UserType,
                        u.IsActive,
                        u.CreatedAt
                    })
                    .ToListAsync();

                return Ok(new
                {
                    Count = users.Count,
                    Users = users
                });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Error = ex.Message });
            }
        }

        // Endpoint 4: Sprawdź czy admin istnieje
        [HttpGet("check-admin")]
        public async Task<IActionResult> CheckAdmin()
        {
            try
            {
                var adminCount = await _context.admins.CountAsync();
                var hasAdmin = adminCount > 0;

                return Ok(new
                {
                    HasAdmin = hasAdmin,
                    AdminCount = adminCount,
                    Message = hasAdmin ? "Admin exists in database" : "No admin in database"
                });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Error = ex.Message });
            }
        }

        // Endpoint 5: Dodaj testowego admina
        [HttpPost("test-admin")]
        public async Task<IActionResult> CreateTestAdmin()
        {
            try
            {
                var existingAdmin = await _context.admins
                    .FirstOrDefaultAsync(a => a.Email == "admin@health4home.pl");

                if (existingAdmin != null)
                {
                    return Ok(new
                    {
                        Message = "Test admin already exists",
                        AdminId = existingAdmin.Id
                    });
                }

                var admin = new H4H.Core.Models.Admin
                {
                    Id = Guid.NewGuid(),
                    Email = "admin@health4home.pl",
                    PasswordHash = BCrypt.Net.BCrypt.HashPassword("Admin123!"),
                    Role = "super_admin",
                    FullName = "Test Administrator",
                    IsActive = true,
                    CreatedAt = DateTime.Now
                };

                _context.admins.Add(admin);
                await _context.SaveChangesAsync();

                return Ok(new
                {
                    Message = "Test admin created successfully",
                    AdminId = admin.Id,
                    Email = admin.Email,
                    Role = admin.Role
                });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Error = ex.Message });
            }
        }
    }
}