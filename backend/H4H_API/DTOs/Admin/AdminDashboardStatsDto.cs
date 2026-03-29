namespace H4H_API.DTOs.Admin
{
    public class AdminDashboardStatsDto
    {
        /// <summary>
        /// Statystyki dla panelu administratora, takie jak liczba użytkowników, 
        /// klientów, specjalistów, oczekujących specjalistów i liczba umówionych wizyt.
        /// </summary>
        public int TotalUsers { get; set; }
        public int TotalClients { get; set; }
        public int TotalSpecialists { get; set; }
        public int PendingSpecialists { get; set; }
        public int TotalAppointments { get; set; }

        //mozna ew dodac kiedys te przychody albo cos
    }
}