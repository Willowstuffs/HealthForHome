namespace H4H_API.DTOs.Auth
{
    /// <summary>
    /// Represents the result of a user registration operation, including status information and user details.
    /// </summary>
    public class RegisterResponse
    {
        public string Message { get; set; } = string.Empty;
        public Guid UserId { get; set; }
        public bool RequiresEmailVerification { get; set; } = true;
    }
}