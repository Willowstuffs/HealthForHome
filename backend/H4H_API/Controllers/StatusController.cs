using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace H4H_API.Controllers
{
    /// <summary>
    /// Handles status-related API requests for monitoring the application's health.
    /// </summary>
    /// <remarks>This controller provides endpoints that allow clients to verify that the API is operational.
    /// It is typically used for health checks or uptime monitoring.</remarks>
    [ApiController] //wlacza automatyczna walidacje modelu
    [Route("api/[controller]")] //sciezka api/status
    public class StatusController : ControllerBase
    {
        /// <summary>
        /// Handles HTTP GET requests to retrieve the current status of the API.
        /// </summary>
        /// <remarks>The returned object includes a "status" string and a "time" value representing the
        /// server's current date and time. This endpoint can be used for health checks or to verify that the API is
        /// operational.</remarks>
        /// <returns>An <see cref="OkObjectResult"/> containing an object with the API status message and the current server
        /// time.</returns>
        [HttpGet] //metoda GET
        public IActionResult GetStatus()
        { //ok200 z timestampem
            return Ok(new { status = "API is running", time = DateTime.Now });
        }
    }
}
