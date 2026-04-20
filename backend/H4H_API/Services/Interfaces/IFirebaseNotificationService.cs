namespace H4H_API.Services.Interfaces
{
    public interface IFirebaseNotificationService
    {
        /// <summary>
        /// Sends a push notification to a device using the specified Firebase Cloud Messaging (FCM) token.
        /// </summary>
        /// <param name="fcmToken">The FCM device token that identifies the target device. Cannot be null or empty.</param>
        /// <param name="title">The title of the notification to display. Cannot be null.</param>
        /// <param name="body">The body text of the notification to display. Cannot be null.</param>
        /// <param name="isClientApp">true to send the notification to a client application; otherwise, false.</param>
        /// <returns>A task that represents the asynchronous operation. The task result contains the message ID of the sent
        /// notification.</returns>
        public Task<string> SendNotificationAsync(string fcmToken, string title, string body, string appointmentId, bool isClientApp = false);

        /// <summary>
        /// Sends a push notification with the specified title and body to multiple devices identified by their FCM
        /// tokens.
        /// </summary>
        /// <param name="fcmTokens">A list of Firebase Cloud Messaging (FCM) device tokens representing the recipients of the notification.
        /// Cannot be null or empty.</param>
        /// <param name="title">The title of the notification message to display to recipients. Cannot be null or empty.</param>
        /// <param name="body">The body content of the notification message to display to recipients. Cannot be null or empty.</param>
        /// <param name="appointmentId">The unique identifier of the appointment associated with the notification. Used to provide context or link
        /// the notification to a specific appointment.</param>
        /// <param name="isClientApp">true if the notification is intended for the client application; otherwise, false. This may affect the
        /// notification's formatting or delivery.</param>
        /// <returns>A task that represents the asynchronous operation of sending the notification.</returns>
        public Task SendNotificationToManyAsync(List<string> fcmTokens, string title, string body, string appointmentId, bool isClientApp = false);

    }
}
