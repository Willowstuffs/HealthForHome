using H4H.Core.Models;
using H4H.Data;
using H4H_API.DTOs.Admin;
using H4H_API.DTOs.Common;
using H4H_API.Services.Interfaces;
using H4H_API.Helpers; //Do bledow
using Microsoft.EntityFrameworkCore;
using H4H_API.Exceptions;

namespace H4H_API.Services.Implementations
{
    public class AdminService : IAdminService
    {
        private readonly ApplicationDbContext _context;
        public AdminService(ApplicationDbContext context)
        {
            _context = context; //kontekst bazy danych
        }
        /// <summary>
        /// Otrzymuje liste specjalistow z mozliwoscia filtrowania po statusie weryfikacji i dacie rejestracji,
        /// sortowania po dacie rejestracji oraz paginacji. Ta metoda jest przeznaczona dla administratorów do 
        /// przeglądania i zarządzania zgłoszeniami specjalistów oczekujących na weryfikację.</summary>
        /// <param name="filter">
        /// Obiekt zawierający opcje filtrowania, sortowania i paginacji do zastosowania przy wyborze specjalistów. Nie może być nullem.</param>
        /// <returns>
        /// Zwraca paged response zawierający listę specjalistów, którzy spełniają kryteria filtrowania, wraz z informacjami o paginacji 
        /// (aktualna strona, rozmiar strony, łączna liczba elementów).</returns>
        public async Task<PagedResponse<AdminSpecialistListItemDto>> GetSpecialistsAsync(AdminSpecialistFilterDto filter)
        {
            var query = _context.specialists
                .Include(s => s.User)
                .AsQueryable();

            //Filtrowanie
            if (!string.IsNullOrEmpty(filter.VerificationStatus))
                query = query.Where(s => s.VerificationStatus == filter.VerificationStatus);

            if (filter.RegisteredFrom.HasValue)
                query = query.Where(s => s.CreatedAt >= filter.RegisteredFrom.Value);

            if (filter.RegisteredTo.HasValue)
                query = query.Where(s => s.CreatedAt <= filter.RegisteredTo.Value);

            //Sortowanie (domyślnie po dacie rejestracji malejąco)
            query = filter.SortDescending
                ? query.OrderByDescending(s => s.CreatedAt)
                : query.OrderBy(s => s.CreatedAt);

            //Paginacja, czyli najpierw liczymy łączną liczbę elementów, a następnie pobieramy tylko te,
            //które odpowiadają aktualnej stronie i rozmiarowi strony
            var totalCount = await query.CountAsync();
            var items = await query
                .Skip((filter.Page - 1) * filter.PageSize)
                .Take(filter.PageSize)
                .Select(s => new AdminSpecialistListItemDto
                {
                    SpecialistId = s.Id,
                    FirstName = s.FirstName,
                    LastName = s.LastName,
                    Email = s.User.Email,
                    ProfessionalTitle = s.ProfessionalTitle ?? string.Empty, //CS8601 fix
                    VerificationStatus = s.VerificationStatus,
                    CreatedAt = s.CreatedAt
                })
                .ToListAsync();

            return new PagedResponse<AdminSpecialistListItemDto>
            {
                Items = items,
                Page = filter.Page,
                PageSize = filter.PageSize,
                TotalCount = totalCount
            };
        }
        /// <summary>
        /// Asynchronicznie pobiera szczegółowe informacje o specjaliście do celów administracyjnych, 
        /// w tym dane osobowe, informacje kontaktowe, status weryfikacji, oraz aktywne kwalifikacje.</summary>
        /// <remarks>
        /// Zwracane szczegóły obejmują zarówno podstawowy profil specjalisty, jak i jego aktywne kwalifikacje, 
        /// jeśli są dostępne. Pola dotyczące kwalifikacji mogą być nullem, jeśli specjalista nie posiada aktywnych kwalifikacji. 
        /// Ta metoda jest przeznaczona do użytku administracyjnego i może ujawniać wrażliwe informacje.</remarks>
        public async Task<AdminSpecialistDetailsDto> GetSpecialistDetailsAsync(Guid specialistId)
        {
            var specialist = await _context.specialists
                .Include(s => s.User)
                .FirstOrDefaultAsync(s => s.Id == specialistId)
                ?? throw new AppException ("Nie znaleziono specjalisty.", ErrorCodes.SpecialistNotFound);
            var qualifications = await _context.specialist_qualifications
                .FirstOrDefaultAsync(q => q.SpecialistId == specialistId && q.IsActive);

            return new AdminSpecialistDetailsDto
            {
                SpecialistId = specialist.Id,
                FirstName = specialist.FirstName,
                LastName = specialist.LastName,
                Email = specialist.User.Email,
                PhoneNumber = specialist.User.PhoneNumber,
                ProfessionalTitle = specialist.ProfessionalTitle ?? string.Empty,
                Bio = specialist.Bio,
                VerificationStatus = specialist.VerificationStatus,
                IsVerified = specialist.IsVerified,
                CreatedAt = specialist.CreatedAt,
                LicenseNumber = qualifications?.LicenseNumber,
                LicensePhotoUrl = qualifications?.LicensePhotoUrl,
                IdCardPhotoUrl = qualifications?.IdCardPhotoUrl,
                VerificationNotes = qualifications?.VerificationNotes
            };
        }
        /// <summary>Zatwierdza specjaliste aktualizując status weryfikacji i logując akcje wykonaną przez admina</summary>
        public async Task ApproveSpecialistAsync(Guid specialistId, Guid adminId)
        {
            var specialist = await _context.specialists.FindAsync(specialistId)
                ?? throw new AppException("Profil specjalisty nie istnieje.", ErrorCodes.SpecialistNotFound);

            specialist.VerificationStatus = "approved";
            specialist.IsVerified = true;
            specialist.VerifiedAt = DateTime.UtcNow;
            Console.WriteLine(adminId);
            // Logowanie akcji admina
            _context.verification_logs.Add(new VerificationLog
            {
                Id = Guid.NewGuid(),
                SpecialistId = specialistId,
                AdminId = adminId,
                Action = "approved",
                CreatedAt = DateTime.UtcNow
            });

            await _context.SaveChangesAsync();
        }

