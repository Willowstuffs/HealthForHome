using System.ComponentModel.DataAnnotations.Schema;
using System.Drawing;
using NetTopologySuite.Geometries;

namespace H4H.Core.Models
{
    [Table("clients")]
    public class Client
    {
        [Column("id")]
        public Guid Id { get; set; }

        [Column("user_id")]
        public Guid UserId { get; set; }

        [Column("first_name")]
        public string FirstName { get; set; } = string.Empty;

        [Column("last_name")]
        public string LastName { get; set; } = string.Empty;

        [Column("date_of_birth", TypeName = "date")]
        public DateOnly? DateOfBirth { get; set; }

        [Column("address")]
        public string? Address { get; set; }

        [Column("emergency_contact")]
        public string? EmergencyContact { get; set; }

        [Column("created_at", TypeName = "timestamp without time zone")]
        public DateTime CreatedAt { get; set; } = DateTime.SpecifyKind(DateTime.Now, DateTimeKind.Unspecified);

        // ====== NOWE POLA DLA GEOLOKALIZACJI ======

        /// <summary>
        /// Punkt geograficzny adresu klienta
        /// </summary>
        [Column("address_point", TypeName = "geography(Point, 4326)")]
        public NetTopologySuite.Geometries.Point? AddressPoint { get; set; }

        /// <summary>
        /// Kiedy zgeokodowano adres klienta
        /// </summary>
        [Column("address_geocoded_at", TypeName = "timestamp without time zone")]
        public DateTime? AddressGeocodedAt { get; set; }

        // ==========================================

        public virtual User User { get; set; } = null!;
        public virtual ICollection<Appointment> Appointments { get; set; } = new List<Appointment>();
        public virtual ICollection<Review> Reviews { get; set; } = new List<Review>();
    }
}