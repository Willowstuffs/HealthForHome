using H4H.Core.Helpers;

namespace H4H_API.DTOs.Common
{
    /// <summary>
    /// Generyczna klasa odpowiedzi API dla endpointów które zwracają dane
    /// </summary>
    /// <typeparam name="T">Typ danych zwracanych w sukcesie</typeparam>
    public class ApiResponse<T>
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;
        public string? ErrorCode { get; set; } //Opcjonalny kod błędu
        public T? Data { get; set; } // Dane zwracane przez endpoint
        public List<string>? Errors { get; set; } // Lista błędów (jeśli success=false)
        public DateTime Timestamp { get; set; } = DateTime.Now; // Znacznik czasu odpowiedzi

        /// <summary>
        /// Metoda pomocnicza do tworzenia pozytywnej odpowiedzi
        /// </summary>
        /// <param name="data">Dane do zwrócenia</param>
        /// <param name="message">Opcjonalna wiadomość</param>
        public static ApiResponse<T> SuccessResponse(T data, string message = "Operacja zakończona sukcesem")
        {
            return new ApiResponse<T>
            {
                Success = true,
                Message = message,
                Data = data
            };
        }
        /// <summary>
        /// Tworzy odpowiedzi błędu
        /// </summary>
        /// <param name="message">Wiadomość błędu</param>
        /// <param name="errors">Opcjonalna lista szczegółów błędów</param>
        public static ApiResponse<T> ErrorResponse(string message, string? errorCode = null, List<string>? errors = null)
        {
            return new ApiResponse<T>
            {
                Success = false,
                Message = message,
                ErrorCode = errorCode,
                Errors = errors
            };
        }
    }

    /// <summary>
    /// Dla endpointów które nie zwracają danych
    /// </summary>
    public class ApiResponse
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;
        public string? ErrorCode { get; set; }
        public List<string>? Errors { get; set; }
        public DateTime Timestamp { get; set; } = DateTime.UtcNow;

        public static ApiResponse SuccessResponse(string message = "Operacja zakończona sukcesem")
        {
            return new ApiResponse { Success = true, Message = message };
        }

        public static ApiResponse ErrorResponse(string message, string? errorCode = null, List<string>? errors = null)
        {
            return new ApiResponse
            {
                Success = false,
                Message = message,
                ErrorCode = errorCode,
                Errors = errors
            };
        }
    }
}