        /// <summary>Odrzuca specjaliste zmieniajac status weryfikacji na rejected i logujac akcje wykonana przez admina z powodem odrzucenia.</summary>
        public async Task RejectSpecialistAsync(Guid specialistId, Guid adminId, string reason)
        {
            var specialist = await _context.specialists.FindAsync(specialistId)
                ?? throw new AppException("Profil specjalisty nie istnieje.", ErrorCodes.SpecialistNotFound);

            specialist.VerificationStatus = "rejected";
            specialist.IsVerified = false;

            // Logowanie akcji admina
            _context.verification_logs.Add(new VerificationLog
            {
                Id = Guid.NewGuid(),
                SpecialistId = specialistId,
                AdminId = adminId,
                Action = "rejected",
                Notes = reason, // Powód odrzucenia
                CreatedAt = DateTime.UtcNow
            });

            await _context.SaveChangesAsync();
        }


        /// <summary>
        /// Otrzymuje liste klientow z mozliwoscia filtrowania po imieniu, nazwisku i emailu, sortowania po dacie rejestracji oraz paginacji.
        /// </summary>
        /// <param name="filter"></param>
        /// <returns></returns>
        public async Task<PagedResponse<AdminClientListItemDto>> GetClientsAsync(AdminClientFilterDto filter)
        {
            //Podobnie jak w przypadku specjalistów, zaczynamy od zbudowania zapytania do bazy danych,
            //które pobiera klientów wraz z powiązanymi danymi (użytkownik i wizyty).
            var query = _context.clients
                .Include(c => c.User)
                .Include(c => c.Appointments)
                .AsQueryable();

            //Filtrowanie po imieniu, nazwisku i emailu (jeśli podano searchTerm)
            if (!string.IsNullOrWhiteSpace(filter.SearchTerm))
            {
                var search = filter.SearchTerm.ToLower();
                query = query.Where(c =>
                    c.FirstName.ToLower().Contains(search) ||
                    c.LastName.ToLower().Contains(search) ||
                    c.User.Email.ToLower().Contains(search));
            }

            //Paginacja - najpierw liczymy łączną liczbę elementów,
            //a następnie pobieramy tylko te, które odpowiadają aktualnej stronie i rozmiarowi strony
            var totalItems = await query.CountAsync();

            //Pobieramy klientów z bazy danych, sortujemy po dacie rejestracji malejąco, a następnie stosujemy paginację
            var items = await query
                .OrderByDescending(c => c.CreatedAt)
                .Skip((filter.Page - 1) * filter.PageSize) 
                .Take(filter.PageSize)
                .Select(c => new AdminClientListItemDto
                {
                    ClientId = c.Id,
                    FirstName = c.FirstName,
                    LastName = c.LastName,
                    Email = c.User.Email,
                    CreatedAt = c.CreatedAt,
                    TotalAppointments = c.Appointments.Count
                })
                .ToListAsync();

            // Na koniec zwracamy paged response zawierający listę klientów oraz informacje o paginacji
            return new PagedResponse<AdminClientListItemDto>
            {
                Items = items,
                Page = filter.Page,
                PageSize = filter.PageSize,
                TotalCount = totalItems
            };
        }

