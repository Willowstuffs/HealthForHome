using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace H4H_API.DTOs.Admin
{
    public class UpdateLicenseDto
    {
        [Required]
        [JsonPropertyName("licenseValidUntil")]
        public DateTime ValidUntil { get; set; }
    }
}