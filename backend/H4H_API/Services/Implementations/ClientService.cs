using AutoMapper;
using H4H_API.DTOs.Appointments;
using H4H_API.DTOs.Common;
using H4H_API.DTOs.Specialist;
using H4H.Core.Models;
using H4H.Data;
using H4H_API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using H4H_API.DTOs.Client;
using H4H_API.Exceptions;
using H4H_API.Helpers;
using H4H_API.DTOs.Geolocation;

namespace H4H_API.Services.Implementations
{
    /// <summary>
    /// Provides client-related operations such as profile management, password changes, appointment handling, and
    /// specialist search for authenticated users.
    /// </summary>
    /// <remarks>This service acts as the main entry point for client-facing features in the application. It
    /// encapsulates business logic for retrieving and updating client profiles, managing appointments, and searching
    /// for specialists. All methods are asynchronous and require a valid user identifier. Thread safety is not
    /// guaranteed; instances should not be shared between concurrent requests.</remarks>
    public class ClientService : IClientService
    {
        private readonly ApplicationDbContext _context;
        private readonly IMapper _mapper;
        private readonly IGeocoder _geocoder;

        /// <summary>
        /// Initializes a new instance of the ClientService class using the specified database context and object
        /// mapper.
        /// </summary>
        /// <param name="context">The database context used to access and manage client data within the application. Cannot be null.</param>
        /// <param name="mapper">The object mapper used to map between domain entities and data transfer objects. Cannot be null.</param>
        /// <param name="geocoder">The geocoding service for address geolocation. Cannot be null.</param>
        public ClientService(ApplicationDbContext context, IMapper mapper, IGeocoder geocoder)
        {
            _context = context;
            _mapper = mapper;
            _geocoder = geocoder;
        }

        /// <summary>
        /// Asynchronously retrieves the client profile associated with the specified user identifier.
        /// </summary>
        /// <param name="userId">The unique identifier of the user whose client profile is to be retrieved.</param>
        /// <returns>A task that represents the asynchronous operation. The task result contains a <see cref="ClientProfileDto"/>
        /// representing the client's profile.</returns>
        /// <exception cref="AppException">Thrown when no client profile is found for the specified <paramref name="userId"/>.</exception>
        public async Task<ClientProfileDto> GetProfileAsync(Guid userId)
        {
            var client = await _context.clients
                .Include(c => c.User)
                .FirstOrDefaultAsync(c => c.UserId == userId);

            if (client == null)
                throw new AppException($"Nie znaleziono profilu klienta dla użytkownika {userId}", ErrorCodes.ClientNotFound);

            return _mapper.Map<ClientProfileDto>(client);
        }

