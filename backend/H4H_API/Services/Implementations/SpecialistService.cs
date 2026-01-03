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

            if (spec == null) throw new KeyNotFoundException($"Nie znaleziono specjalisty dla użytkownika {userId}");

            return new SpecialistDto
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
                Services = spec.Services.Select(s => new SpecialistServiceDto
                {
                    Id = s.Id,
                    ServiceName = s.ServiceType.Name,
                    Price = s.Price,
                    //tu uzupelnic o reszte pozniej
                }).ToList(),
                ServiceAreas = spec.ServiceAreas.Select(a => new ServiceAreaDto
                {
                    City = a.City,
                    MaxDistanceKm = a.MaxDistanceKm
                }).ToList()
            };
        }
    }
}
