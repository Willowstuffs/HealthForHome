using Microsoft.AspNetCore.Mvc;
using H4H.Data;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;

namespace H4H_API.Controllers
{
    /// <summary>
    /// Provides API endpoints for testing and managing application data, including database connectivity checks and
    /// creation of test users and administrators.
    /// </summary>
    /// <remarks>This controller is intended primarily for development and testing purposes. It exposes
    /// endpoints to verify database connectivity, retrieve user information, and create test user and administrator
    /// accounts. These endpoints should not be used in production environments, as they may expose sensitive operations
    /// or test data. All actions are accessible via HTTP routes prefixed with 'api/test'.</remarks>
    [ApiController]
    [Route("api/[controller]")]
    public class TestController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<TestController> _logger;

        /// <summary>
        /// Initializes a new instance of the TestController class with the specified database context and logger.
        /// </summary>
        /// <param name="context">The database context used to access application data. Cannot be null.</param>
        /// <param name="logger">The logger used to record diagnostic and operational information. Cannot be null.</param>
        public TestController(ApplicationDbContext context, ILogger<TestController> logger)
        {
            _context = context;
            _logger = logger;
        }


        /// <summary>
        /// Checks the application's ability to connect to the database and retrieves information about the available
        /// tables.
        /// </summary>
        /// <remarks>This endpoint is intended for health checks and diagnostics. The response includes a
        /// summary of the database state, which can be useful for monitoring or troubleshooting connectivity issues.
        /// Sensitive information is not exposed in the response.</remarks>
        /// <returns>An HTTP 200 response containing the database name, connection status, table count, table names, and a
        /// timestamp if the check succeeds; otherwise, an HTTP 400 response with error details.</returns>

        [HttpGet("database")]
        public IActionResult CheckDatabase()
        {
            try
            {
                _logger.LogInformation("Testing database connection...");


                // Test czy można połączyć się z bazą
                var canConnect = _context.Database.CanConnect();

                // Bezpośrednie zapytanie SQL do pobrania informacji o tabelach

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

        /// <summary>
        /// Creates a test user account with predefined credentials if one does not already exist.
        /// </summary>
        /// <remarks>This endpoint is intended for development or testing purposes. If a test user with
        /// the email "test@health4home.pl" already exists, the existing user's information is returned. Otherwise, a
        /// new test user is created and returned. The created user's password is set to "Test123!". This endpoint
        /// should not be exposed in production environments.</remarks>
        /// <returns>An <see cref="OkObjectResult"/> containing information about the test user if the operation succeeds, or a
        /// <see cref="BadRequestObjectResult"/> with error details if the operation fails.</returns>
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


                // Stwórz nowego użytkownika testowego

                var user = new H4H.Core.Models.User
                {
                    Id = Guid.NewGuid(),
                    Email = "test@health4home.pl",

                    PasswordHash = BCrypt.Net.BCrypt.HashPassword("Test123!"), // Zahaszowane hasło

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


        /// <summary>
        /// Retrieves a list of all users with basic profile information.
        /// </summary>
        /// <remarks>Sensitive information such as password hashes is not included in the returned data.
        /// The response includes only non-confidential user details. If an error occurs during retrieval, a bad request
        /// response is returned with an error message.</remarks>
        /// <returns>An <see cref="IActionResult"/> containing a JSON object with the total user count and a collection of user
        /// records. Each user record includes the user's ID, email, user type, active status, and creation date.</returns>

        [HttpGet("users")]
        public async Task<IActionResult> GetUsers()
        {
            try
            {
                var users = await _context.users


                    .Select(u => new // Projektowanie danych - nie zwracamy hash hasła!

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

        /// <summary>
        /// Checks whether any administrator accounts exist in the database.
        /// </summary>
        /// <returns>An <see cref="IActionResult"/> containing a JSON object with the following properties: <c>HasAdmin</c> (a
        /// boolean indicating whether at least one admin exists), <c>AdminCount</c> (the total number of admins), and
        /// <c>Message</c> (a descriptive message). Returns a 400 Bad Request with an error message if an exception
        /// occurs.</returns>
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

        /// <summary>
        /// Creates a test administrator account with predefined credentials if one does not already exist.
        /// </summary>
        /// <remarks>This endpoint is intended for development or testing purposes and should not be used
        /// in production environments. The test administrator is created with a fixed email and password. If an account
        /// with the specified email already exists, no new account is created.</remarks>
        /// <returns>An <see cref="IActionResult"/> containing a success message and administrator details if the test admin is
        /// created or already exists; otherwise, a bad request result with error information.</returns>
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

                    Role = "super_admin", // Rola super administratora

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

        /// <summary>
        /// Tests connectivity to the Nominatim geocoding service by performing a sample address lookup.
        /// </summary>
        /// <returns> </returns>
        [HttpGet("test-nominatim")]
        public async Task<IActionResult> TestNominatim()
        {
            try
            {
                // Test bezpośrednio HTTP
                var httpClient = new HttpClient();
                httpClient.DefaultRequestHeaders.UserAgent.ParseAdd("Health4Home/1.0");

                // Test 1: Prosty adres (miasto)
                var testAddress = "Warszawa";
                var encodedAddress = Uri.EscapeDataString(testAddress);
                var url = $"https://nominatim.openstreetmap.org/search?format=json&q={encodedAddress}&limit=1";

                Console.WriteLine($"Testing Nominatim with: {url}");
                var response = await httpClient.GetStringAsync(url);
                var json = JsonDocument.Parse(response);

                return Ok(new
                {
                    Test = "Nominatim Connection Test",
                    Url = url,
                    ResponseLength = response.Length,
                    HasResults = json.RootElement.GetArrayLength() > 0,
                    FirstResult = json.RootElement.GetArrayLength() > 0 ?
                        json.RootElement[0].GetProperty("display_name").GetString() :
                        "No results"
                });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Error = ex.Message, StackTrace = ex.StackTrace });
            }
        }
    }
}