        /// <summary>
        /// Asynchronously updates the client profile for the specified user with the provided data.
        /// </summary>
        /// <remarks>Only fields in <paramref name="dto"/> that are provided (non-null or non-empty) will
        /// be updated. The method saves changes to the database before returning the updated profile.</remarks>
        /// <param name="userId">The unique identifier of the user whose client profile is to be updated.</param>
        /// <param name="dto">An object containing the updated profile information. Only non-null and non-empty fields will be applied.</param>
        /// <returns>A <see cref="ClientProfileDto"/> representing the updated client profile.</returns>
        /// <exception cref="KeyNotFoundException">Thrown if no client profile is found for the specified <paramref name="userId"/>.</exception>
        /// <exception cref="InvalidOperationException">Thrown if the user associated with the client profile cannot be found.</exception>
        /// <exception cref="AppException">Thrown if address geocoding fails.</exception>
        public async Task<ClientProfileDto> UpdateProfileAsync(Guid userId, ClientUpdateDto dto)
        {
            try
            {
                Console.WriteLine($"DEBUG: UpdateProfileAsync called for userId: {userId}");

                // Pobierz klienta wraz z danymi użytkownika
                var client = await _context.clients
                    .Include(c => c.User)
                    .FirstOrDefaultAsync(c => c.UserId == userId);

                if (client == null)
                    throw new AppException($"Nie znaleziono profilu klienta dla użytkownika {userId}", ErrorCodes.ClientNotFound);

                if (client.User == null)
                    throw new AppException($"Uzytkonik nie znaleziony dla klienta {client.Id}", ErrorCodes.ClientUserNotFound);

                Console.WriteLine($"DEBUG: Found client: {client.FirstName} {client.LastName}");

                // Aktualizuj dane klienta tylko jeśli nowa wartość jest podana
                if (!string.IsNullOrEmpty(dto.FirstName))
                {
                    Console.WriteLine($"DEBUG: Updating FirstName from '{client.FirstName}' to '{dto.FirstName}'");
                    client.FirstName = dto.FirstName;
                }

                if (!string.IsNullOrEmpty(dto.LastName))
                    client.LastName = dto.LastName;

                if (dto.DateOfBirth.HasValue)
                    client.DateOfBirth = dto.DateOfBirth.Value;

                // AKTUALIZACJA ADRESU Z GEOKODOWANIEM
                if (!string.IsNullOrEmpty(dto.Address))
                {
                    var oldAddress = client.Address;
                    client.Address = dto.Address;
                    client.User.UpdatedAt = DateTime.SpecifyKind(DateTime.UtcNow, DateTimeKind.Unspecified);

                    // Automatyczna geolokalizacja adresu (tylko jeśli adres się zmienił)
                    if (oldAddress != dto.Address)
                    {
                        await GeocodeClientAddressAsync(client);
                    }
                }

                if (!string.IsNullOrEmpty(dto.EmergencyContact))
                    client.EmergencyContact = dto.EmergencyContact;

                // Aktualizuj dane użytkownika (phoneNumber jest w tabeli User)
                if (!string.IsNullOrEmpty(dto.PhoneNumber))
                {
                    client.User.PhoneNumber = dto.PhoneNumber;
                    client.User.UpdatedAt = DateTime.SpecifyKind(DateTime.UtcNow, DateTimeKind.Unspecified);
                }

                // Zapis do bazy
                Console.WriteLine($"DEBUG: Saving changes to database...");
                await _context.SaveChangesAsync();
                Console.WriteLine($"DEBUG: Changes saved successfully");

                // Zwróć zaktualizowany profil (tymczasowo bez AutoMappera)
                return new ClientProfileDto
                {
                    Id = client.Id,
                    UserId = client.UserId,
                    Email = client.User.Email,
                    FirstName = client.FirstName,
                    LastName = client.LastName,
                    PhoneNumber = client.User.PhoneNumber,
                    DateOfBirth = client.DateOfBirth,
                    Address = client.Address,
                    EmergencyContact = client.EmergencyContact,
                    CreatedAt = client.CreatedAt,
                    UpdatedAt = client.User.UpdatedAt
                };
            }
            catch (Exception ex)
            {
                Console.WriteLine($"ERROR in UpdateProfileAsync: {ex.Message}");
                Console.WriteLine($"Stack Trace: {ex.StackTrace}");
                throw; // Przekaż wyjątek do ErrorHandlingMiddleware
            }
        }

        /// <summary>
        /// Geokoduje adres klienta i zapisuje współrzędne
        /// </summary>
        private async Task<bool> GeocodeClientAddressAsync(Client client)
        {
            if (string.IsNullOrEmpty(client.Address))
                return false;

            try
            {
                var geocoded = await _geocoder.GeocodeAddressAsync(client.Address);
                if (geocoded != null)
                {
                    client.AddressPoint = _geocoder.CreatePoint(
                        geocoded.Longitude,
                        geocoded.Latitude
                    );
                    client.AddressGeocodedAt = DateTime.SpecifyKind(DateTime.UtcNow, DateTimeKind.Unspecified);

                    // Zaktualizuj sformatowany adres jeśli dostępny
                    if (!string.IsNullOrEmpty(geocoded.FormattedAddress))
                    {
                        client.Address = geocoded.FormattedAddress;
                    }

                    Console.WriteLine($"DEBUG: Address geocoded successfully: {geocoded.Latitude}, {geocoded.Longitude}");
                    return true;
                }
                else
                {
                    Console.WriteLine($"DEBUG: Geocoding returned no results for address: {client.Address}");
                    return false;
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"DEBUG: Geocoding error: {ex.Message}");
                // Nie rzucamy wyjątku - geokodowanie nie jest krytyczne dla aktualizacji profilu
                return false;
            }
        }

