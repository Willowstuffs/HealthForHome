using H4H.Core.Models;
using H4H.Data;
using H4H_API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace H4H_API.Services.Implementations
{
    public class AppointmentsLifeCycleService : IAppointmentsLifeCycleServer
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

        public async Task CancelAppointmentAsync(Appointment appointment)
        {
            // Jeśli już jest anulowana lub zakończona, nic nie rób
            if (appointment.AppointmentStatus == "cancelled" || appointment.AppointmentStatus == "completed")
                return;

            appointment.AppointmentStatus = "cancelled";
            appointment.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
        }

        public async Task RemoveSpecialistOfferAsync(Guid appointmentId, Guid specialistId)
        {
            // Usuwanie oferty specjalisty z wizyty
            var offer = await _context.Set<AppointmentSpecialist>()
                .FirstOrDefaultAsync(os => os.AppointmentId == appointmentId && os.SpecialistId == specialistId);

            if (offer != null)
            {
                _context.Set<AppointmentSpecialist>().Remove(offer);
                await _context.SaveChangesAsync();
            }
        }

        // Wycofanie oferty specjalisty, przywraca wizyte na rynek
        public async Task ResetAppointmentToOpenAsync(Appointment appointment)
        {
            //Czyszczenie danych przypisanych przez poprzedniego specjalistę
            appointment.SpecialistId = null;
            appointment.AppointmentStatus = "open";
            appointment.TotalPrice = null;
            appointment.FinalDate = null;
            appointment.SpecialistServiceIds = Array.Empty<Guid>();
            appointment.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
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
                "rating",
                true
            );
        }
    }
}

