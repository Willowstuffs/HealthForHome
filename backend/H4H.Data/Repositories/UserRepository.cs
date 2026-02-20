using Microsoft.EntityFrameworkCore;
using H4H.Core.Interfaces;
using H4H.Core.Models;
using H4H.Data;

namespace H4H.Data.Repositories
{
    public class UserRepository : IUserRepository
    {
        private readonly ApplicationDbContext _context;

        public UserRepository(ApplicationDbContext context)
        {
            _context = context;
        }


        // Sprawdza czy email już istnieje w bazie

        public async Task<bool> EmailExistsAsync(string email)
        {
            return await _context.users.AnyAsync(u => u.Email == email);
        }


        // Tworzy nowego użytkownika (i odpowiedniego klienta/specjalistę)
        public async Task<User> CreateUserAsync(string email, string password, string firstName, string lastName, string userType)
        {
            // Utwórz DateTime bez Kind (Unspecified) - ważne dla PostgreSQL

            var unspecifiedNow = DateTime.SpecifyKind(DateTime.Now, DateTimeKind.Unspecified);

            var user = new User
            {
                Id = Guid.NewGuid(),
                Email = email,

                PasswordHash = BCrypt.Net.BCrypt.HashPassword(password),  // Hashowanie hasła

                UserType = userType,
                PhoneNumber = null, // Dodaj brakujące pola
                AvatarUrl = null,
                IsActive = true,

                CreatedAt = unspecifiedNow, // Użycie Unspecified dla PostgreSQL
                UpdatedAt = unspecifiedNow, // Użycie Unspecified dla PostgreSQL

                LastLoginAt = null
            };

            _context.users.Add(user);


            // Jeśli to klient, utwórz również rekord w tabeli clients

            if (userType == "client")
            {
                var client = new Client
                {
                    Id = Guid.NewGuid(),
                    UserId = user.Id,
                    FirstName = firstName,
                    LastName = lastName,
                    DateOfBirth = null,
                    Address = null,
                    EmergencyContact = null,
                    CreatedAt = unspecifiedNow // ← TU POPRAWIONE
                };
                _context.clients.Add(client);
            }

            await _context.SaveChangesAsync();
            return user;
        }

        // Autentykacja użytkownika (logowanie)
        public async Task<User?> AuthenticateAsync(string email, string password)
        {
            // Pobierz użytkownika z danymi klienta/specjalisty
            var user = await _context.users
                .Include(u => u.Client) // Dołącz dane klienta
                .Include(u => u.Specialist) // Dołącz dane specjalisty
                .FirstOrDefaultAsync(u => u.Email == email && u.IsActive); // Tylko aktywni użytkownicy

            // Sprawdź czy użytkownik istnieje i czy hasło się zgadza

            if (user == null || !BCrypt.Net.BCrypt.Verify(password, user.PasswordHash))
                return null;

            // Aktualizuj last login również z Unspecified
            user.LastLoginAt = DateTime.SpecifyKind(DateTime.Now, DateTimeKind.Unspecified);
            await _context.SaveChangesAsync();

            return user;
        }


        // Pobiera użytkownika po ID

        public async Task<User?> GetUserByIdAsync(Guid id)
        {
            return await _context.users
                .Include(u => u.Client)
                .Include(u => u.Specialist)
                .FirstOrDefaultAsync(u => u.Id == id);
        }

        // Dodatkowe metody które mogą być potrzebne:

        
        // Pobiera użytkownika po emailu
        public async Task<User?> GetUserByEmailAsync(string email)
        {
            return await _context.users
                .Include(u => u.Client)
                .Include(u => u.Specialist)
                .FirstOrDefaultAsync(u => u.Email == email);
        }

        // Aktualizuje dane użytkownika
        public async Task<bool> UpdateUserAsync(User user)
        {
            user.UpdatedAt = DateTime.SpecifyKind(DateTime.Now, DateTimeKind.Unspecified);
            _context.users.Update(user);
            return await _context.SaveChangesAsync() > 0;
        }


        // Dezaktywuje użytkownika (soft delete)
        public async Task<bool> DeactivateUserAsync(Guid userId)
        {
            var user = await GetUserByIdAsync(userId);
            if (user == null) return false;


            user.IsActive = false; // Soft delete - użytkownik nieaktywny

            user.UpdatedAt = DateTime.SpecifyKind(DateTime.Now, DateTimeKind.Unspecified);
            return await _context.SaveChangesAsync() > 0;
        }
    }
}