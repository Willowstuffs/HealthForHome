using System.Net;
using System.Text.Json;
using H4H_API.DTOs.Common;

namespace H4H_API.Middleware
{
    public class ErrorHandlingMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<ErrorHandlingMiddleware> _logger;

        public ErrorHandlingMiddleware(RequestDelegate next, ILogger<ErrorHandlingMiddleware> logger)
        {
            _next = next;
            _logger = logger;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            try
            {
                await _next(context);  // Przekaż żądanie dalej w pipeline
            }
            catch (Exception ex)
            {
                await HandleExceptionAsync(context, ex); // Obsłuż wyjątek
            }
        }

        private async Task HandleExceptionAsync(HttpContext context, Exception exception)
        {
            _logger.LogError(exception, "An unhandled exception occurred");

            // Mapuj typy wyjątków na kody HTTP
            var statusCode = exception switch
            {
                UnauthorizedAccessException => HttpStatusCode.Unauthorized,  // 401 - brak autoryzacji
                KeyNotFoundException => HttpStatusCode.NotFound,             // 404 - nie znaleziono
                ArgumentException => HttpStatusCode.BadRequest,              // 400 - złe żądanie
                NotImplementedException => HttpStatusCode.NotImplemented,    // 501 - nie zaimplementowano
                _ => HttpStatusCode.InternalServerError                      // 500 - błąd serwera
            };

            // Przygotuj odpowiedź w standardowym formacie API
            var response = ApiResponse.ErrorResponse(
                statusCode == HttpStatusCode.InternalServerError
                    ? "Wystąpił nieoczekiwany błąd serwera"
                    : exception.Message
            );

            context.Response.ContentType = "application/json";
            context.Response.StatusCode = (int)statusCode;

            // Zwróć odpowiedź jako JSON
            var jsonOptions = new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
            await context.Response.WriteAsync(JsonSerializer.Serialize(response, jsonOptions));
        }
    }
}
