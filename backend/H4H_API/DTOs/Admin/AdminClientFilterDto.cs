using H4H_API.DTOs.Common;

namespace H4H_API.DTOs.Admin
{
    /// <summary>
    /// DTO zawierający opcje filtrowania, sortowania i paginacji do zastosowania przy wyborze klientów.
    /// </summary>
    public class AdminClientFilterDto : PagedRequest
    {
        public string? SearchTerm { get; set; }
    }
}