using System.ComponentModel.DataAnnotations;

namespace H4H_API.DTOs.Client
{
    public class CreateServiceRequestDto
    {
        // Ekran 0 i 1: Wybór kategorii/usługi
        // Klient wybiera: "nursing" lub "physiotherapy"
        [Required]
        public string Category { get; set; }

        // Ekran 1: Dane kontaktowe i adres
        public string? ContactName { get; set; }  // "Imię (opcjonalnie)"
        public string? PhoneNumber { get; set; } // "Telefon"
        public string? Email { get; set; }       // "Email"
        public string Address { get; set; }      // "Adres zamieszkania"

        // Ekran 1: Wybierz datę od do
        [Required]
        public DateTime DateFrom { get; set; }
        [Required]
        public DateTime DateTo { get; set; }

        // Ekran 1: Uwagi
        public string Description { get; set; } // "Uwagi"

        public decimal? MaxPrice { get; set; }
    }
}
