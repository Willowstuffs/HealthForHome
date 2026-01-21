using System.ComponentModel.DataAnnotations.Schema;
using System.Drawing;
using NetTopologySuite.Geometries;


namespace H4H.Core.Models
{
    [Table("service_areas")]
    public class ServiceArea
    {
        [Column("id")]
        public Guid Id { get; set; }

        [Column("specialist_id")]
        public Guid SpecialistId { get; set; }

        [Column("city")]
        public string City { get; set; } = string.Empty;

        [Column("postal_code")]
        public string? PostalCode { get; set; }

        [Column("max_distance_km")]
        public int MaxDistanceKm { get; set; } = 20;

        [Column("is_primary")]
        public bool IsPrimary { get; set; } = false;

        [Column("created_at", TypeName = "timestamp without time zone")]
        public DateTime CreatedAt { get; set; } = DateTime.SpecifyKind(DateTime.Now, DateTimeKind.Unspecified);

        // ====== NOWE POLA DLA GEOLOKALIZACJI ======

        /// <summary>
        /// Punkt geograficzny (PostGIS Point) z współrzędnymi
        /// X = longitude (długość geograficzna)
        /// Y = latitude (szerokość geograficzna)
        /// SRID 4326 = standard WGS84 (używany przez GPS)
        /// </summary>
        [Column("location", TypeName = "geography(Point, 4326)")]
        public NetTopologySuite.Geometries.Point? Location { get; set; }

        /// <summary>
        /// Kiedy ostatnio zaktualizowano współrzędne
        /// </summary>
        [Column("location_updated_at", TypeName = "timestamp without time zone")]
        public DateTime? LocationUpdatedAt { get; set; }

        // ==========================================

        public virtual Specialist Specialist { get; set; } = null!;
    }
}