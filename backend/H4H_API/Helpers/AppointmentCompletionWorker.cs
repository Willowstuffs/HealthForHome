using H4H.Data;
using H4H_API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace H4H_API.Helpers
{
    public class AppointmentCompletionWorker : BackgroundService
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<AppointmentCompletionWorker> _logger;

        public AppointmentCompletionWorker(IServiceScopeFactory scopeFactory, ILogger<AppointmentCompletionWorker> logger)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            while (!stoppingToken.IsCancellationRequested) //do zatrzymania
            {
                try 
                {
                    using var scope = _scopeFactory.CreateScope(); 
                    var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
                    //teraz interfejs a nie klasa
                    var lifecycle = scope.ServiceProvider.GetRequiredService<IAppointmentsLifeCycleServer>();

                    var now = DateTime.UtcNow;

                    //sukces przy auto completion
                    var toComplete = await context.appointments
                        .Where(a => (a.AppointmentStatus == "confirmed" || a.AppointmentStatus == "in_progress") && //tylko confirmed i in_progress (niezakończone samemu)
                                    a.ScheduledEnd < now)
                        .ToListAsync(stoppingToken);

                    foreach (var appointment in toComplete)
                    {
                        await lifecycle.CompleteAppointmentAsync(appointment);
                        _logger.LogInformation($"Wizyta {appointment.Id} automatycznie zakończona.");
                    }

                    // Wygasłe ogłoszenia, tylko open i pending
                    var toCancel = await context.appointments
                        .Where(a => (a.AppointmentStatus == "open" || a.AppointmentStatus == "pending") &&
                                    a.ScheduledEnd < now)
                        .ToListAsync(stoppingToken);

                    foreach (var appointment in toCancel)
                    {
                        await lifecycle.CancelAppointmentAsync(appointment);
                        _logger.LogInformation($"Ogłoszenie {appointment.Id} automatycznie anulowane (wygasło).");
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Błąd podczas pracy AppointmentCompletionWorker.");
                }
                //na przyszlosc da sie co X minut
                await Task.Delay(TimeSpan.FromDays(1), stoppingToken);
            }
        }
    }
}
