using H4H_API.Services.Interfaces;
using H4H_API.Helpers;

namespace H4H_API.Middleware
{
    /// <summary>
    /// Middleware do obsługi tokenów JWT
    /// </summary>
    public class JwtMiddleware
    {
        private readonly RequestDelegate _next;

        public JwtMiddleware(RequestDelegate next)
        {
            _next = next;
        }

        /// <summary>
        /// Middleware do sprawdzania, czy token JWT jest na czarnej liście (revoked). Jeśli token jest zrevokowany, 
        /// zwraca 401 Unauthorized z odpowiednim komunikatem. Jeśli token jest ważny lub nie ma tokena, pozwala na dalsze przetwarzanie żądania.
        /// </summary>
        /// <param name="context"></param>
        /// <param name="jwtService"></param>
        /// <returns></returns>
        public async Task Invoke(HttpContext context, IJwtService jwtService)
        {
            // 1. Pobieramy token z nagłówka
            var token = context.Request.Headers["Authorization"].ToString().Replace("Bearer ", "");

            if (!string.IsNullOrEmpty(token))
            {
                // 2. Wywołujemy metodę z JwtService
                if (await jwtService.IsTokenRevoked(token))
                {
                    // 3. Jeśli token jest na czarnej liście, przerywamy i wyrzucamy 401
                    context.Response.StatusCode = StatusCodes.Status401Unauthorized;
                    context.Response.ContentType = "application/json";
                    await context.Response.WriteAsJsonAsync(new
                    {
                        success = false,
                        message = "Sesja wygasła lub użytkownik wylogowany.",
                        errorCode = ErrorCodes.InvalidToken
                    });
                    return; // Przerywamy dalsze przetwarzanie żądania
                }
            }

            // Jeśli token nie jest na czarnej liście lub nie ma tokena, kontynuujemy przetwarzanie żądania
            await _next(context);
        }
    }
}