using System.ComponentModel.DataAnnotations.Schema;

namespace H4H.Core.Models
{
    [Table("specialists")]
    public class Specialist
    {
        [Column("id")]
        public Guid Id { get; set; }

        [Column("user_id")]
        public Guid UserId { get; set; }

        [Column("first_name")]
        public string FirstName { get; set; } = string.Empty;

        [Column("last_name")]
        public string LastName { get; set; } = string.Empty;

        [Column("professional_title")]
        public string? ProfessionalTitle { get; set; }

        [Column("bio")]
        public string? Bio { get; set; }

        [Column("hourly_rate")]
        public decimal? HourlyRate { get; set; }

        [Column("is_verified")]
        public bool IsVerified { get; set; } = false;

        [Column("verification_status")]
        public string VerificationStatus { get; set; } = "pending";

        [Column("average_rating")]
        public decimal AverageRating { get; set; } = 0.00m;

        [Column("total_reviews")]
        public int TotalReviews { get; set; } = 0;

        [Column("verified_at", TypeName = "timestamp without time zone")]
        public DateTime? VerifiedAt { get; set; }

        [Column("created_at", TypeName = "timestamp without time zone")]
        public DateTime CreatedAt { get; set; } = DateTime.SpecifyKind(DateTime.Now, DateTimeKind.Unspecified);

        // Nowe pola do zarządzania zawieszeniem konta specjalisty 
        [Column("is_suspended")]
        public bool IsSuspended { get; set; } = false;

        [Column("suspended_at", TypeName = "timestamp without time zone")]
        public DateTime? SuspendedAt { get; set; }



        public virtual User User { get; set; } = null!;
        public virtual ICollection<SpecialistService> Services { get; set; } = new List<SpecialistService>();
        public virtual ICollection<ServiceArea> ServiceAreas { get; set; } = new List<ServiceArea>();
        public virtual ICollection<SpecialistAvailability> Availabilities { get; set; } = new List<SpecialistAvailability>();
        public virtual ICollection<BookedSlot> BookedSlots { get; set; } = new List<BookedSlot>();
        public virtual ICollection<Appointment> Appointments { get; set; } = new List<Appointment>();
        public virtual ICollection<Review> Reviews { get; set; } = new List<Review>();
        public virtual ICollection<SpecialistQualification> Qualifications { get; set; } = new List<SpecialistQualification>();
        public virtual ICollection<VerificationLog> VerificationLogs { get; set; } = new List<VerificationLog>();
    }
}