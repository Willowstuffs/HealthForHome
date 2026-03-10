using System.ComponentModel.DataAnnotations;

namespace H4H_API.DTOs.Common
{
    // DTO dla żądań ze stronicowaniem
    public class PagedRequest
    {
        [Range(1, int.MaxValue, ErrorMessage = "Numer strony musi być większy od 0")]
        public int Page { get; set; } = 1; // Domyślnie strona 1

        [Range(1, 100, ErrorMessage = "Rozmiar strony musi być między 1 a 100")]
        public int PageSize { get; set; } = 10; // Domyślnie 10 elementów na stronie

        public string? SortBy { get; set; } // Po której kolumnie sortować
        public bool SortDescending { get; set; } = false; // Kierunek sortowania (rosnąco/malejąco)
    }
}