        /// <summary>
        /// Ręcznie geokoduje adres klienta (do użycia z endpointu API)
        /// </summary>
        public async Task<bool> GeocodeClientAddressAsync(Guid userId)
        {
            var client = await _context.clients
                .FirstOrDefaultAsync(c => c.UserId == userId);

            if (client == null)
                throw new AppException($"Nie znaleziono klienta dla użytkownika {userId}", ErrorCodes.ClientNotFound);

            if (string.IsNullOrEmpty(client.Address))
                throw new AppException("Klient nie ma adresu do geokodowania", ErrorCodes.GeocodingFailed);

            var success = await GeocodeClientAddressAsync(client);

            if (success)
            {
                await _context.SaveChangesAsync();
            }

            return success;
        }

        /// <summary>
        /// Pobiera współrzędne geograficzne klienta
        /// </summary>
        public async Task<(double Latitude, double Longitude)?> GetClientCoordinatesAsync(Guid userId)
        {
            var client = await _context.clients
                .FirstOrDefaultAsync(c => c.UserId == userId);

            if (client == null || client.AddressPoint == null)
                return null;

            return (client.AddressPoint.Y, client.AddressPoint.X); // Y = latitude, X = longitude
        }

        /// <summary>
        /// Attempts to change the password for the specified user using the provided current and new passwords.
        /// </summary>
        /// <param name="userId">The unique identifier of the user whose password is to be changed.</param>
        /// <param name="currentPassword">The user's current password. Used to verify the user's identity before allowing the password change.</param>
        /// <param name="newPassword">The new password to set for the user. This will replace the existing password if verification succeeds.</param>
        /// <returns>A value indicating whether the password was successfully changed. Returns <see langword="true"/> if the
        /// password was updated; otherwise, <see langword="false"/> if the current password is incorrect.</returns>
        /// <exception cref="AppException">Thrown if a user with the specified <paramref name="userId"/> does not exist.</exception>
        public async Task<bool> ChangePasswordAsync(Guid userId, string currentPassword, string newPassword)
        {
            // Ta metoda powinna być w AuthService, ale dla wygody dodaję tutaj
            var user = await _context.users.FindAsync(userId);
            if (user == null)
                throw new AppException($"Nie znaleziono użytkownika {userId}", ErrorCodes.UserNotFound);

            if (!BCrypt.Net.BCrypt.Verify(currentPassword, user.PasswordHash))
                return false;

            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(newPassword);
            user.UpdatedAt = DateTime.SpecifyKind(DateTime.UtcNow, DateTimeKind.Unspecified);

            await _context.SaveChangesAsync();
            return true;
        }

