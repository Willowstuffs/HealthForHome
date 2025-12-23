namespace H4H_API.DTOs.Auth
{
    // Klasa odpowiedzi po udanej rejestracji
    public class RegisterResponse
    {
        public string Message { get; set; } = string.Empty;
        public Guid UserId { get; set; }
        public bool RequiresEmailVerification { get; set; } = true;
    }
}