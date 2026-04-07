using H4H.Core.Models;
using H4H.Data;
using H4H_API.DTOs.Appointments;
using H4H_API.DTOs.Admin;
using H4H_API.DTOs.Common;
using H4H_API.Services.Interfaces;
using H4H_API.Helpers;
using Microsoft.EntityFrameworkCore;
using H4H_API.Exceptions;
using System.Linq.Expressions;

namespace H4H_API.Services.Implementations
{
    public class AdminService : IAdminService
    {
        private readonly IEmailService _emailService;
        private readonly ApplicationDbContext _context;

        public AdminService(ApplicationDbContext context, IEmailService emailService)
        {
            _context = context;
            _emailService = emailService;
        }
        /// <summary>
        /// Otrzymuje liste specjalistow z mozliwoscia filtrowania po statusie weryfikacji i dacie rejestracji,
        /// sortowania po dacie rejestracji oraz paginacji.
        /// </summary>
        public async Task<PagedResponse<AdminSpecialistListItemDto>> GetSpecialistsAsync(AdminSpecialistFilterDto filter)
        {
            var query = _context.specialists
                .Include(s => s.User)
                .Include(s => s.Qualifications)
                .AsQueryable();

            if (!string.IsNullOrEmpty(filter.VerificationStatus))
                query = query.Where(s => s.VerificationStatus == filter.VerificationStatus);

            if (filter.RegisteredFrom.HasValue)
                query = query.Where(s => s.CreatedAt >= filter.RegisteredFrom.Value);

            if (filter.RegisteredTo.HasValue)
                query = query.Where(s => s.CreatedAt <= filter.RegisteredTo.Value);

            query = filter.SortDescending
                ? query.OrderByDescending(s => s.CreatedAt)
                : query.OrderBy(s => s.CreatedAt);

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
                    ProfessionalTitle = s.ProfessionalTitle ?? string.Empty,
                    VerificationStatus = s.VerificationStatus,
                    CreatedAt = s.CreatedAt,
                    LicenseValidUntil = s.Qualifications
                        .Where(q => q.IsActive)
                        .Select(q => q.LicenseValidUntil)
                        .FirstOrDefault()
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
        /// Pobiera szczegółowe informacje o specjaliście.
        /// </summary>
        public async Task<AdminSpecialistDetailsDto> GetSpecialistDetailsAsync(Guid specialistId)
        {
            var specialist = await _context.specialists
                .Include(s => s.User)
                .FirstOrDefaultAsync(s => s.Id == specialistId)
                ?? throw new AppException("Nie znaleziono specjalisty.", ErrorCodes.SpecialistNotFound);

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
                VerificationNotes = qualifications?.VerificationNotes,
                LicenseValidUntil = qualifications?.LicenseValidUntil
            };
        }

