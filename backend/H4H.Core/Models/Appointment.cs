using System.ComponentModel.DataAnnotations.Schema;
using NetTopologySuite.Geometries;

namespace H4H.Core.Models
{
    [Table("appointments")]
    public class Appointment
    {
        [Column("id")]
        public Guid Id { get; set; }

        [Column("client_id")]
        public Guid ClientId { get; set; } // usuwam opcje wysylania dla gości - nie moze byc null

        [Column("specialist_id")]
        public Guid? SpecialistId { get; set; } // Zmiana na nullable (dla ogłoszeń "open")

        [Column("specialist_service_ids")]
        public Guid[] SpecialistServiceIds { get; set; } = Array.Empty<Guid>(); // Zmiana na tablicę Guidów (dla wielu usług) - może być pusta dla ogłoszeń "open"

        [Column("service_type_id")]
        public Guid ServiceTypeId { get; set; } // kategoria uslugi akceptowana w ogłoszeniu

        [Column("location")]
        public Point? Location { get; set; } // Kolumna do obliczeń dystansu (PostGIS/NetTopologySuite)
        [Column("appointment_status")]
        public string AppointmentStatus { get; set; } = "open";

        [Column("scheduled_start", TypeName = "timestamp without time zone")]
        public DateTime ScheduledStart { get; set; }

        [Column("scheduled_end", TypeName = "timestamp without time zone")]
        public DateTime ScheduledEnd { get; set; }

        [Column("total_price")]
        public decimal? TotalPrice { get; set; }

        [Column("client_address")]
        public string? ClientAddress { get; set; }
        
        // Poprawa formatowania - podzial client_notes:

        // NOWE POLA:
        [Column("contact_name")]
        public string ContactName { get; set; } = string.Empty;

        [Column("contact_phone_number")]
        public string ContactPhoneNumber { get; set; } = string.Empty;

        [Column("contact_email")]
        public string ContactEmail { get; set; } = string.Empty;

        // To zostaje, ale od teraz będzie tu TYLKO czysty opis od klienta
        [Column("client_notes")]
        public string? ClientNotes { get; set; }


        [Column("specialist_notes")]
        public string? SpecialistNotes { get; set; }

        [Column("created_at", TypeName = "timestamp without time zone")]
        public DateTime CreatedAt { get; set; } = DateTime.SpecifyKind(DateTime.Now, DateTimeKind.Unspecified);

        [Column("updated_at", TypeName = "timestamp without time zone")]
        public DateTime UpdatedAt { get; set; } = DateTime.SpecifyKind(DateTime.Now, DateTimeKind.Unspecified);

        [Column("cancelled_at", TypeName = "timestamp without time zone")]
        public DateTime? CancelledAt { get; set; }

        [Column("selected_specialist_id")]
        public Guid? SelectedSpecialistId { get; set; }

        [Column("final_date")] // dodanie pola na ostateczną datę (z godziną) po wyborze specjalisty
        public DateTime? FinalDate { get; set; }

        [Column("is_rated")] // dodanie pola do oznaczania, czy wizyta została oceniona (po wystawieniu opinii przez klienta)
        public bool IsRated { get; set; } = false;


        public virtual Client Client { get; set; } = null!;
        public virtual Specialist? Specialist { get; set; } 
        //public virtual SpecialistService? SpecialistService { get; set; } // usuwam, bo teraz mamy tablicę SpecialistServiceIds - relacja będzie realizowana przez AppointmentSpecialist
        public virtual ServiceType ServiceType { get; set; } = null!;

        public virtual Payment? Payment { get; set; }
        public virtual Review? Review { get; set; }
        public virtual ICollection<Message> Messages { get; set; } = new List<Message>();
        public virtual ICollection<AppointmentSpecialist> AppointmentSpecialists { get; set; } = new List<AppointmentSpecialist>();
    }
}