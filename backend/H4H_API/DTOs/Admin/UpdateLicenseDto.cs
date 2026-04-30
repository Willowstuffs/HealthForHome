using System.ComponentModel.DataAnnotations;

namespace H4H_API.DTOs.Admin
{
    public class UpdateLicenseDto
    {
        [Required]
        public DateTime ValidUntil { get; set; }
    }
}