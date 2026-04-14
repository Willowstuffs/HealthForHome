using Google.Apis.Requests;
using H4H.Core.Models;
using H4H.Data;
using H4H_API.DTOs.Client;
using H4H_API.DTOs.Specialist;
using H4H_API.Exceptions;
using H4H_API.Helpers;
using H4H_API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using NetTopologySuite;
using ErrorCodes = H4H_API.Helpers.ErrorCodes;
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
                ? throw new AppException("Profil specjalisty nie istnieje.", ErrorCodes.SpecialistNotFound)
                : new SpecialistDto
                {
                    Id = spec.Id,
                    FirstName = spec.FirstName,
                    LastName = spec.LastName,

                    Email = spec.User.Email,
                    PhoneNumber = spec.User.PhoneNumber,

                    ProfessionalTitle = spec.ProfessionalTitle,
                    Bio = spec.Bio,
                    HourlyRate = spec.HourlyRate,
                    IsVerified = spec.IsVerified,
                    AverageRating = (decimal)spec.AverageRating,
                    TotalReviews = spec.TotalReviews,
                    AvatarUrl = spec.User.AvatarUrl,
                    //uproszczone mapowanie list

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
                .FirstOrDefaultAsync(s => s.UserId == userId) ?? throw new AppException("Profil specjalisty nie istnieje.", ErrorCodes.SpecialistNotFound);
            var area = await _context.service_areas
                .Where(a => a.Specialist.UserId == userId)
                .OrderByDescending(a => a.IsPrimary)
                .FirstOrDefaultAsync();

            if (area == null || area.Location == null)
                throw new AppException("Nie ustawiono obszaru świadczenia usług.", ErrorCodes.NoServiceAreaDefined);
            //PostGIS uzywa metrow
            var maxMeters = area.MaxDistanceKm * 1000;
            ///<summary>
            ///Query Builder do pobrania zapytan z zastosowaniem filtrow
            /// </summary>
            var query = _context.appointments
                .Include(a => a.Client)
                .Include(a => a.SpecialistService)
                    .ThenInclude(ss => ss!.ServiceType) //by dostac nazwe uslugi

                .AsQueryable();
            ///<summary>
            ///dadanie sprawdzenia czy dany specjalista już nie dodał ogłoszenia
            /// </summary>>
            var appointmentIds = query.Select(q => q.Id).ToList();

            query = query.Where(a => !_context.appointments_specialists
                            .Any(aspl => aspl.AppointmentId == a.Id && aspl.SpecialistId == specialist.Id));




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
            query = query.Where(a => a.AppointmentStatus == "open");


            query = query
                .Where(a => a.Location != null)
                .Where(a => a.Location!.Distance(area.Location) <= maxMeters);


            //Pobranie danych i mapowanie na DTO
            var result = await query
                .OrderBy(a => a.Location!.Distance(area.Location))
                .Select(a => new InquiryListItemDto
                {
                    AppointmentId = a.Id,
                    ScheduledStart = a.ScheduledStart,
                    ScheduledEnd = a.ScheduledEnd,
                    PatientName = a.Client.FirstName + " " + a.Client.LastName,
                    ServiceName = a.SpecialistService!.ServiceType.Name,
                    Status = a.AppointmentStatus,
                    PatientAddress = a.ClientAddress ?? a.Client.Address ?? "Brak adresu",
                    Price = a.TotalPrice ?? 0,
                    Description = a.ClientNotes,

                    DistanceKm = Math.Round(a.Location!.Distance(area.Location) / 1000, 2)
                })
    .ToListAsync();
            return result;
        }
        public async Task UpdateLicenseNumberAsync(Guid userId, string licenseNumber)
        {
            var specialist = await _context.specialists
                .FirstOrDefaultAsync(s => s.UserId == userId)
                ?? throw new AppException("Profil specjalisty nie istnieje.", ErrorCodes.SpecialistNotFound);

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

            if (specialist != null)
            {
                var qualification = specialist.Qualifications.FirstOrDefault();
                return qualification?.LicenseNumber;
            }

            throw new AppException("Profil specjalisty nie istnieje.", ErrorCodes.SpecialistNotFound);
        }
        public async Task<List<SpecialistServiceDto>> GetServicesAsync(Guid userId)
        {
            var specialist = await _context.specialists
                .Include(s => s.Services)
                    .ThenInclude(ss => ss.ServiceType)
                .FirstOrDefaultAsync(s => s.UserId == userId)
                ?? throw new AppException("Profil specjalisty nie istnieje.", ErrorCodes.SpecialistNotFound);

            return specialist.Services
                .Where(s => s.IsActive)
                .Select(s => new SpecialistServiceDto
                {
                    Id = s.Id,
                    ServiceName = s.ServiceType.Name,
                    Category = s.ServiceType.Category ?? "",
                    DurationMinutes = s.DurationMinutes,
                    Price = s.Price,
                    ServiceTypeId = s.ServiceTypeId,
                    Description = s.Description
                })
                .ToList();
        }
        public async Task<List<ServiceTypeDto>> GetServiceTypesAsync()
        {
            var types = await _context.service_types
                .Select(st => new ServiceTypeDto
                {
                    Id = st.Id,
                    Name = st.Name,
                    Category = st.Category ?? string.Empty,
                    DefaultDuration = st.DefaultDuration ?? 0,
                    Description = st.Description
                })
                .ToListAsync();

            return types;
        }
        public async Task AddServiceAsync(Guid userId, SpecialistServiceManageDto dto)
        {
            var specialist = await _context.specialists.FirstOrDefaultAsync(s => s.UserId == userId)
                 ?? throw new AppException("Profil specjalisty nie istnieje.", ErrorCodes.SpecialistNotFound); // ErrorCode: SPEC_001

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
                //CreatedAt = DateTime.UtcNow
                CreatedAt = DateTime.SpecifyKind(DateTime.UtcNow, DateTimeKind.Unspecified)
            };

            _context.specialist_services.Add(newService);
            await _context.SaveChangesAsync();
        }
        public async Task UpdateServiceAsync(Guid userId, Guid serviceId, SpecialistServiceManageDto dto)
        {
            var specialist = await _context.specialists.FirstOrDefaultAsync(s => s.UserId == userId)
                ?? throw new AppException("Profil specjalisty nie istnieje.", ErrorCodes.SpecialistNotFound);

            // Pobieranie konkretnej uslugi
            var service = await _context.specialist_services
                .FirstOrDefaultAsync(ss => ss.Id == serviceId && ss.SpecialistId == specialist.Id);

            if (service != null)
            {
                // Aktualizacja pól
                service.Price = dto.Price;
                service.DurationMinutes = dto.DurationMinutes;
                service.Description = dto.Description;
                service.ServiceTypeId = dto.ServiceTypeId;

                await _context.SaveChangesAsync();
            }
            throw new AppException("Usługa nie znaleziona.", ErrorCodes.ServiceNotFound); //SERV_002
        }

        public async Task DeleteServiceAsync(Guid userId, Guid serviceId)
        {
            var specialist = await _context.specialists.FirstOrDefaultAsync(s => s.UserId == userId);

            var service = await _context.specialist_services
                .FirstOrDefaultAsync(ss => ss.Id == serviceId && ss.SpecialistId == specialist!.Id);

            if (service != null)
            {
                _context.specialist_services.Remove(service);
                await _context.SaveChangesAsync();
            }
            else
                throw new AppException("Usługa nie znaleziona.", ErrorCodes.ServiceNotFound); //SERV_002
        }

        public async Task UpdateServiceAreaAsync(Guid userId, ServiceAreaManageDto dto)
        {
            var specialist = await _context.specialists
                .Include(s => s.ServiceAreas)
                .FirstOrDefaultAsync(s => s.UserId == userId)
                ?? throw new AppException("Profil specjalisty nie istnieje.", ErrorCodes.SpecialistNotFound);
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

            //PostGIS
            if (dto.Latitude.HasValue && dto.Longitude.HasValue)
            {
                // Tworzymy punkt geograficzny (SRID 4326 = WGS 84, standard GPS)
                var geometryFactory = NtsGeometryServices.Instance.CreateGeometryFactory(srid: 4326);
                area.Location = geometryFactory.CreatePoint(new NetTopologySuite.Geometries.Coordinate(dto.Longitude.Value, dto.Latitude.Value));
                area.LocationUpdatedAt = DateTime.UtcNow;
            }
            else
            {
                //Majac tylko miasto i kod pocztowy, mozna zrobic geokodowanie (kiedys)
                area.Location = null;
            }
            await _context.SaveChangesAsync();
        }

        public async Task ConfirmAppointmentAsync(Guid userId, Guid appointmentId, List<Guid> serviceTypeIds, decimal price)
        {
            var specialist = await _context.specialists.FirstOrDefaultAsync(s => s.UserId == userId)
                ?? throw new AppException("Profil nie istnieje.", ErrorCodes.SpecialistNotFound);


            var appointment = await _context.appointments
                .FirstOrDefaultAsync(a => a.Id == appointmentId);

            if (appointment == null)
                throw new AppException("Wizyta nie znaleziona.", ErrorCodes.AppointmentNotFound);

            if (appointment.AppointmentStatus != "open")
                throw new AppException("Można potwierdzić tylko wizyty oczekujące.", ErrorCodes.AppointmentStatusNotPending);


            var appointmentSpecialist = new AppointmentSpecialist
            {
                Id = Guid.NewGuid(),
                AppointmentId = appointment.Id,
                SpecialistId = specialist.Id,
                Price = price,
                ServiceTypeIds = serviceTypeIds,
                CreatedAt = DateTime.UtcNow
            };
            _context.appointments_specialists.Add(appointmentSpecialist);

            appointment.AppointmentStatus = "pending";

            await _context.SaveChangesAsync();
        }
        public async Task ShowConfirmAppointmentAsync(Guid userId, Guid appointmentId)
        {
            var specialist = await _context.specialists.FirstOrDefaultAsync(s => s.UserId == userId)
                ?? throw new AppException("Profil nie istnieje.", ErrorCodes.SpecialistNotFound);


            // Szukamy wizyty, która należy do tego specjalisty i ma status pending
            var appointment = await _context.appointments
                .FirstOrDefaultAsync(a => a.Id == appointmentId && a.SpecialistId == specialist.Id);

            if (appointment == null)
                throw new AppException("Wizyta nie znaleziona.", ErrorCodes.AppointmentNotFound);

            if (appointment.AppointmentStatus != "pending")
                throw new AppException("Można potwierdzić tylko wizyty oczekujące.", ErrorCodes.AppointmentStatusNotPending);

            appointment.AppointmentStatus = "confirmed";

            await _context.SaveChangesAsync();
        }
        public async Task ShowArchiwumAsync(Guid userId, Guid appointmentId)
        {
            var specialist = await _context.specialists.FirstOrDefaultAsync(s => s.UserId == userId)
                ?? throw new AppException("Profil nie istnieje.", ErrorCodes.SpecialistNotFound);

            // Szukamy wizyty, która należy do tego specjalisty i ma status pending
            var appointment = await _context.appointments
                .FirstOrDefaultAsync(a => a.Id == appointmentId && a.SpecialistId == specialist.Id);

            if (appointment == null)
                throw new AppException("Wizyta nie znaleziona.", ErrorCodes.AppointmentNotFound);

            if (appointment.AppointmentStatus != "pending")
                throw new AppException("Można potwierdzić tylko wizyty oczekujące.", ErrorCodes.AppointmentStatusNotPending);

            appointment.AppointmentStatus = "confirmed";
            appointment.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
        }
        public async Task<List<InquiryListItemDto>> GetCommingInquiriesAsync(Guid userId, InquiryFilterDto filters)
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
            query = query.Where(a => a.AppointmentStatus == "confirmed");

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
        public async Task<List<InquiryListItemDto>> GetArchiveInquiriesAsync(Guid userId, InquiryFilterDto filters)
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



            if (!string.IsNullOrEmpty(filters.PatientName))
            {
                var search = filters.PatientName.ToLower();
                query = query.Where(a =>
                    (a.Client.FirstName != null && a.Client.FirstName.ToLower().Contains(search)) ||
                    (a.Client.LastName != null && a.Client.LastName.ToLower().Contains(search))
                );
            }
            //filtrowanie po statusie
            query = query.Where(a => a.AppointmentStatus == "completed");

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
        public async Task UpdateProfileAsync(Guid userId, UpdateSpecialistProfileDto dto)
        {
            // Pobranie specjalisty wraz z obszarami działania
            var specialist = await _context.specialists
                .Include(s => s.ServiceAreas)
                .FirstOrDefaultAsync(s => s.UserId == userId)
                ?? throw new KeyNotFoundException("Profil specjalisty nie istnieje.");

            // Pobranie powiązanego użytkownika osobno, aby EF Core poprawnie śledził zmiany
            var user = await _context.users.FirstOrDefaultAsync(u => u.Id == userId)
                ?? throw new KeyNotFoundException("Użytkownik nie istnieje.");
            // Aktualizacja podstawowych danych w tabeli Users
            user.Email = dto.Email;
            user.PhoneNumber = dto.PhoneNumber;
            user.UpdatedAt = DateTime.UtcNow;

            // Obsługa uploadu avataru
            if (dto.Avatar != null && dto.Avatar.Length > 0)
            {
                // Tworzymy nazwę pliku z GUIDem, zachowując rozszerzenie
                var fileName = $"{Guid.NewGuid()}{Path.GetExtension(dto.Avatar.FileName)}";

                // Tworzymy folder wwwroot/avatars jeśli nie istnieje
                var folderPath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "avatars");
                if (!Directory.Exists(folderPath))
                    Directory.CreateDirectory(folderPath);

                var filePath = Path.Combine(folderPath, fileName);

                // Zapis pliku na dysku
                using (var stream = new FileStream(filePath, FileMode.Create))
                {
                    await dto.Avatar.CopyToAsync(stream);
                }

                // Zapisujemy ścieżkę do bazy (relative URL)
                user.AvatarUrl = $"/avatars/{fileName}";
            }
            // Aktualizacja danych specjalisty
            specialist.FirstName = dto.FirstName;
            specialist.LastName = dto.LastName;
            specialist.ProfessionalTitle = dto.ProfessionalTitle;
            specialist.Bio = dto.Bio;
            specialist.HourlyRate = dto.HourlyRate;
            // Zapis wszystkich zmian w jednej transakcji
            await _context.SaveChangesAsync();

        }


        /// <summary>
        /// Pobiera publiczny profil specjalisty na podstawie jego ID (nie userId), zawierający podstawowe informacje, średnią ocen, profesję i obszary działania.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        public async Task<SpecialistProfileDto?> GetPublicProfileAsync(Guid id)
        {
            // 1. Pobieramy dane z bazy (bez mapowania współrzędnych w SQL)
            var specialist = await _context.specialists
                .Include(s => s.User)
                .Include(s => s.ServiceAreas)
                .FirstOrDefaultAsync(s => s.Id == id);

            if (specialist == null) return null;

            // 2. Pobieramy profesję osobnym zapytaniem (prostsze i bezpieczniejsze)
            var profession = await _context.specialist_qualifications
                .Where(q => q.SpecialistId == id && q.IsActive)
                .Select(q => q.Profession)
                .FirstOrDefaultAsync();

            // 3. Mapujemy na DTO w pamięci (tutaj .Y i .X zadziałają bez błędu bazy)
            return new SpecialistProfileDto
            {
                Id = specialist.Id,
                FirstName = specialist.FirstName,
                LastName = specialist.LastName,
                ProfessionalTitle = specialist.ProfessionalTitle,
                Bio = specialist.Bio,
                AvatarUrl = specialist.User?.AvatarUrl,
                PhoneNumber = specialist.User?.PhoneNumber,
                Profession = profession,
                Areas = specialist.ServiceAreas.Select(a => new ServiceAreaManageDto
                {
                    City = a.City,
                    PostalCode = a.PostalCode,
                    MaxDistanceKm = (int)a.MaxDistanceKm,
                    // Tutaj procesor C# obsłuży to poprawnie, bo dane są już pobrane z bazy
                    Latitude = a.Location?.Y,
                    Longitude = a.Location?.X
                }).ToList()
            };
        }

        /// <summary>
        /// Pobiera listę aktywnych usług oferowanych przez specjalistę na podstawie jego ID (nie userId), zawierającą nazwę usługi, kategorię, czas trwania, cenę i opis.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        public async Task<List<SpecialistOfferDto>> GetPublicServicesAsync(Guid id)
        {
            return await _context.specialist_services
                .Include(ss => ss.ServiceType)
                .Where(ss => ss.SpecialistId == id && ss.IsActive)
                .Select(ss => new SpecialistOfferDto
                {
                    ServiceId = ss.Id,
                    Name = ss.ServiceType.Name,
                    Category = ss.ServiceType.Category,
                    DurationMinutes = ss.DurationMinutes,
                    Price = ss.Price,
                    Description = ss.Description
                })
                .ToListAsync();
        }

        /// <summary>
        /// Pobiera listę specjalistów znajdujących się w pobliżu klienta na podstawie jego współrzędnych geograficznych (latitude i longitude). Zwraca podstawowe informacje o specjaliście, średnią ocenę, stawkę godzinową oraz odległość od klienta. Wykorzystuje funkcje geograficzne PostGIS do obliczenia odległości między klientem a obszarami działania specjalistów, filtrując tylko tych, którzy znajdują się w zasięgu określonym przez ich maksymalną odległość działania. Wyniki są sortowane według odległości rosnąco, aby najbliżsi specjaliści byli wyświetlani jako pierwsi.
        /// </summary>
        /// <param name="lat"></param>
        /// <param name="lng"></param>
        /// <returns></returns>
        public async Task<List<NearbySpecialistDto>> GetNearbySpecialistsAsync(double lat, double lng)
        {
            var geometryFactory = NtsGeometryServices.Instance.CreateGeometryFactory(srid: 4326);
            var clientPoint = geometryFactory.CreatePoint(new NetTopologySuite.Geometries.Coordinate(lng, lat));

            return await _context.specialists
                .Include(s => s.ServiceAreas)
                .Where(s => s.ServiceAreas.Any(sa =>
                    sa.Location != null &&
                    sa.Location.Distance(clientPoint) <= sa.MaxDistanceKm * 1000)) // Distance w PostGIS dla Geography jest w metrach
                .Select(s => new NearbySpecialistDto
                {
                    Id = s.Id,
                    FirstName = s.FirstName,
                    LastName = s.LastName,
                    ProfessionalTitle = s.ProfessionalTitle,
                    AvatarUrl = s.User.AvatarUrl,
                    HourlyRate = s.HourlyRate ?? 0,
                    DistanceKm = s.ServiceAreas
                        .Where(sa => sa.Location != null)
                        .Select(sa => sa.Location!.Distance(clientPoint) / 1000)
                        .Min()
                })
                .OrderBy(s => s.DistanceKm)
                .ToListAsync();
        }
        

    }
}