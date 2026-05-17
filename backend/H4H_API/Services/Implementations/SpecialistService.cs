using H4H.Core.Models;
using H4H.Data;
using H4H_API.DTOs.Appointments;
using H4H_API.DTOs.Client;
using H4H_API.DTOs.Specialist;
using H4H_API.Exceptions;
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
        private readonly FirebaseNotificationService _firebaseNotificationService;
        private readonly IAppointmentsLifeCycleServer _lifecycle;

        public SpecialistService(ApplicationDbContext context, FirebaseNotificationService firebaseNotificationService)
        {
            _context = context;
            _firebaseNotificationService = firebaseNotificationService;
            //Jest lekki to może być wstrzykiwany bezpośrednio
            _lifecycle = new AppointmentsLifeCycleService(context, firebaseNotificationService);
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

            // --- Dodane sprawdzenie, czy specjalista jest zawieszony (suspended) - jeśli tak, nie pozwalamy na pobieranie zapytań ---
            if (specialist.IsSuspended)
            {
                // Możemy zwrócić pustą listę zamiast błędu, żeby aplikacja się nie wywaliła na starcie, 
                // ale specjalista nie zobaczy żadnych ofert.
                return new List<InquiryListItemDto>();
            }
            // -----------------------

            var area = await _context.service_areas
                .Where(a => a.Specialist.UserId == userId)
                .OrderByDescending(a => a.IsPrimary)
                .FirstOrDefaultAsync();

            if (area == null || area.Location == null)
                throw new AppException("Nie ustawiono obszaru świadczenia usług.", ErrorCodes.NoServiceAreaDefined);
            var profession = await _context.specialist_qualifications
                .Where(q => q.SpecialistId == specialist.Id && q.IsActive)
                .Select(q => q.Profession)
                .FirstOrDefaultAsync();
            //PostGIS uzywa metrow
            var maxMeters = area.MaxDistanceKm * 1000;
            ///<summary>
            ///Query Builder do pobrania zapytan z zastosowaniem filtrow
            /// </summary>
            var query = _context.appointments
                .Include(a => a.Client)
                .Include(a => a.ServiceType)
                .AsQueryable();

            query = query.Where(a =>
                 a.ServiceType != null &&
                 (
                     (profession == "nurse" && a.ServiceType.Category == "nursing") ||
                     (profession == "physiotherapist" && a.ServiceType.Category == "physiotherapy")
                 )
             );

            ///<summary>
            ///dadanie sprawdzenia czy dany specjalista już nie dodał ogłoszenia
            /// </summary>>
            query = query.Where(a =>
                   !_context.appointments_specialists
                       .Any(aspl => aspl.AppointmentId == a.Id && aspl.SpecialistId == specialist.Id)
               );



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

            // DANE DO PAMIĘCI
            var appointments = await query.ToListAsync();

            // STATYSTYKI 
            var clientStats = await _context.appointments
                .Where(a => a.ClientId != null && a.ClientRating != null)
                .GroupBy(a => a.ClientId)
                .Select(g => new
                {
                    ClientId = g.Key,
                    Ratings = g.GroupBy(x => x.ClientRating)
                        .Select(r => new
                        {
                            Rating = r.Key,
                            Count = r.Count()
                        })
                })
                .ToListAsync();

            var statsDict = clientStats.ToDictionary(
                x => x.ClientId,
                x => new ClientStatsDto
                {
                    GoodCount = x.Ratings.FirstOrDefault(r => r.Rating == "good")?.Count ?? 0,
                    NeutralCount = x.Ratings.FirstOrDefault(r => r.Rating == "neutral")?.Count ?? 0,
                    BadCount = x.Ratings.FirstOrDefault(r => r.Rating == "bad")?.Count ?? 0
                }
            );

            //LOKALIZACJA 
            var result = await query
               .OrderBy(a => a.Location!.Distance(area.Location))
               .Select(a => new InquiryListItemDto
               {
                   AppointmentId = a.Id,
                   ScheduledStart = a.ScheduledStart,
                   ScheduledEnd = a.ScheduledEnd,
                   PatientName = a.Client.FirstName + " " + a.Client.LastName,
                   ServiceName = a.ServiceType != null ? a.ServiceType.Name : "Nieznana kategoria",
                   Status = a.AppointmentStatus,
                   PatientAddress = a.ClientAddress ?? a.Client.Address ?? "Brak adresu",
                   Price = a.TotalPrice ?? 0,
                   Description = a.ClientNotes,
                   reviews = a.ClientId != null && statsDict.ContainsKey(a.ClientId)
                        ? statsDict[a.ClientId]
                        : new ClientStatsDto(),

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
                 ?? throw new AppException("Profil specjalisty nie istnieje.", ErrorCodes.SpecialistNotFound);

            Guid serviceTypeId;

            //Logika ustalania ServiceTypeId (Istniejące vs Nowe)
            if (dto.ServiceTypeId.HasValue && dto.ServiceTypeId != Guid.Empty)
            {
                serviceTypeId = dto.ServiceTypeId.Value;
            }
            else if (!string.IsNullOrWhiteSpace(dto.ServiceName))
            {
                //Szukamy czy taka nazwa już istnieje w bazie (case-insensitive)
                var existingType = await _context.service_types
                    .FirstOrDefaultAsync(st => st.Name.ToLower() == dto.ServiceName.ToLower());

                if (existingType != null)
                {
                    serviceTypeId = existingType.Id;
                }
                else
                {
                    //Tworzymy nowy typ usługi, jeśli nie znaleziono
                    var newType = new ServiceType
                    {
                        Id = Guid.NewGuid(),
                        Name = dto.ServiceName,
                        Category = dto.Category ?? "Inne", // domyślna kategoria jeśli nie podano
                        DefaultDuration = dto.DurationMinutes
                    };
                    _context.service_types.Add(newType);
                    await _context.SaveChangesAsync(); // zapisujemy od razu by miec ID
                    serviceTypeId = newType.Id;
                }
            }
            else
            {
                throw new AppException("Musisz podać ID usługi lub jej nazwę.", ErrorCodes.ValidationError);
            }

            //Sprawdzenie duplikatu u tego konkretnego specjalisty
            var exists = await _context.specialist_services
                .AnyAsync(ss => ss.SpecialistId == specialist.Id && ss.ServiceTypeId == serviceTypeId);

            if (exists) throw new AppException("Masz już tę usługę w swoim profilu.", ErrorCodes.ServiceAlreadyExists);

            //Dodanie usługi do profilu specjalisty
            var newService = new SpecialistServiceEntity
            {
                Id = Guid.NewGuid(),
                SpecialistId = specialist.Id,
                ServiceTypeId = serviceTypeId,
                Price = dto.Price,
                DurationMinutes = dto.DurationMinutes,
                Description = dto.Description,
                IsActive = true,
                CreatedAt = DateTime.SpecifyKind(DateTime.UtcNow, DateTimeKind.Unspecified)
            };

            _context.specialist_services.Add(newService);
            await _context.SaveChangesAsync();
        }
        public async Task UpdateServiceAsync(Guid userId, Guid serviceId, SpecialistServiceManageDto dto)
        {
            var specialist = await _context.specialists.FirstOrDefaultAsync(s => s.UserId == userId)
                ?? throw new AppException("Profil specjalisty nie istnieje.", ErrorCodes.SpecialistNotFound);

            var service = await _context.specialist_services
                .FirstOrDefaultAsync(ss => ss.Id == serviceId && ss.SpecialistId == specialist.Id)
                ?? throw new AppException("Usługa nie znaleziona.", ErrorCodes.ServiceNotFound);

            service.Price = dto.Price;
            service.DurationMinutes = dto.DurationMinutes;
            service.Description = dto.Description;

            // Jeśli DTO przesyła nowe ServiceTypeId, też je aktualizujemy
            if (dto.ServiceTypeId.HasValue) service.ServiceTypeId = dto.ServiceTypeId.Value;

            await _context.SaveChangesAsync();
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

        public async Task ConfirmAppointmentAsync(Guid userId, Guid appointmentId, List<Guid> serviceTypeIds, decimal price, DateTime proposedDate)
        {
            var specialist = await _context.specialists.FirstOrDefaultAsync(s => s.UserId == userId)
                ?? throw new AppException("Profil nie istnieje.", ErrorCodes.SpecialistNotFound);

            // --- Sprawdzenie, czy mozna dodac oferte (czy konto nie jest zawieszone) ---
            if (specialist.IsSuspended)
            {
                throw new AppException("Twoje konto jest zawieszone przez administratora. Nie możesz wysyłać nowych ofert.", ErrorCodes.SpecialistAccountSuspended);
            }
            // -----------------------

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
                CreatedAt = DateTime.UtcNow,
                ProposedDate = proposedDate
            };
            _context.appointments_specialists.Add(appointmentSpecialist);

            appointment.AppointmentStatus = "pending";

            var clientUserId = await _context.clients
                .Where(c => c.Id == appointment.ClientId)
                .Select(c => c.UserId)
                .FirstOrDefaultAsync();

            var clientTokens = await _context.device_tokens
                .Where(dt => dt.UserId == clientUserId)
                .Select(dt => dt.FcmToken)
                .ToListAsync();

            var body = "";

            var serviceTypeName = await _context.service_types
                .Where(st => st.Id == appointment.ServiceTypeId)
                .Select(st => st.Name)
                .FirstOrDefaultAsync();

            if (appointment.ClientNotes != null && appointment.ClientNotes.Length > 30)
                body = serviceTypeName != null ? $"Twoje ogłoszenie z kategorii {serviceTypeName} - {appointment.ClientNotes[..30]}... otrzymało nową ofertę!" :
                    $"Twoje ogłoszenie - {appointment.ClientNotes[..30]}... otrzymało nową ofertę!";
            else if (appointment.ClientNotes != null)
                body = serviceTypeName != null ? $"Twoje ogłoszenie z kategorii {serviceTypeName} - {appointment.ClientNotes} otrzymało nową ofertę!" :
                    $"Twoje ogłoszenie - {appointment.ClientNotes} otrzymało nową ofertę!";
            else
                body = serviceTypeName != null ? $"Twoje ogłoszenie z kategorii {serviceTypeName} otrzymało nową ofertę!" :
                    $"Twoje ogłoszenie otrzymało nową ofertę!";

            if (clientTokens.Count != 0)
            {
                await _firebaseNotificationService.SendNotificationToManyAsync(
                    clientTokens,
                    "Nowa oferta!",
                    body,
                    appointment.Id.ToString(),
                    isClientApp: true
                );
            }

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
                .Where(a => a.SpecialistId == specialist.Id)
                .Where(a => a.AppointmentStatus == "confirmed") // Pokazujemy tylko potwierdzone wizyty, które są w przyszłości (lub dzisiaj)
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

            //Pobranie danych i mapowanie na DTO
            var appointments = await query.OrderByDescending(a => a.ScheduledStart).ToListAsync();

            var allServiceIds = appointments.SelectMany(a => a.SpecialistServiceIds).Distinct().ToList();
            var serviceNamesMap = new Dictionary<Guid, string>();

            if (allServiceIds.Any())
            {
                serviceNamesMap = await _context.specialist_services
                    .Include(ss => ss.ServiceType)
                    .Where(ss => allServiceIds.Contains(ss.Id))
                    .ToDictionaryAsync(ss => ss.Id, ss => ss.ServiceType.Name);
            }

            return appointments.Select(a => new InquiryListItemDto
            {
                AppointmentId = a.Id,
                ClientId = a.ClientId,
                FinalDate = a.FinalDate,
                PatientName = a.Client.FirstName + " " + a.Client.LastName,
                ServiceName = a.ServiceNamesSnapshot ?? "Brak usługi",
                Status = a.AppointmentStatus,
                PatientAddress = a.ClientAddress ?? a.Client.Address ?? "Brak adresu",
                Price = a.TotalPrice ?? 0
            }).ToList();
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
                .Where(a => a.SpecialistId == specialist.Id) // Filtrujemy bezpośrednio po ID specjalisty w wizycie
                .Where(a => a.AppointmentStatus == "completed")
                .AsQueryable();

            if (!string.IsNullOrEmpty(filters.PatientName))
            {
                var search = filters.PatientName.ToLower();
                query = query.Where(a =>
                    (a.Client.FirstName != null && a.Client.FirstName.ToLower().Contains(search)) ||
                    (a.Client.LastName != null && a.Client.LastName.ToLower().Contains(search))
                );
            }

            // Pobieramy listę wizyt z bazy
            var appointments = await query
                .OrderByDescending(a => a.ScheduledStart)
                .ToListAsync();

            // Pobieramy nazwy usług dla wszystkich wizyt (jedno zapytanie do bazy)
            var allServiceIds = appointments.SelectMany(a => a.SpecialistServiceIds).Distinct().ToList();
            var serviceNamesMap = new Dictionary<Guid, string>();

            if (allServiceIds.Any())
            {
                serviceNamesMap = await _context.specialist_services
                    .Include(ss => ss.ServiceType)
                    .Where(ss => allServiceIds.Contains(ss.Id))
                    .ToDictionaryAsync(ss => ss.Id, ss => ss.ServiceType.Name);
            }

            // Mapujemy na DTO i łączymy nazwy usług w jeden ciąg tekstowy (np. "Konsultacja, Zastrzyk")
            var result = appointments.Select(a => new InquiryListItemDto
            {
                AppointmentId = a.Id,
                FinalDate = a.FinalDate,
                PatientName = a.Client.FirstName + " " + a.Client.LastName,
                // Pobieramy nazwy z mapy na podstawie tablicy ID
                ServiceName = a.ServiceNamesSnapshot ?? "Brak usługi",

                Status = a.AppointmentStatus,
                Price = a.TotalPrice ?? 0,
                ClientRating = a.ClientRating
            }).ToList();


            return result;
        }
        public async Task UpdateAvatarAsync(Guid userId, string avatarUrl)
        {
            var user = await _context.users.FirstOrDefaultAsync(u => u.Id == userId)
                ?? throw new KeyNotFoundException("Użytkownik nie istnieje.");

            user.AvatarUrl = avatarUrl;
            user.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
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
            // Aktualizacja danych specjalisty
            specialist.FirstName = dto.FirstName;
            specialist.LastName = dto.LastName;
            // Zapis wszystkich zmian w jednej transakcji
            await _context.SaveChangesAsync();

        }



        /// <summary>
        /// Pobiera publiczny profil specjalisty na podstawie jego ID (nie userId), zawierający podstawowe informacje, średnią ocen, profesję i obszary działania.
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        public async Task<SpecialistProfileTruncatedDto?> GetPublicProfileAsync(Guid id)
        {
            // 1. Pobieramy dane z bazy (bez mapowania współrzędnych w SQL)
            var specialist = await _context.specialists
                .Include(s => s.User)
                .Include(s => s.ServiceAreas)
                .FirstOrDefaultAsync(s => s.Id == id);

            if (specialist == null) return null;

            // 2. Pobieramy kwalifikacje specjalisty
            var qualifications = await _context.specialist_qualifications
                .Where(q => q.SpecialistId == specialist.Id && q.IsActive)
                .Select(q => q.Profession)
                .ToListAsync();

            // 3. Mapujemy na DTO w pamięci (tutaj .Y i .X zadziałają bez błędu bazy)
            return new SpecialistProfileTruncatedDto
            {
                Id = specialist.Id,
                FirstName = specialist.FirstName,
                LastName = specialist.LastName,
                ProfessionalTitle = specialist.ProfessionalTitle,
                Bio = specialist.Bio,
                AvatarUrl = specialist.User?.AvatarUrl,
                Qualifications = qualifications,
                Areas = specialist.ServiceAreas.Select(a => new ServiceAreaManageDto
                {
                    City = a.City,
                    PostalCode = a.PostalCode,
                    MaxDistanceKm = (int)a.MaxDistanceKm,
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
                    ServiceNames = s.Services
                        .Where(srv => srv.IsActive)
                        .Select(srv => srv.ServiceType.Name)
                        .ToList(),
                    ServiceArea = s.ServiceAreas // select closest area to client
                        .Where(sa => sa.Location != null)
                        .OrderBy(sa => sa.Location!.Distance(clientPoint))
                        .Select(sa => sa.City)
                        .FirstOrDefault() ?? "Brak obszaru",
                    DistanceKm = s.ServiceAreas
                        .Where(sa => sa.Location != null)
                        .Select(sa => sa.Location!.Distance(clientPoint) / 1000)
                        .Min()
                })
                .ToListAsync();
        }
        /// <summary>Pozwala specjaliście zrezygnować z potwierdzonej wizyty. Jeśli wizyta była już potwierdzona, metoda usuwa ofertę 
        /// specjalisty z tej wizyty i przywraca status wizyty do "open", umożliwiając klientowi wybór innego specjalisty. 
        /// Dodatkowo, jeśli wizyta była potwierdzona, wysyła powiadomienie do klienta informujące o rezygnacji specjalisty i ponownym 
        /// otwarciu ogłoszenia. Jeśli wizyta nie była jeszcze potwierdzona, metoda po prostu usuwa ofertę specjalisty bez zmiany statusu wizyty.</summary>
        public async Task ResignFromAppointmentAsync(Guid userId, Guid appointmentId)
        {
            var specialist = await _context.specialists.FirstOrDefaultAsync(s => s.UserId == userId)
                ?? throw new AppException("Nie znaleziono profilu specjalisty.", ErrorCodes.SpecialistNotFound);

            var appointment = await _context.appointments.FindAsync(appointmentId)
                ?? throw new AppException("Wizyta nie istnieje.", ErrorCodes.AppointmentNotFound);
            // Sprawdzanie czy specjalista ma oferte w tej wizycie
            var hasOffer = await _context.Set<AppointmentSpecialist>()
                .AnyAsync(os => os.AppointmentId == appointmentId && os.SpecialistId == specialist.Id);

            if (!hasOffer)
                throw new AppException("Nie posiadasz oferty w tym zleceniu.", ErrorCodes.NoOfferForAppointment);

            //Wariant B - wizyta potwierdzona, rezygnacja specjalisty.
            if (appointment.AppointmentStatus == "confirmed")
            {
                
                if (appointment.SpecialistId != specialist.Id)
                    throw new AppException("Nie jesteś przypisanym specjalistą.", ErrorCodes.NoOfferForAppointment);

                // Najpierw usuwamy ofertę specjalisty, żeby nie mógł być wybrany ponownie
                await _lifecycle.RemoveSpecialistOfferAsync(appointmentId, specialist.Id);
                // Potem przywracamy wizytę do statusu 'open'
                await _lifecycle.ResetAppointmentToOpenAsync(appointment);

                // Wysyłamy powiadomienie do klienta o rezygnacji specjalisty i ponownym otwarciu ogłoszenia
                await SendSpecialistResignedNotification(appointment);
            }
            else
            {
                // Jeśli wizyta nie była confirmed, tylko usuwamy ofertę
                await _lifecycle.RemoveSpecialistOfferAsync(appointmentId, specialist.Id);
            }
        }

        /// <summary>
        /// Wysyła powiadomienie do klienta, informujące o rezygnacji specjalisty z potwierdzonej wizyty i ponownym otwarciu ogłoszenia.
        /// </summary>
        private async Task SendSpecialistResignedNotification(Appointment appointment)
        {
            var clientUserId = await _context.clients
                .Where(c => c.Id == appointment.ClientId)
                .Select(c => c.UserId)
                .FirstAsync();

            var tokens = await _context.device_tokens
                .Where(t => t.UserId == clientUserId)
                .Select(t => t.FcmToken)
                .ToListAsync();

            if (tokens.Any())
            {
                await _firebaseNotificationService.SendNotificationToManyAsync(
                    tokens,
                    "Zmiana w Twojej wizycie",
                    "Specjalista musiał zrezygnować. Twoje ogłoszenie jest znów otwarte – wybierz innego specjalistę.",
                    appointment.Id.ToString()
                );
            }
        }


        /// <summary>
        /// Pozwala specjaliście ocenić klienta po zakończeniu wizyty, przypisując ocenę ("good", "neutral", "bad") oraz opcjonalny komentarz. 
        /// Metoda sprawdza, czy wizyta istnieje, należy do danego specjalisty i ma status "completed", zanim zaktualizuje dane oceny klienta w bazie. 
        /// Ocena klienta może być wykorzystana do budowania reputacji klienta w systemie oraz do ewentualnych działań moderacyjnych w przypadku negatywnych opinii.
        /// </summary>
        /// <param name="specialistUserId"></param>
        /// <param name="appointmentId"></param>
        /// <param name="dto"></param>
        /// <returns></returns>
        /// <exception cref="AppException"></exception>
        public async Task RateClientAsync(Guid specialistUserId, Guid appointmentId, RateClientDto dto)
        {
            // 1. Pobieramy wizytę
            var appointment = await _context.appointments
                .Include(a => a.Specialist)
                .FirstOrDefaultAsync(a => a.Id == appointmentId);

            // 2. Sprawdzamy czy wizyta istnieje I czy specjalista do niej przypisany to ten, który wysłał żądanie
            if (appointment == null || appointment.Specialist?.UserId != specialistUserId)
            {
                throw new AppException("Wizyta nie istnieje lub nie należy do Ciebie.", ErrorCodes.AppointmentNotFound);
            }

            // 3. Sprawdzamy status
            if (appointment.AppointmentStatus != "completed")
            {
                throw new AppException("Można oceniać tylko zakończone wizyty.", ErrorCodes.AppointmentStatusNotCompleted);
            }

            // 4. Zapisujemy ocenę
            appointment.ClientRating = dto.Rating.ToLower();
            appointment.ClientRatingComment = dto.Comment; // Zapisujemy komentarz niezależnie od tego czy to 'good' czy 'bad'
                                                           // Ale wyswietlamy pole tekstowe raczej dla bad, a dla good/neutral mozna dac opcjonalne pole komentarza 
            await _context.SaveChangesAsync();
        }

    }
}