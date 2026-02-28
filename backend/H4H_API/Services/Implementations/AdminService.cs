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
                ProfessionalTitle = specialist.ProfessionalTitle,
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
    }
}