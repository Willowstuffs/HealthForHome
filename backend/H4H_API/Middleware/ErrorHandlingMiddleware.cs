using System.Net;
using System.Text.Json;
using H4H_API.DTOs.Common;
using H4H_API.Exceptions;
using H4H_API.Helpers;

namespace H4H_API.Middleware
{
    /// <summary>
    /// Middleware that provides centralized exception handling for HTTP requests in the ASP.NET Core pipeline.
    /// </summary>
    /// <remarks>This middleware intercepts unhandled exceptions thrown during request processing, logs the
    /// error, and returns a standardized JSON error response with an appropriate HTTP status code. It should be
    /// registered early in the middleware pipeline to ensure that all exceptions are caught and handled consistently.
    /// The response format and status codes are mapped based on the exception type, providing clients with meaningful
    /// error information.</remarks>
    public class ErrorHandlingMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<ErrorHandlingMiddleware> _logger;

        /// <summary>
        /// Initializes a new instance of the ErrorHandlingMiddleware class with the specified request delegate and
        /// logger.
        /// </summary>
        /// <param name="next">The next middleware component in the HTTP request pipeline. Cannot be null.</param>
        /// <param name="logger">The logger used to record error information. Cannot be null.</param>
        public ErrorHandlingMiddleware(RequestDelegate next, ILogger<ErrorHandlingMiddleware> logger)
        {
            _next = next;
            _logger = logger;
        }

        /// <summary>
        /// Processes an HTTP request asynchronously and handles any unhandled exceptions that occur during request
        /// processing.
        /// </summary>
        /// <remarks>If an exception is thrown during request processing, it is caught and handled to
        /// generate an appropriate HTTP response. This method is typically used as part of the ASP.NET Core middleware
        /// pipeline.</remarks>
        /// <param name="context">The HTTP context for the current request. Provides access to request and response information.</param>
        /// <returns>A task that represents the asynchronous operation.</returns>
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

        /// <summary>
        /// Handles an unhandled exception by logging the error and generating an appropriate JSON error response for
        /// the HTTP client.
        /// </summary>
        /// <remarks>The response status code and error message are determined based on the type of
        /// exception. The response is formatted as JSON and uses standard HTTP status codes for common exception
        /// types.</remarks>
        /// <param name="context">The HTTP context for the current request. Used to write the error response.</param>
        /// <param name="exception">The exception that was thrown during request processing.</param>
        /// <returns>A task that represents the asynchronous operation of handling the exception and writing the response.</returns>
        private async Task HandleExceptionAsync(HttpContext context, Exception exception)
        {
            _logger.LogError(exception, "An unhandled exception occurred");

            // Domyslne wartosci
            var statusCode = HttpStatusCode.InternalServerError;
            string? errorCode = null;
            string message = "Wystąpił nieoczekiwany błąd serwera";


            switch (exception)
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