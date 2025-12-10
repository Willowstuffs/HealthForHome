using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace H4H_API.Controllers
{
    [ApiController] //wlacza automatyczna walidacje modelu
    [Route("api/[controller]")] //sciezka api/status
    public class StatusController : ControllerBase
    {
        [HttpGet] //metoda GET
        public IActionResult GetStatus()
        { //ok200 z timestampem
            return Ok(new { status = "API is running", time = DateTime.Now });
        }
    }
}
