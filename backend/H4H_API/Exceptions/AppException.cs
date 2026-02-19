namespace H4H_API.Exceptions
{
    public class AppException : Exception
    {
        public string ErrorCode { get; }

        public AppException(string message, string errorCode) : base(message)
        {
            ErrorCode = errorCode;
        }
    }
}
