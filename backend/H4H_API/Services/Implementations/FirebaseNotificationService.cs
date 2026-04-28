using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;
using Message = FirebaseAdmin.Messaging.Message;
using Notification = FirebaseAdmin.Messaging.Notification;

namespace H4H_API.Services.Implementations
{
    public class FirebaseNotificationService
    {
        private readonly FirebaseApp _specialistApp;
        private readonly FirebaseApp _clientApp;

        public FirebaseNotificationService()
        {
            var jsonSpecialist = Environment.GetEnvironmentVariable("FIREBASE_CREDENTIALS_JSON");
            if (!string.IsNullOrEmpty(jsonSpecialist))
            {
                _specialistApp = FirebaseApp.DefaultInstance ?? FirebaseApp.Create(new AppOptions()
                {
                    Credential = GoogleCredential.FromJson(jsonSpecialist),
                    ProjectId = "test-e1dc5"
                });
            }

            var jsonClient = Environment.GetEnvironmentVariable("FIREBASE_CLIENT_CREDENTIALS_JSON");
            if (!string.IsNullOrEmpty(jsonClient))
            {
                _clientApp = FirebaseApp.GetInstance("ClientApp") ?? FirebaseApp.Create(new AppOptions()
                {
                    Credential = GoogleCredential.FromJson(jsonClient),
                    ProjectId = "h4h-client"
                }, "ClientApp");
            }
        }

        private FirebaseMessaging GetMessaging(bool isClientApp)
        {
            if (isClientApp)
                return FirebaseMessaging.GetMessaging(_clientApp);
            else
                return FirebaseMessaging.DefaultInstance;
        }

        public async Task<string> SendNotificationAsync(string fcmToken, string title, string body, string appointmentId, bool isClientApp = false)
        {
            var message = new Message()
            {
                Token = fcmToken,
                Notification = new Notification()
                {
                    Title = title,
                    Body = body
                },
                Data = new Dictionary<string, string>
                {
                    { "appointmentId", appointmentId },
                    { "screen", "offer" }
                },
                Android = new AndroidConfig() { Priority = Priority.High },
                Apns = new ApnsConfig() { Aps = new Aps() { ContentAvailable = true } }
            };

            var result = await GetMessaging(isClientApp).SendAsync(message);
            return result;
        }

        public async Task<string> SendNotificationAsync(string fcmToken, string title, string body, string appointmentId, string screen, bool isClientApp = false)
        {
            var message = new Message()
            {
                Token = fcmToken,
                Notification = new Notification()
                {
                    Title = title,
                    Body = body
                },
                Data = new Dictionary<string, string>
                {
                    { "appointmentId", appointmentId },
                    { "screen", screen }
                },
                Android = new AndroidConfig() { Priority = Priority.High },
                Apns = new ApnsConfig() { Aps = new Aps() { ContentAvailable = true } }
            };

            var result = await GetMessaging(isClientApp).SendAsync(message);
            return result;
        }

        public async Task SendNotificationToManyAsync(List<string> fcmTokens, string title, string body, string appointmentId, bool isClientApp = false)
        {
            if (fcmTokens == null || !fcmTokens.Any()) return;

            var messages = fcmTokens.Select(token => new Message()
            {
                Token = token,
                Notification = new Notification()
                {
                    Title = title,
                    Body = body
                },
                Data = new Dictionary<string, string>
                {
                    { "appointmentId", appointmentId },
                    { "screen", "offer" }
                },
                Android = new AndroidConfig() { Priority = Priority.High },
                Apns = new ApnsConfig() { Aps = new Aps() { ContentAvailable = true } }
            }).ToList();

            var response = await GetMessaging(isClientApp).SendEachAsync(messages);

            Console.WriteLine($"Success: {response.SuccessCount}, Failure: {response.FailureCount}");
        }

        public async Task SendNotificationToManyAsync(List<string> fcmTokens, string title, string body, string appointmentId, string screen, bool isClientApp = false)
        {
            if (fcmTokens == null || !fcmTokens.Any()) return;

            var messages = fcmTokens.Select(token => new Message()
            {
                Token = token,
                Notification = new Notification()
                {
                    Title = title,
                    Body = body
                },
                Data = new Dictionary<string, string>
                {
                    { "appointmentId", appointmentId },
                    { "screen", screen }
                },
                Android = new AndroidConfig() { Priority = Priority.High },
                Apns = new ApnsConfig() { Aps = new Aps() { ContentAvailable = true } }
            }).ToList();

            var response = await GetMessaging(isClientApp).SendEachAsync(messages);

            Console.WriteLine($"Success: {response.SuccessCount}, Failure: {response.FailureCount}");
        }
    }
}