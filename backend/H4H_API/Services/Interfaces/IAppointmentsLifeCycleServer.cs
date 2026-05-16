using H4H.Core.Models;

namespace H4H_API.Services.Interfaces
{
    public interface IAppointmentsLifeCycleServer
    {
        Task CompleteAppointmentAsync(Appointment appointment);
        Task CancelAppointmentAsync(Appointment appointment);
    }
}
