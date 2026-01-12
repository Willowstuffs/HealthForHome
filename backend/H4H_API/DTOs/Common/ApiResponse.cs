namespace H4H_API.DTOs.Common
{
    /// <summary>
    /// Represents a standardized response returned by an API operation, including status, message, data, and error
    /// details.
    /// </summary>
    /// <remarks>Use this class to encapsulate both successful and error responses from API endpoints. The
    /// generic parameter allows the response to carry any type of data relevant to the operation. The response includes
    /// a timestamp, a success indicator, an optional message, and a list of errors if the operation failed.</remarks>
    /// <typeparam name="T">The type of the data payload returned by the API response.</typeparam>
    public class ApiResponse<T>
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;
        public T? Data { get; set; } // Dane zwracane przez endpoint
        public List<string>? Errors { get; set; } // Lista błędów (jeśli success=false)
        public DateTime Timestamp { get; set; } = DateTime.Now; // Znacznik czasu odpowiedzi

        /// <summary>
        /// Creates a successful API response containing the specified data and an optional message.
        /// </summary>
        /// <param name="data">The data to include in the response. This value is assigned to the <see cref="ApiResponse{T}.Data"/>
        /// property.</param>
        /// <param name="message">An optional message describing the result of the operation. The default is "Operacja zakończona sukcesem".</param>
        /// <returns>An <see cref="ApiResponse{T}"/> instance with <see cref="ApiResponse{T}.Success"/> set to <see
        /// langword="true"/>, containing the specified data and message.</returns>
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
        /// Creates an error response with the specified message and optional list of error details.
        /// </summary>
        /// <param name="message">The error message describing the reason for the failure. Cannot be null.</param>
        /// <param name="errors">An optional list of error details to include in the response. If null, an empty list is used.</param>
        /// <returns>An <see cref="ApiResponse{T}"/> instance representing a failed operation, containing the provided error
        /// message and error details.</returns>
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

    /// <summary>
    /// Represents a standard response returned by an API, including status, message, errors, and a timestamp.
    /// </summary>
    /// <remarks>Use this class to encapsulate the outcome of API operations, providing a consistent structure
    /// for both successful and error responses. The static methods <see cref="SuccessResponse"/> and <see
    /// cref="ErrorResponse"/> can be used to create common response types.</remarks>
    public class ApiResponse
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;
        public List<string>? Errors { get; set; }
        public DateTime Timestamp { get; set; } = DateTime.UtcNow;

        /// <summary>
        /// Creates a successful API response with the specified message.
        /// </summary>
        /// <param name="message">The message to include in the response. If not specified, a default success message is used.</param>
        /// <returns>An ApiResponse instance indicating a successful operation, with the specified message.</returns>
        public static ApiResponse SuccessResponse(string message = "Operacja zakończona sukcesem")
        {
            return new ApiResponse { Success = true, Message = message };
        }

        /// <summary>
        /// Creates an error response with the specified message and optional list of error details.
        /// </summary>
        /// <param name="message">The error message to include in the response. Cannot be null.</param>
        /// <param name="errors">An optional list of error details to include in the response. If null, an empty list is used.</param>
        /// <returns>An <see cref="ApiResponse"/> instance representing an error, with <see cref="ApiResponse.Success"/> set to
        /// <see langword="false"/>.</returns>
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