        /// <summary>
        /// Asynchronicznie pobiera listę wizyt (terminów) dla klienta z opcjonalnym filtrowaniem po statusie. Wyniki są paginowane
        /// </summary>
        /// <param name="userId"></param>
        /// <param name="request"></param>
        /// <param name="status"></param>
        /// <returns></returns>
        /// <exception cref="KeyNotFoundException"></exception>
        public async Task<PagedResponse<AppointmentDto>> GetAppointmentsAsync(Guid userId, PagedRequest request, string? status = null)
        {
            var client = await _context.clients.FirstOrDefaultAsync(c => c.UserId == userId);
            if (client == null) throw new AppException("Klient nie znaleziony", ErrorCodes.ClientNotFound);

            var query = _context.appointments
                .Include(a => a.Client) // Ważne dla ClientName
                .Include(a => a.Specialist) // Ważne dla SpecialistName
                .Include(a => a.SpecialistService) // Ważne dla ServiceName
                    .ThenInclude(ss => ss.ServiceType)
                .Where(a => a.ClientId == client.Id)
                .AsQueryable();

            if (!string.IsNullOrEmpty(status))
                query = query.Where(a => a.AppointmentStatus == status);

            var totalCount = await query.CountAsync();

            var appointments = await query
                .OrderByDescending(a => a.ScheduledStart)
                .Skip((request.Page - 1) * request.PageSize)
                .Take(request.PageSize)
                .ToListAsync();

            // Mapujemy listę modeli na listę DTO za pomocą AutoMappera
            var items = _mapper.Map<List<AppointmentDto>>(appointments);

            return new PagedResponse<AppointmentDto>
            {
                Items = items,
                TotalCount = totalCount,
                Page = request.Page,
                PageSize = request.PageSize
            };
        }

        /// <summary>
        /// Asynchronicznie pobiera szczegóły wizyty (terminu) dla klienta, w tym informacje o specjaliście i usłudze. Sprawdza, czy wizyta należy do klienta.
        /// </summary>
        /// <param name="userId"></param>
        /// <param name="appointmentId"></param>
        /// <returns></returns>
        /// <exception cref="AppException"></exception>
        public async Task<AppointmentDto> GetAppointmentDetailsAsync(Guid userId, Guid appointmentId)
        {
            // Pobierz profil klienta
            var client = await _context.clients.FirstOrDefaultAsync(c => c.UserId == userId);
            if (client == null) throw new AppException("Klient nie znaleziony", ErrorCodes.ClientNotFound);

            // Pobierz wizytę z uwzględnieniem danych specjalisty i usługi
            var appointment = await _context.appointments
                .Include(a => a.Client)
                .Include(a => a.Specialist)
                .Include(a => a.SpecialistService)
                    .ThenInclude(ss => ss.ServiceType)
                .FirstOrDefaultAsync(a => a.Id == appointmentId && a.ClientId == client.Id);

            if (appointment == null)
                throw new AppException($"Nie znaleziono wizyty o ID {appointmentId} dla tego klienta", ErrorCodes.AppointmentNotFound);

            // Mapuj model wizyty na DTO, w tym nazwy klienta, specjalisty i usługi
            return _mapper.Map<AppointmentDto>(appointment);
        }

        public async Task<AppointmentDto> CreateAppointmentAsync(Guid userId, CreateAppointmentDto dto)
        {
            // TODO: Zaimplementować z walidacją odległości
            throw new NotImplementedException("CreateAppointmentAsync not implemented yet");
        }

        /// <summary>
        /// Anuluj wizytę (termin) klienta, jeśli wizyta należy do niego i nie jest już zakończona lub anulowana. Zwraca true jeśli anulowano, false jeśli nie można anulować z powodu statusu wizyty.
        /// </summary>
        /// <param name="userId"></param>
        /// <param name="appointmentId"></param>
        /// <returns></returns>
        /// <exception cref="KeyNotFoundException"></exception>
        public async Task<bool> CancelAppointmentAsync(Guid userId, Guid appointmentId)
        {
            // Pobierz profil klienta
            var client = await _context.clients.FirstOrDefaultAsync(c => c.UserId == userId);
            if (client == null) return false;

            // Pobierz wizytę i sprawdź, czy należy do klienta
            var appointment = await _context.appointments
                .FirstOrDefaultAsync(a => a.Id == appointmentId && a.ClientId == client.Id);

            // Sprawdź, czy wizyta istnieje i czy nie jest już zakończona lub anulowana
            if (appointment == null) return false;

            // Upewnij się, że porównujesz statusy małymi literami
            if (appointment.AppointmentStatus.ToLower() == "cancelled" ||
                appointment.AppointmentStatus.ToLower() == "completed")
                return false;

            appointment.AppointmentStatus = "cancelled";

            // Zmiana na DateTime.Now i zapewnienie braku "Kind"
            var now = DateTime.Now;
            appointment.CancelledAt = DateTime.SpecifyKind(now, DateTimeKind.Unspecified);
            appointment.UpdatedAt = DateTime.SpecifyKind(now, DateTimeKind.Unspecified);

            // Zapisz zmiany w bazie danych
            await _context.SaveChangesAsync();
            return true;
        }

