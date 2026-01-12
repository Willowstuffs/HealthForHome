using H4H.Core.Models;
using H4H.Data;
using H4H_API.DTOs.Specialist;
using H4H_API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

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
    }
}
