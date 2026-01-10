using H4H.Core.Helpers;
using H4H.Core.Models;
using H4H.Data;
using H4H_API.DTOs.Specialist;
using H4H_API.Exceptions;
using H4H_API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using SpecialistServiceEntity = H4H.Core.Models.SpecialistService;

namespace H4H_API.Services.Implementations
{
    public class SpecialistService : ISpecialistService
    {
        private readonly ApplicationDbContext _context;

        public SpecialistService(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<SpecialistDto> GetProfileAsync(Guid userId)
        {
            //pobieranie specjaliste z danymi uzytkownika, uslugami i obszarami
            var spec = await _context.specialists
                .Include(s => s.User)
                .Include(s => s.Services)
                  .ThenInclude(ss => ss.ServiceType)
                .Include(s => s.ServiceAreas)
                .FirstOrDefaultAsync(s => s.UserId == userId);

            return spec == null
                ? throw new KeyNotFoundException($"Nie znaleziono specjalisty dla użytkownika {userId}")
                : new SpecialistDto
            {
                Id = spec.Id,
                FirstName = spec.FirstName,
                LastName = spec.LastName,
                ProfessionalTitle = spec.ProfessionalTitle,
                Bio = spec.Bio,
                HourlyRate = spec.HourlyRate,
                IsVerified = spec.IsVerified,
                AverageRating = (decimal)spec.AverageRating,
                TotalReviews = spec.TotalReviews,
                //uproszczone mapowanie list
                Services = [.. spec.Services.Select(s => new SpecialistServiceDto
                {
                    Id = s.Id,
                    ServiceName = s.ServiceType?.Name ?? "Nieznana usługa",
                    Price = s.Price,
                //tu uzupelnic o reszte pozniej
                })],
                ServiceAreas = [.. spec.ServiceAreas.Select(a => new ServiceAreaDto
                {
                    City = a.City,
                    MaxDistanceKm = a.MaxDistanceKm
                })]
                };
        }
        public async Task<List<InquiryListItemDto>> GetInquiriesAsync(Guid userId, InquiryFilterDto filters)
        {
            var specialist = await _context.specialists
                .FirstOrDefaultAsync(s => s.UserId == userId) ?? throw new KeyNotFoundException($"Nie znaleziono specjalisty dla użytkownika {userId}");

            ///<summary>
            ///Query Builder do pobrania zapytan z zastosowaniem filtrow
            /// </summary>
            var query = _context.appointments
                .Include(a => a.Client)
                .Include(a => a.SpecialistService)
                    .ThenInclude(ss => ss!.ServiceType) //by dostac nazwe uslugi
                .Where(a => a.SpecialistService!.SpecialistId == specialist.Id)
                .AsQueryable();
            //Aplikowanie filtrow
            if (filters.DateFrom.HasValue) // od
                query = query.Where(a => a.ScheduledStart >= filters.DateFrom.Value);
            if (filters.DateTo.HasValue) // do
                query = query.Where(a => a.ScheduledEnd <= filters.DateTo.Value);

            if (!string.IsNullOrEmpty(filters.PatientName))
            {
                var search = filters.PatientName.ToLower();
                query = query.Where(a =>
                    (a.Client.FirstName != null && a.Client.FirstName.ToLower().Contains(search)) ||
                    (a.Client.LastName != null && a.Client.LastName.ToLower().Contains(search))
                );
            }
            //filtrowanie po statusie
            query = query.Where(a => a.AppointmentStatus != "cancelled");

            //Pobranie danych i mapowanie na DTO
            var result = await query
                .OrderByDescending(a => a.ScheduledStart)
                .Select(a => new InquiryListItemDto
                {
                    AppointmentId = a.Id,
                    ScheduledStart = a.ScheduledStart,
                    ScheduledEnd = a.ScheduledEnd,
                    PatientName = a.Client.FirstName + " " + a.Client.LastName,
                    ServiceName = a.SpecialistService!.ServiceType.Name,
                    Status = a.AppointmentStatus,
                    PatientAddress = a.ClientAddress ?? a.Client.Address ?? "Brak adresu",
                    Price = a.TotalPrice ?? 0
                })
                .ToListAsync();
            return result;
        }
        public async Task UpdateLicenseNumberAsync(Guid userId, string licenseNumber)
        {
            var specialist = await _context.specialists
                .FirstOrDefaultAsync(s => s.UserId == userId) 
                ?? throw new KeyNotFoundException($"Nie znaleziono specjalisty dla użytkownika {userId}");
            
            var qualification = await _context.specialist_qualifications
                .FirstOrDefaultAsync(q => q.SpecialistId == specialist.Id);

            //znajdz lub utworz wpis w kwalifikacjach z tabeli specialist_qualifications
            if (qualification == null)
            {
                qualification = new SpecialistQualification
                {
                    Id = Guid.NewGuid(),
                    SpecialistId = specialist.Id,
                    CreatedAt = DateTime.Now
                };
                _context.specialist_qualifications.Add(qualification);
            }

            qualification.LicenseNumber = licenseNumber;
            qualification.Profession = specialist.ProfessionalTitle!;
            qualification.IsActive = true;

            specialist.VerificationStatus = "pending";

            await _context.SaveChangesAsync();
        }
        public async Task<string?> GetLicenseNumberAsync(Guid userId)
        {
            //sieganie do tabeli specialist_qualifications poprzez specjaliste
            var specialist = await _context.specialists
                .Include(s => s.Qualifications) //relacja do kwalifikacji
                .FirstOrDefaultAsync(s => s.UserId == userId);

            if(specialist == null)
                throw new KeyNotFoundException($"Nie znaleziono profilu specjalisty dla użytkownika {userId}");

            var qualification = specialist.Qualifications.FirstOrDefault();
            return qualification?.LicenseNumber;
        }
        public async Task AddServiceAsync(Guid userId, SpecialistServiceManageDto dto)
        {
            var specialist = await _context.specialists.FirstOrDefaultAsync(s => s.UserId == userId)
                 ?? throw new KeyNotFoundException("Profil nie istnieje."); // ErrorCode: SPEC_001

            // Duplikaty
            var exists = await _context.specialist_services
                .AnyAsync(ss => ss.SpecialistId == specialist.Id && ss.ServiceTypeId == dto.ServiceTypeId);
            // Wlasny wyjatek z kodem bledu dla duplikatu
            if (exists) throw new AppException("Masz już tę usługę.", ErrorCodes.ServiceAlreadyExists);

            // Nowa encja z bazy danych
            var newService = new SpecialistServiceEntity
            {
                Id = Guid.NewGuid(),
                SpecialistId = specialist.Id,
                ServiceTypeId = dto.ServiceTypeId,
                Price = dto.Price,
                DurationMinutes = dto.DurationMinutes,
                Description = dto.Description,
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            };

            _context.specialist_services.Add(newService);
            await _context.SaveChangesAsync();
        }
        public async Task UpdateServiceAsync(Guid userId, Guid serviceId, SpecialistServiceManageDto dto)
        {
            var specialist = await _context.specialists.FirstOrDefaultAsync(s => s.UserId == userId)
                ?? throw new KeyNotFoundException("Profil nie istnieje.");

            // Pobieranie konkretnej uslugi
            var service = await _context.specialist_services
                .FirstOrDefaultAsync(ss => ss.Id == serviceId && ss.SpecialistId == specialist.Id);

            if (service == null) throw new KeyNotFoundException("Usługa nie znaleziona.");

            // Aktualizacja pól
            service.Price = dto.Price;
            service.DurationMinutes = dto.DurationMinutes;
            service.Description = dto.Description;
            service.ServiceTypeId = dto.ServiceTypeId; 

            await _context.SaveChangesAsync();
        }

        public async Task DeleteServiceAsync(Guid userId, Guid serviceId)
        {
            var specialist = await _context.specialists.FirstOrDefaultAsync(s => s.UserId == userId);

            var service = await _context.specialist_services
                .FirstOrDefaultAsync(ss => ss.Id == serviceId && ss.SpecialistId == specialist!.Id);

            if (service == null) throw new KeyNotFoundException("Usługa nie znaleziona.");

            _context.specialist_services.Remove(service);
            await _context.SaveChangesAsync();
        }

        public async Task UpdateServiceAreaAsync(Guid userId, ServiceAreaManageDto dto)
        {
            var specialist = await _context.specialists
                .Include(s => s.ServiceAreas)
                .FirstOrDefaultAsync(s => s.UserId == userId)
                ?? throw new KeyNotFoundException("Profil nie istnieje.");
            // Zakladamy ze specjalista ma jeden obszar dzialania.

            var area = specialist.ServiceAreas.FirstOrDefault();

            if (area == null)
            {
                area = new ServiceArea
                {
                    Id = Guid.NewGuid(),
                    SpecialistId = specialist.Id,
                    IsPrimary = true
                };
                _context.service_areas.Add(area);
            }

            area.City = dto.City;
            area.PostalCode = dto.PostalCode;
            area.MaxDistanceKm = dto.MaxDistanceKm;

            // --- PRZYSZŁA IMPLEMENTACJA GEOLOKALIZACJI ---
            /*
            if (dto.Latitude.HasValue && dto.Longitude.HasValue)
            {
                 area.Latitude = dto.Latitude.Value;
                 area.Longitude = dto.Longitude.Value;
            }
            */
            await _context.SaveChangesAsync();
        }

    }
}
