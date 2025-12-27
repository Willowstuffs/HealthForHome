namespace H4H_API.DTOs.Common
{
    // Generyczna klasa odpowiedzi API dla endpointów które zwracają dane
    public class ApiResponse<T>
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;
        public T? Data { get; set; } // Dane zwracane przez endpoint
        public List<string>? Errors { get; set; } // Lista błędów (jeśli success=false)
        public DateTime Timestamp { get; set; } = DateTime.Now; // Znacznik czasu odpowiedzi

        // Metoda pomocnicza do tworzenia pozytywnej odpowiedzi
        public static ApiResponse<T> SuccessResponse(T data, string message = "Operacja zakończona sukcesem")
        {
            return new ApiResponse<T>
            {
                Success = true,
                Message = message,
                Data = data
            };
        }

        public static ApiResponse<T> ErrorResponse(string message, List<string>? errors = null)
        {
            return new ApiResponse<T>
            {
                Success = false,
                Message = message,
                Errors = errors ?? new List<string>()
            };
        }
    }

    // Dla endpointów które nie zwracają danych
    public class ApiResponse
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;
        public List<string>? Errors { get; set; }
        public DateTime Timestamp { get; set; } = DateTime.UtcNow;

        public static ApiResponse SuccessResponse(string message = "Operacja zakończona sukcesem")
        {
            return new ApiResponse { Success = true, Message = message };
        }

        public static ApiResponse ErrorResponse(string message, List<string>? errors = null)
        {
            return new ApiResponse
            {
                Success = false,
                Message = message,
                Errors = errors ?? new List<string>()
            };
        }
    }
}