using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;
using H4H.Core.Models;
using Message = FirebaseAdmin.Messaging.Message;
using Notification = FirebaseAdmin.Messaging.Notification;

namespace H4H_API.Services.Implementations
{
    public class FirebaseNotificationService
    {
        
        private readonly FirebaseApp _app;

        public FirebaseNotificationService()
        {
            // Sprawdzenie, czy domyślny app już istnieje
            _app = FirebaseApp.DefaultInstance ?? FirebaseApp.Create(new AppOptions()
            {
                Credential = GoogleCredential.FromFile("Firebase/test-e1dc5-firebase-adminsdk-fbsvc-1ab20af410.json"),
                ProjectId = "test-e1dc5" // dokładnie jak w pliku JSON i projekcie Firebase
            });
        }

        // Wysyłanie powiadomienia do pojedynczego tokena FCM
        public async Task<string> SendNotificationAsync(string fcmToken, string title, string body)
        {
            var message = new Message()
            {
                Token = fcmToken,
                Notification = new Notification()
                {
                    Title = title,
                    Body = body
                },
                Android = new AndroidConfig()
                {
                    Priority = Priority.High
                },
                Apns = new ApnsConfig()
                {
                    Aps = new Aps()
                    {
                        ContentAvailable = true
                    }
                }
            };

            var result = await FirebaseMessaging.DefaultInstance.SendAsync(message);
            return result; // Zwraca messageId
        }
        public async Task SendNotificationToManyAsync(List<string> fcmTokens,string title,string body,string appointmentId)
        {
            if (fcmTokens == null || !fcmTokens.Any())
                return;

            var messages = fcmTokens.Select(token => new Message()
            {
                Token = token,

                Notification = new Notification
                {
                    Title = title
                },

                Data = new Dictionary<string, string>
                {
                    { "appointmentId", appointmentId },
                    { "screen", "offer" }
                },

                Android = new AndroidConfig()
                {
                    Priority = Priority.High
                },

                Apns = new ApnsConfig()
                {
                    Aps = new Aps()
                    {
                        ContentAvailable = true
                    }
                }

            }).ToList();
            Console.WriteLine(messages);

            var response = await FirebaseMessaging.DefaultInstance.SendEachAsync(messages);

            Console.WriteLine(
                $"Success: {response.SuccessCount}, Failure: {response.FailureCount}");
        }

    }
}
