using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.ComponentModel.DataAnnotations.Schema;
using H4H.Core.Helpers;

namespace H4H.Core.Models
{
    [Table("appointments_specialists")]
    public class AppointmentSpecialist
    {
        [Column("id")]
        public Guid Id { get; set; }

        [Column("appointment_id")]
        public Guid AppointmentId { get; set; }

        [Column("specialist_id")]
        public Guid SpecialistId { get; set; }

        [Column("price")]
        public decimal? Price { get; set; }

        [Column("service_type_ids")]
        public List<Guid> ServiceTypeIds { get; set; } = new List<Guid>();

        [Column("created_at")]
        public DateTime CreatedAt { get; set; } = DateTimeHelper.NowUnspecified;

        // Relacje do innych tabel
        public virtual Appointment Appointment { get; set; } = null!;
        public virtual Specialist Specialist { get; set; } = null!;
    }
}
