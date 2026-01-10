using System.Net;
using System.Text.Json;
using H4H_API.DTOs.Common;
using H4H_API.Exceptions;

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

            // Domyslne wartosci
            var statusCode = HttpStatusCode.InternalServerError;
            string? errorCode = null;
            string message = "Wystąpił nieoczekiwany błąd serwera";

            switch(exception)
            {
                case AppException appEx:
                    statusCode = HttpStatusCode.BadRequest;
                    errorCode = appEx.ErrorCode;
                    message = appEx.Message;
                    break;
                case UnauthorizedAccessException:
                    statusCode = HttpStatusCode.Unauthorized;
                    message = exception.Message;
                    break;
                case KeyNotFoundException:
                    statusCode = HttpStatusCode.NotFound;
                    message = exception.Message;
                    break;
                case ArgumentException:
                    statusCode = HttpStatusCode.BadRequest;
                    message = exception.Message;
                    break;
                default:
                    // Dla pozostałych błędów zachowujemy 500 i domyślną wiadomość
                    break;
            }
            ;

            // Przygotuj odpowiedź w zaktualizowanym ApiResponse
            var response = ApiResponse.ErrorResponse(message, errorCode);

            context.Response.ContentType = "application/json";
            context.Response.StatusCode = (int)statusCode;

            // Zwróć odpowiedź jako JSON
            var jsonOptions = new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
            await context.Response.WriteAsync(JsonSerializer.Serialize(response, jsonOptions));
        }
    }
}
