using H4H.Data;
using H4H_API.Services.Implementations;
using Microsoft.EntityFrameworkCore;

namespace H4H_API.Helpers
{
    public class AppointmentCompletionWorker : BackgroundService
    {
        private readonly IServiceScopeFactory _scopeFactory;

        public AppointmentCompletionWorker(IServiceScopeFactory scopeFactory)
        {
            _scopeFactory = scopeFactory;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            while (!stoppingToken.IsCancellationRequested)
            {
                using var scope = _scopeFactory.CreateScope();

                var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
                var lifecycle = scope.ServiceProvider.GetRequiredService<AppointmentsLifeCycleService>();

                var now = DateTime.Now;

                var appointments = await context.appointments
                    .Where(a =>
                        a.AppointmentStatus == "confirmed" &&
                        a.FinalDate < now)
                    .ToListAsync();

                foreach (var appointment in appointments)
                {
                    await lifecycle.CompleteAppointmentAsync(appointment);
                }

                appointments = await context.appointments
                    .Where(a =>
                        a.AppointmentStatus != "confirmed" &&
                        a.AppointmentStatus != "cancelled" &&
                        a.ScheduledEnd < now)
                    .ToListAsync();

                foreach (var appointment in appointments)
                {
                    await lifecycle.CancelAppointmentAsync(appointment);
                }

                await Task.Delay(TimeSpan.FromMinutes(5), stoppingToken);
            }
        }
    }
}
