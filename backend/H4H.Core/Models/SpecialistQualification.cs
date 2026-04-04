using System.ComponentModel.DataAnnotations.Schema;

namespace H4H.Core.Models
{
    [Table("specialist_qualifications")]
    public class SpecialistQualification
    {
        [Column("id")]
        public Guid Id { get; set; }

        [Column("specialist_id")]
        public Guid SpecialistId { get; set; }

        [Column("profession")]
        public string Profession { get; set; } = string.Empty;

        [Column("license_number")]
        public string LicenseNumber { get; set; } = string.Empty;

        [Column("license_photo_url")]
        public string? LicensePhotoUrl { get; set; }

        [Column("id_card_photo_url")]
        public string? IdCardPhotoUrl { get; set; }

        [Column("verification_notes")]
        public string? VerificationNotes { get; set; }

        [Column("verified_by_admin_id")]
        public Guid? VerifiedByAdminId { get; set; }

        [Column("verified_at", TypeName = "timestamp without time zone")]
        public DateTime? VerifiedAt { get; set; }

        [Column("is_active")]
        public bool IsActive { get; set; } = true;

        [Column("created_at", TypeName = "timestamp without time zone")]
        public DateTime CreatedAt { get; set; } = DateTime.SpecifyKind(DateTime.Now, DateTimeKind.Unspecified);
        [Column("license_valid_until", TypeName = "timestamp without time zone")]
        public DateTime? LicenseValidUntil { get; set; }

        public virtual Specialist Specialist { get; set; } = null!;
        public virtual Admin? VerifiedByAdmin { get; set; }
    }
}