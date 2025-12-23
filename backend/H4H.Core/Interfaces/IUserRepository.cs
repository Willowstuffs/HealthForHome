using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using H4H.Core.Models;

namespace H4H.Core.Interfaces
{
    // Interfejs repozytorium użytkowników - definiuje kontrakt dla dostępu do danych
    public interface IUserRepository
    {
        // Sprawdza czy email już istnieje
        Task<bool> EmailExistsAsync(string email);

        // Tworzy nowego użytkownika
        Task<User> CreateUserAsync(string email, string password, string firstName, string lastName, string userType);

        // Autentykuje użytkownika (logowanie)
        Task<User?> AuthenticateAsync(string email, string password);

        // Pobiera użytkownika po ID
        Task<User?> GetUserByIdAsync(Guid id);
    }
}