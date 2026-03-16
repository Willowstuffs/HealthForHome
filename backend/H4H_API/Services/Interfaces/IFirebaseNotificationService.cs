namespace H4H_API.Services.Interfaces
{
    public interface IFirebaseNotificationService
    {
        /// <summary>
        /// wysyłąnie powiadomienia do pojedyńczego tokena FCM
        /// </summary>
        /// <param name="fcmToken"></param>
        /// <param name="title"></param>
        /// <param name="body"></param>
        /// <returns></returns>
        public Task<string> SendNotificationAsync(string fcmToken, string title, string body);

    }
}