        /// <summary>
        /// Oblicza odległość między lokalizacją klienta a lokalizacją ogłoszenia serwisowego (ServiceRequest) i sprawdza, 
        /// czy mieści się ona w zdefiniowanym zasięgu obszaru świadczenia usług (ServiceArea) przypisanego do specjalisty. 
        /// Zwraca informacje o dystansie, szacowanym czasie dojazdu oraz czy zlecenie mieści się w zasięgu specjalisty. 
        /// </summary>
        /// <param name="specialistId"></param>
        /// <param name="serviceRequestId"></param>
        /// <returns></returns>
        /// <exception cref="AppException"></exception>
        public async Task<DistanceInfoDto> GetDistanceToServiceRequestAsync(Guid specialistId, Guid serviceRequestId)
        {
            // 1. Pobieramy lokalizację ogłoszenia (ServiceRequest)
            var request = await _context.service_requests
                .Where(r => r.Id == serviceRequestId)
                .Select(r => new { r.Location })
                .FirstOrDefaultAsync();

            if (request == null)
                throw new AppException("Nie znaleziono ogłoszenia.", ErrorCodes.ServiceRequestNotFound);

            if (request.Location == null)
                throw new AppException("Brak lokalizacji ogłoszenia.", ErrorCodes.GeocodingFailed);

            // 2. Szukamy obszarów usług (ServiceAreas) przypisanych do tego specjalisty.
            // Wybieramy ten obszar, którego środek (Location) jest najbliżej zlecenia.
            var nearestArea = await _context.service_areas
                .Where(sa => sa.SpecialistId == specialistId && sa.Location != null)
                .OrderBy(sa => sa.Location!.Distance(request.Location))
                .FirstOrDefaultAsync();

            if (nearestArea == null)
                throw new AppException("Brak zdefiniowanych obszarów.", ErrorCodes.SpecialistNotFound);

            // 3. Obliczenia dystansu (PostGIS zwraca metry, więc dzielimy przez 1000 dla kilometrów)
            double distance = nearestArea.Location!.Distance(request.Location);
            double distanceInKm = 0;

            if (distance < 2.0)
            {
                // Prawdopodobnie stopnie - zamieniamy na km (1 stopień to ok. 111km)
                // Ale lepiej po prostu zapytać o dystans w metrach używając ProjectTo:
                distanceInKm = Math.Round((distance * 111.32), 2);
            }
            else
            {
                // Prawdopodobnie metry
                distanceInKm = Math.Round(distance / 1000, 2);
            }

            // 4. Sprawdzamy, czy zlecenie mieści się w zdefiniowanym zasięgu tego obszaru
            bool isWithinRange = distanceInKm <= nearestArea.MaxDistanceKm;

            // 5. Szacujemy czas (uproszczony model: 1.5 min na km + 5 min rezerwy)
            int estimatedMinutes = (int)(distanceInKm * 1.5) + 5;

            return new DistanceInfoDto
            {
                DistanceKm = distanceInKm,
                DistanceMiles = Math.Round(distanceInKm * 0.621371, 2),
                IsWithinRange = isWithinRange,
                EstimatedTravelTime = $"{estimatedMinutes} min"
            };
        }

        public async Task<PagedResponse<SpecialistDto>> SearchSpecialistsAsync(SearchSpecialistsDto filters, PagedRequest request)
        {
            // TODO: Zaimplementować z filtrowaniem po odległości
            // Na razie zwróć pustą listę
            return new PagedResponse<SpecialistDto>
            {
                Items = new List<SpecialistDto>(),
                Page = request.Page,
                PageSize = request.PageSize,
                TotalCount = 0
            };
        }

