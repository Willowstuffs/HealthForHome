using H4H.Core.Models;
using H4H.Data;
using H4H_API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace H4H_API.Services.Implementations
{
    public class AppointmentsLifeCycleService: IAppointmentsLifeCycleServer
    {
        private readonly ApplicationDbContext _context;
        private readonly FirebaseNotificationService _firebase;

        public AppointmentsLifeCycleService(
            ApplicationDbContext context,
            FirebaseNotificationService firebase)
        {
            _context = context;
            _firebase = firebase;
        }

        public async Task CompleteAppointmentAsync(Appointment appointment)
        {
            if (appointment.AppointmentStatus != "confirmed")
                return;

            appointment.AppointmentStatus = "completed";
            appointment.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            await SendCompletedNotification(appointment);
        }
        private async Task SendCompletedNotification(Appointment appointment)
        {
            var clientUserId = await _context.clients
                .Where(c => c.Id == appointment.ClientId)
                .Select(c => c.UserId)
                .FirstAsync();

            var tokens = await _context.device_tokens
                .Where(t => t.UserId == clientUserId)
                .Select(t => t.FcmToken)
                .ToListAsync();
            if (!tokens.Any())
                return;
            await _firebase.SendNotificationToManyAsync(
                tokens,
                "Wizyta zakończona",
                "Twoja wizyta została zakończona. Oceń specjalistę ⭐",
                appointment.Id.ToString(),
                true
            );
        }

       
    }
}
   