        /// <summary>
        /// Pobiera szczegółowe informacje o kliencie, w tym dane osobowe, kontaktowe oraz historię wizyt.
        /// </summary>
        /// <param name="clientId"></param>
        /// <returns></returns>
        /// <exception cref="AppException"></exception>
        public async Task<AdminClientDetailsDto> GetClientDetailsAsync(Guid clientId)
        {
            // Pobieramy klienta z bazy danych wraz z powiązanymi danymi (użytkownik i wizyty).
            // Jeśli klient o podanym ID nie istnieje, rzucamy wyjątek AppException.
            var client = await _context.clients
                .Include(c => c.User)
                .Include(c => c.Appointments)
                    .ThenInclude(a => a.ServiceType)
                .FirstOrDefaultAsync(c => c.Id == clientId)
                ?? throw new AppException("Nie znaleziono klienta.", ErrorCodes.ClientNotFound);

            // Mapujemy dane klienta na DTO, w tym listę wizyt klienta, która zawiera informacje o dacie i godzinie wizyty,
            // nazwie usługi, statusie oraz cenie. Wizyty są sortowane malejąco po dacie planowanego rozpoczęcia.
            return new AdminClientDetailsDto
            {
                ClientId = client.Id,
                FirstName = client.FirstName,
                LastName = client.LastName,
                Email = client.User.Email,
                PhoneNumber = client.User.PhoneNumber,
                CreatedAt = client.CreatedAt,
                Appointments = client.Appointments.Select(a => new AdminClientAppointmentDto
                {
                    AppointmentId = a.Id,
                    ScheduledStart = a.ScheduledStart,
                    ServiceName = a.ServiceType?.Name ?? "Nieokreślona",
                    Status = a.AppointmentStatus,
                    Price = a.TotalPrice
                }).OrderByDescending(a => a.ScheduledStart).ToList()
            };
        }

        /// <summary>
        /// Pobiera statystyki dla dashboardu administratora, takie jak łączna liczba użytkowników, 
        /// klientów, specjalistów, specjalistów oczekujących na weryfikację oraz wizyt.
        /// </summary>
        /// <returns></returns>
        public async Task<AdminDashboardStatsDto> GetDashboardStatsAsync()
        {
            // Pobieramy dane dla czytelności po kolei:
            var stats = new AdminDashboardStatsDto
            {
                TotalUsers = await _context.users.CountAsync(),
                TotalClients = await _context.clients.CountAsync(),
                TotalSpecialists = await _context.specialists.CountAsync(),

                // Zliczamy tylko tych specjalistów, którzy czekają na weryfikację
                PendingSpecialists = await _context.specialists
                    .CountAsync(s => s.VerificationStatus == "pending"),

                TotalAppointments = await _context.appointments.CountAsync()
            };

            return stats;
        }

        /// <summary>
        /// Pobiera listę wizyt z możliwością filtrowania po statusie i zakresie dat, sortowania po dacie oraz paginacji.
        /// </summary>
        /// <param name="filter"></param>
        /// <returns></returns>
        public async Task<PagedResponse<AdminAppointmentListItemDto>> GetAppointmentsAsync(AdminAppointmentFilterDto filter)
        {
            var query = _context.appointments
                .Include(a => a.ServiceType)
                .AsQueryable();

            // Filtrowanie po statusie
            if (!string.IsNullOrEmpty(filter.Status))
                query = query.Where(a => a.AppointmentStatus == filter.Status);

            // Filtrowanie po dacie
            if (filter.FromDate.HasValue)
                query = query.Where(a => a.ScheduledStart >= filter.FromDate.Value);

            if (filter.ToDate.HasValue)
                query = query.Where(a => a.ScheduledStart <= filter.ToDate.Value);

            var totalCount = await query.CountAsync();

            var items = await query
                .OrderByDescending(a => a.ScheduledStart)
                .Skip((filter.Page - 1) * filter.PageSize) // Używamy .Page z PagedRequest
                .Take(filter.PageSize)
                .Select(a => new AdminAppointmentListItemDto
                {
                    AppointmentId = a.Id,
                    ContactName = a.ContactName ?? "Brak danych",
                    ServiceName = a.ServiceType.Name ?? "Nieokreślona",
                    ScheduledStart = a.ScheduledStart,
                    Status = a.AppointmentStatus,
                    TotalPrice = a.TotalPrice,
                    ClientAddress = a.ClientAddress ?? "Brak adresu"
                })
                .ToListAsync();

            // Na koniec zwracamy paged response zawierający listę wizyt oraz informacje o paginacji
            return new PagedResponse<AdminAppointmentListItemDto>
            {
                Items = items,
                Page = filter.Page,
                PageSize = filter.PageSize,
                TotalCount = totalCount
            };
        }
    }
}