        /// <summary>
        /// Zatwierdza specjalistę.
        /// </summary>
        public async Task ApproveSpecialistAsync(Guid specialistId, Guid adminId)
        {
            var specialist = await _context.specialists
                .Include(s => s.User)
                .FirstOrDefaultAsync(s => s.Id == specialistId)
                ?? throw new AppException("Profil specjalisty nie istnieje.", ErrorCodes.SpecialistNotFound);

            specialist.VerificationStatus = "approved";
            specialist.IsVerified = true;
            specialist.VerifiedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            try
            {
                await _emailService.SendEmailAsync(
                    specialist.User.Email,
                    "Weryfikacja konta specjalisty - zaakceptowano",
                    $@"
            <p>Dzień dobry {specialist.FirstName},</p>
            <p>Twoje konto specjalisty w <strong>Health4Home</strong> zostało zaakceptowane.</p>
            <p>Możesz teraz korzystać z funkcji dostępnych dla zweryfikowanych specjalistów.</p>
            <p>Pozdrawiamy,<br/>Zespół Health4Home</p>
            ");
            }
            catch
            {
            }
        }

        /// <summary>
        /// Odrzuca specjalistę.
        /// </summary>
        public async Task RejectSpecialistAsync(Guid specialistId, Guid adminId, string reason)
        {
            var specialist = await _context.specialists
                .Include(s => s.User)
                .FirstOrDefaultAsync(s => s.Id == specialistId)
                ?? throw new AppException("Profil specjalisty nie istnieje.", ErrorCodes.SpecialistNotFound);

            specialist.VerificationStatus = "rejected";
            specialist.IsVerified = false;

            await _context.SaveChangesAsync();

            var rejectionReason = string.IsNullOrWhiteSpace(reason)
                ? "Nie podano powodu."
                : reason;

            try
            {
                await _emailService.SendEmailAsync(
                    specialist.User.Email,
                    "Weryfikacja konta specjalisty - odrzucono",
                    $@"
            <p>Dzień dobry {specialist.FirstName},</p>
            <p>Twoje konto specjalisty w <strong>Health4Home</strong> zostało odrzucone.</p>
            <p><strong>Powód:</strong> {rejectionReason}</p>
            <p>W razie potrzeby popraw dane i spróbuj ponownie.</p>
            <p>Pozdrawiamy,<br/>Zespół Health4Home</p>
            ");
            }
            catch
            {
            }
        }
        /// <summary>
        /// Licencja specjalisty - aktualizuje datę ważności licencji w tabeli specialist_qualifications. 
        /// Jeśli rekord kwalifikacji dla specjalisty nie istnieje, zostanie utworzony nowy z podaną datą ważności licencji.
        /// </summary>
        public async Task UpdateLicenseValidityAsync(Guid specialistId, DateTime validUntil)
        {
            var specialist = await _context.specialists
                .FirstOrDefaultAsync(s => s.Id == specialistId)
                ?? throw new AppException("Nie znaleziono specjalisty.", ErrorCodes.SpecialistNotFound);

            var qualification = await _context.specialist_qualifications
                .FirstOrDefaultAsync(q => q.SpecialistId == specialistId && q.IsActive);

            if (qualification == null)
            {
                qualification = new SpecialistQualification
                {
                    Id = Guid.NewGuid(),
                    SpecialistId = specialistId,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow,
                    Profession = NormalizeProfession(specialist.ProfessionalTitle)
                };

                _context.specialist_qualifications.Add(qualification);
            }

            qualification.LicenseValidUntil = validUntil;

            await _context.SaveChangesAsync();
        }
        private string NormalizeProfession(string? professionalTitle)
        {
            var value = professionalTitle?.Trim().ToLower();

            return value switch
            {
                "physiotherapist" => "physiotherapist",
                "fizjoterapeuta" => "physiotherapist",
                "mgr fizjoterapii" => "physiotherapist",

                "nurse" => "nurse",
                "pielęgniarka" => "nurse",
                "pielegniarka" => "nurse",

                _ => throw new AppException(
                    $"Nieobsługiwany zawód: '{professionalTitle}'",
                    ErrorCodes.ValidationError)
            };
        }

        /// <summary>
        /// Otrzymuje listę klientów z możliwością filtrowania i paginacji.
        /// </summary>
        public async Task<PagedResponse<AdminClientListItemDto>> GetClientsAsync(AdminClientFilterDto filter)
        {
            var query = _context.clients
                .Include(c => c.User)
                .Include(c => c.Appointments)
                .AsQueryable();

            if (!string.IsNullOrWhiteSpace(filter.SearchTerm))
            {
                var search = filter.SearchTerm.ToLower();
                query = query.Where(c =>
                    c.FirstName.ToLower().Contains(search) ||
                    c.LastName.ToLower().Contains(search) ||
                    c.User.Email.ToLower().Contains(search));
            }

            var totalItems = await query.CountAsync();

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
                    PhoneNumber = c.User.PhoneNumber,
                    CreatedAt = c.CreatedAt,
                    TotalAppointments = c.Appointments.Count
                })
                .ToListAsync();

            return new PagedResponse<AdminClientListItemDto>
            {
                Items = items,
                Page = filter.Page,
                PageSize = filter.PageSize,
                TotalCount = totalItems
            };
        }

        /// <summary>
        /// Pobiera szczegółowe informacje o kliencie.
        /// </summary>
        public async Task<AdminClientDetailsDto> GetClientDetailsAsync(Guid clientId)
        {
            var client = await _context.clients
                .Include(c => c.User)
                .Include(c => c.Appointments)
                .FirstOrDefaultAsync(c => c.Id == clientId)
                ?? throw new AppException("Nie znaleziono klienta.", ErrorCodes.ClientNotFound);

            return new AdminClientDetailsDto
            {
                ClientId = client.Id,
                FirstName = client.FirstName,
                LastName = client.LastName,
                Email = client.User.Email,
                PhoneNumber = client.User.PhoneNumber,
                CreatedAt = client.CreatedAt,
                Appointments = client.Appointments
                    .OrderByDescending(a => a.CreatedAt)
                    .Select(a => new AdminClientAppointmentDto
                    {
                        AppointmentId = a.Id,
                        ScheduledStart = a.ScheduledStart,
                        Status = a.AppointmentStatus,
                        Price = a.TotalPrice
                    })
                    .ToList()
            };
        }

        /// <summary>
        /// Pobiera statystyki dla dashboardu administratora.
        /// </summary>
        public async Task<AdminDashboardStatsDto> GetDashboardStatsAsync()
        {
            var stats = new AdminDashboardStatsDto
            {
                TotalUsers = await _context.users.CountAsync(),
                TotalClients = await _context.clients.CountAsync(),
                TotalSpecialists = await _context.specialists.CountAsync(),
                PendingSpecialists = await _context.specialists.CountAsync(s => s.VerificationStatus == "pending"),
                TotalAppointments = await _context.appointments.CountAsync()
            };

            return stats;
        }

