using AutoMapper;
using H4H_API.DTOs.Appointments;
using H4H_API.DTOs.Common;
using H4H_API.DTOs.Specialist;
using H4H.Core.Models;
using H4H.Data;
using H4H_API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using H4H_API.DTOs.Client;

namespace H4H_API.Services.Implementations
{
    public class ClientService : IClientService
    {
        private readonly ApplicationDbContext _context;
        private readonly IMapper _mapper;

        public ClientService(ApplicationDbContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        public async Task<ClientProfileDto> GetProfileAsync(Guid userId)
        {
            var client = await _context.clients
                .Include(c => c.User)
                .FirstOrDefaultAsync(c => c.UserId == userId);

            if (client == null)
                throw new KeyNotFoundException($"Nie znaleziono profilu klienta dla użytkownika {userId}");

            return _mapper.Map<ClientProfileDto>(client);
        }

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
                    throw new KeyNotFoundException($"Nie znaleziono profilu klienta dla użytkownika {userId}");

                if (client.User == null)
                    throw new InvalidOperationException($"User not found for client {client.Id}");

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

                if (!string.IsNullOrEmpty(dto.Address))
              client.User.UpdatedAt = DateTime.UtcNow;      
                client.Address = dto.Address;

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

        public async Task<bool> ChangePasswordAsync(Guid userId, string currentPassword, string newPassword)
        {
            // Ta metoda powinna być w AuthService, ale dla wygody dodaję tutaj
            var user = await _context.users.FindAsync(userId);
            if (user == null)
                throw new KeyNotFoundException($"Nie znaleziono użytkownika {userId}");

            if (!BCrypt.Net.BCrypt.Verify(currentPassword, user.PasswordHash))
                return false;

            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(newPassword);
            user.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<PagedResponse<AppointmentDto>> GetAppointmentsAsync(Guid userId, PagedRequest request, string? status = null)
        {
            // TODO: Zaimplementować po stworzeniu AppointmentDto
            // Na razie zwróć pustą listę
            return new PagedResponse<AppointmentDto>
            {
                Items = new List<AppointmentDto>(),
                Page = request.Page,
                PageSize = request.PageSize,
                TotalCount = 0
            };
        }

        public async Task<AppointmentDto> GetAppointmentDetailsAsync(Guid userId, Guid appointmentId)
        {
            // TODO: Zaimplementować
            throw new NotImplementedException("GetAppointmentDetailsAsync not implemented yet");
        }

        public async Task<AppointmentDto> CreateAppointmentAsync(Guid userId, CreateAppointmentDto dto)
        {
            // TODO: Zaimplementować
            throw new NotImplementedException("CreateAppointmentAsync not implemented yet");
        }

        public async Task<bool> CancelAppointmentAsync(Guid userId, Guid appointmentId)
        {
            // TODO: Zaimplementować
            throw new NotImplementedException("CancelAppointmentAsync not implemented yet");
        }

        public async Task<PagedResponse<SpecialistDto>> SearchSpecialistsAsync(SearchSpecialistsDto filters, PagedRequest request)
        {
            // TODO: Zaimplementować
            // Na razie zwróć pustą listę
            return new PagedResponse<SpecialistDto>
            {
                Items = new List<SpecialistDto>(),
                Page = request.Page,
                PageSize = request.PageSize,
                TotalCount = 0
            };
        }
    }
}