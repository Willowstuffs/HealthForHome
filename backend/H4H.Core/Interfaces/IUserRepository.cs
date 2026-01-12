using H4H.Core.Models;

namespace H4H.Core.Interfaces
{
    // Interfejs repozytorium użytkowników - definiuje kontrakt dla dostępu do danych
    public interface IUserRepository
    {
        /// <summary>
        /// Asynchronously determines whether a user account with the specified email address exists.
        /// </summary>
        /// <param name="email">The email address to check for existence. Cannot be null or empty.</param>
        /// <returns>A task that represents the asynchronous operation. The task result is <see langword="true"/> if an account
        /// with the specified email exists; otherwise, <see langword="false"/>.</returns>
        Task<bool> EmailExistsAsync(string email);

        /// <summary>
        /// Asynchronously creates a new user account with the specified details.
        /// </summary>
        /// <param name="email">The email address for the new user account. Must be a valid, non-empty email address.</param>
        /// <param name="password">The password for the new user account. Must meet the application's password requirements.</param>
        /// <param name="firstName">The first name of the user. Cannot be null or empty.</param>
        /// <param name="lastName">The last name of the user. Cannot be null or empty.</param>
        /// <param name="userType">The type of user to create. Specifies the user's role or access level.</param>
        /// <returns>A task that represents the asynchronous operation. The task result contains the created <see cref="User"/>
        /// object.</returns>
        Task<User> CreateUserAsync(string email, string password, string firstName, string lastName, string userType);

        /// <summary>
        /// Asynchronously authenticates a user using the specified email address and password.
        /// </summary>
        /// <param name="email">The email address of the user to authenticate. Cannot be null or empty.</param>
        /// <param name="password">The password associated with the specified email address. Cannot be null or empty.</param>
        /// <returns>A task that represents the asynchronous operation. The task result contains the authenticated <see
        /// cref="User"/> if the credentials are valid; otherwise, <see langword="null"/>.</returns>
        Task<User?> AuthenticateAsync(string email, string password);

        /// <summary>
        /// Asynchronously retrieves a user by their unique identifier.
        /// </summary>
        /// <param name="id">The unique identifier of the user to retrieve.</param>
        /// <returns>A task that represents the asynchronous operation. The task result contains the user associated with the
        /// specified identifier, or <see langword="null"/> if no user is found.</returns>
        Task<User?> GetUserByIdAsync(Guid id);
    }
}