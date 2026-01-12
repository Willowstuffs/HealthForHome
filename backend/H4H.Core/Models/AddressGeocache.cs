// H4H.Core/Models/AddressGeocache.cs
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace H4H.Core.Models
{
    /// <summary>
    /// Cache geokodowanych adresów - zapisuje wyniki geokodowania żeby nie pytać API za każdym razem
    /// </summary>
    [Table("address_geocache")]
    public class AddressGeocache
    {
        [Key]
        [Column("id")]
        public Guid Id { get; set; } = Guid.NewGuid();

        /// <summary>
        /// Hash SHA256 adresu dla szybkiego wyszukiwania (unikalny)
        /// </summary>
        [Required]
        [MaxLength(64)]
        [Column("address_hash")]
        public string AddressHash { get; set; } = string.Empty;

        /// <summary>
        /// Pełny adres tekstowy
        /// </summary>
        [Required]
        [Column("address")]
        public string Address { get; set; } = string.Empty;

        /// <summary>
        /// Szerokość geograficzna (latitude)
        /// </summary>
        [Column("latitude", TypeName = "decimal(10, 8)")]
        public decimal Latitude { get; set; }

        /// <summary>
        /// Długość geograficzna (longitude)
        /// </summary>
        [Column("longitude", TypeName = "decimal(11, 8)")]
        public decimal Longitude { get; set; }

        /// <summary>
        /// Sformatowany adres zwrócony przez API geokodujące
        /// </summary>
        [Column("formatted_address")]
        public string? FormattedAddress { get; set; }

        /// <summary>
        /// Data utworzenia wpisu w cache
        /// </summary>
        [Column("created_at", TypeName = "timestamp without time zone")]
        public DateTime CreatedAt { get; set; } = DateTime.SpecifyKind(DateTime.UtcNow, DateTimeKind.Unspecified);
    }
}