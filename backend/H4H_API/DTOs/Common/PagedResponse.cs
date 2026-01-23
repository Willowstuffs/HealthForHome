namespace H4H_API.DTOs.Common
{
    // Klasa odpowiedzi ze stronicowaniem dla list
    public class PagedResponse<T>
    {
        public List<T> Items { get; set; } = new();   // Lista elementów na bieżącej stronie
        public int Page { get; set; }                 // Numer bieżącej strony
        public int PageSize { get; set; }             // Liczba elementów na stronie
        public int TotalCount { get; set; }           // Całkowita liczba elementów
        public int TotalPages => PageSize > 0 ? (int)Math.Ceiling(TotalCount / (double)PageSize) : 0; // Obliczona liczba stron
        public bool HasPreviousPage => Page > 1;      // Czy istnieje poprzednia strona
        public bool HasNextPage => Page < TotalPages; // Czy istnieje następna strona
    }
}