        /// <summary>
        /// Pobiera ID klienta na podstawie ID użytkownika
        /// </summary>
        private async Task<Guid> GetClientIdFromUserId(Guid userId)
        {
            var client = await _context.clients
                .FirstOrDefaultAsync(c => c.UserId == userId);

            if (client == null)
                throw new AppException($"Klient nie znaleziony dla użytkownika {userId}", ErrorCodes.ClientNotFound);

            return client.Id;
        }

        /// <summary>
        /// Asynchronicznie tworzy nowe ogłoszenie serwisowe na podstawie danych z formularza. 
        /// Jeśli użytkownik jest zalogowany, powiązuje ogłoszenie z jego profilem klienta. 
        /// Następnie geokoduje podany adres i zapisuje ogłoszenie w bazie danych. Zwraca ID nowo utworzonego ogłoszenia.
        /// </summary>
        /// <param name="dto"></param>
        /// <param name="userId"></param>
        /// <returns></returns>
        public async Task<Guid> CreateServiceRequestAsync(CreateServiceRequestDto dto, Guid? userId = null)
        {
            Guid? finalClientId = null;

            // Jeśli użytkownik jest zalogowany, znajdź jego ID Klienta
            if (userId.HasValue)
            {
                var client = await _context.clients.FirstOrDefaultAsync(c => c.UserId == userId.Value);
                finalClientId = client?.Id;
            }

            // GEOKODOWANIE: Zawsze geokodujemy adres wpisany w formularzu
            // 1. Próbujemy zgeokodować adres
            var geocoded = await _geocoder.GeocodeAddressAsync(dto.Address);

            // 2. Jeśli się nie udało, nie pozwalamy przejść dalej
            if (geocoded == null)
            {
                throw new AppException(
                    "Nie udało się odnaleźć podanego adresu na mapie. Spróbuj podać bardziej szczegółowy adres (ulica, numer, miasto).",
                    ErrorCodes.GeocodingFailed
                );
            }

            // 3. Jeśli mamy dane, dopiero wtedy tworzymy obiekt
            var request = new ServiceRequest
            {
                Id = Guid.NewGuid(),
                ClientId = finalClientId, // Teraz przypisujemy poprawne ID klienta (lub null dla gościa)
                ServiceTypeId = dto.ServiceTypeId,
                Description = dto.Description,
                DateFrom = DateTime.SpecifyKind(dto.DateFrom, DateTimeKind.Unspecified),
                DateTo = DateTime.SpecifyKind(dto.DateTo, DateTimeKind.Unspecified),

                // Dane z formularza (ekran 1)
                ContactName = dto.ContactName,
                PhoneNumber = dto.PhoneNumber,
                Email = dto.Email,
                Address = geocoded?.FormattedAddress ?? dto.Address,

                Status = "open",
                Location = geocoded != null ? _geocoder.CreatePoint(geocoded.Longitude, geocoded.Latitude) : null
            };

            _context.service_requests.Add(request);
            await _context.SaveChangesAsync();
            return request.Id;
        }

        /// <summary>
        /// Asynchronicznie pobiera listę ogłoszeń serwisowych (prośby o usługę) utworzonych przez zalogowanego klienta.
        /// </summary>
        /// <param name="userId"></param>
        /// <returns></returns>
        /// <exception cref="AppException"></exception>
        public async Task<List<ServiceRequestDto>> GetMyServiceRequestsAsync(Guid userId)
        {
            var client = await _context.clients.FirstOrDefaultAsync(c => c.UserId == userId);
            if (client == null) throw new AppException("Nie znaleziono klienta", ErrorCodes.ClientNotFound);

            var requests = await _context.service_requests
                .Include(r => r.ServiceType)
                .Where(r => r.ClientId == client.Id)
                .OrderByDescending(r => r.CreatedAt)
                .ToListAsync();

            // Automapper zamieni Encje na DTO automatycznie
            return _mapper.Map<List<ServiceRequestDto>>(requests);
        }
    }
}