        /// <summary>
        /// Pobiera listę wizyt z możliwością filtrowania po statusie i zakresie dat.
        /// </summary>
        public async Task<PagedResponse<AdminAppointmentListItemDto>> GetAppointmentsAsync(AdminAppointmentFilterDto filter)
        {
            var query = _context.appointments.AsQueryable();

            if (!string.IsNullOrEmpty(filter.Status))
                query = query.Where(a => a.AppointmentStatus == filter.Status);

            if (filter.FromDate.HasValue)
                query = query.Where(a => a.ScheduledStart >= filter.FromDate.Value);

            if (filter.ToDate.HasValue)
                query = query.Where(a => a.ScheduledStart <= filter.ToDate.Value);

            var totalCount = await query.CountAsync();

            var items = await query
                .OrderByDescending(a => a.ScheduledStart)
                .Skip((filter.Page - 1) * filter.PageSize)
                .Take(filter.PageSize)
                .Select(a => new AdminAppointmentListItemDto
                {
                    AppointmentId = a.Id,
                    ContactName = a.ContactName,
                    ServiceName = "Nieokreślona",
                    ScheduledStart = a.ScheduledStart,
                    Status = a.AppointmentStatus,
                    TotalPrice = a.TotalPrice,
                    ClientAddress = a.ClientAddress ?? "Brak adresu",
                    CreatedAt = a.CreatedAt
                })
                .ToListAsync();

            return new PagedResponse<AdminAppointmentListItemDto>
            {
                Items = items,
                Page = filter.Page,
                PageSize = filter.PageSize,
                TotalCount = totalCount
            };
        }

        /// <summary>
        /// Tworzy nową wizytę.
        /// </summary>
        public async Task<Guid> CreateAppointmentAsync(CreateAppointmentDto dto)
        {
            var clientExists = await _context.clients.AnyAsync(c => c.Id == dto.ClientId);
            if (!clientExists)
                throw new Exception("Klient nie istnieje.");

            if (dto.SpecialistId.HasValue)
            {
                var specialistExists = await _context.specialists.AnyAsync(s => s.Id == dto.SpecialistId.Value);
                if (!specialistExists)
                    throw new Exception("Specjalista nie istnieje.");
            }

            if (dto.SpecialistServiceId.HasValue)
            {
                var specialistServiceExists = await _context.specialist_services.AnyAsync(ss => ss.Id == dto.SpecialistServiceId.Value);
                if (!specialistServiceExists)
                    throw new Exception("Usługa specjalisty nie istnieje.");
            }

            if (dto.ServiceTypeId.HasValue)
            {
                var serviceTypeExists = await _context.service_types.AnyAsync(st => st.Id == dto.ServiceTypeId.Value);
                if (!serviceTypeExists)
                    throw new Exception("Typ usługi nie istnieje.");
            }

            if (dto.ScheduledEnd <= dto.ScheduledStart)
                throw new Exception("Data zakończenia musi być późniejsza niż data rozpoczęcia.");

            var appointment = new Appointment
            {
                Id = Guid.NewGuid(),
                ClientId = dto.ClientId,
                SpecialistId = dto.SpecialistId,
                SpecialistServiceId = dto.SpecialistServiceId,
                ServiceTypeId = dto.ServiceTypeId,
                ScheduledStart = DateTime.SpecifyKind(dto.ScheduledStart, DateTimeKind.Unspecified),
                ScheduledEnd = DateTime.SpecifyKind(dto.ScheduledEnd, DateTimeKind.Unspecified),
                TotalPrice = dto.TotalPrice,
                ClientAddress = dto.ClientAddress,
                ContactName = dto.ContactName,
                ContactPhoneNumber = dto.ContactPhoneNumber,
                ContactEmail = dto.ContactEmail,
                ClientNotes = dto.ClientNotes,
                SpecialistNotes = dto.SpecialistNotes,
                SelectedSpecialistId = dto.SelectedSpecialistId,
                AppointmentStatus = "pending",
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _context.appointments.Add(appointment);
            await _context.SaveChangesAsync();

            return appointment.Id;
        }
        public async Task<AdminAppointmentListItemDto> GetAppointmentByIdAsync(Guid id)
        {
            var appointment = await _context.appointments
                .Include(a => a.Specialist)
                .FirstOrDefaultAsync(a => a.Id == id);

            if (appointment == null)
                throw new AppException("Nie znaleziono wizyty.", "APPOINTMENT_NOT_FOUND");

            return new AdminAppointmentListItemDto
            {
                AppointmentId = appointment.Id,
                ContactName = appointment.ContactName,
                ServiceName = "Nieokreślona",
                ScheduledStart = appointment.ScheduledStart,
                Status = appointment.AppointmentStatus,
                TotalPrice = appointment.TotalPrice,
                ClientAddress = appointment.ClientAddress,
                ContactEmail = appointment.ContactEmail,
                ContactPhoneNumber = appointment.ContactPhoneNumber,
                ClientNotes = appointment.ClientNotes,
                CreatedAt = appointment.CreatedAt,
                SpecialistName = appointment.Specialist != null
                    ? $"{appointment.Specialist.FirstName} {appointment.Specialist.LastName}"
                    : null
            };
        }
    }
}