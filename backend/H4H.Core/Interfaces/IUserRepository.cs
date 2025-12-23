using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using H4H.Core.Models;

namespace H4H.Core.Interfaces
{
    public interface IUserRepository
    {
        Task<bool> EmailExistsAsync(string email);
        Task<User> CreateUserAsync(string email, string password, string firstName, string lastName, string userType);
        Task<User?> AuthenticateAsync(string email, string password);
        Task<User?> GetUserByIdAsync(Guid id);
    }
}