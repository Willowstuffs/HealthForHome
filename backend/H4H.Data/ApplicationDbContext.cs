using Microsoft.EntityFrameworkCore;
using H4H.Core.Models;

namespace H4H.Data
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
            : base(options)
        {
        }

        // DbSets - wszystkie tabele z bazy
        public DbSet<User> users { get; set; }
        public DbSet<Client> clients { get; set; }
        public DbSet<Specialist> specialists { get; set; }
        public DbSet<ServiceType> service_types { get; set; }
        public DbSet<SpecialistService> specialist_services { get; set; }
        public DbSet<ServiceArea> service_areas { get; set; }
        public DbSet<SpecialistAvailability> specialist_availabilities { get; set; }
        public DbSet<BookedSlot> booked_slots { get; set; }
        public DbSet<Appointment> appointments { get; set; }
        public DbSet<Payment> payments { get; set; }
        public DbSet<Review> reviews { get; set; }
        public DbSet<SpecialistQualification> specialist_qualifications { get; set; }
        public DbSet<Admin> admins { get; set; }
        public DbSet<VerificationLog> verification_logs { get; set; }
        public DbSet<Message> messages { get; set; }
        public DbSet<Notification> notifications { get; set; }
        public DbSet<VerificationCode> verification_codes { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Konfiguracja tabel
            modelBuilder.Entity<User>(entity =>
            {
                entity.HasIndex(e => e.Email).IsUnique();
                entity.Property(e => e.UserType).HasMaxLength(20);
            });

            modelBuilder.Entity<Client>(entity =>
            {
                entity.HasOne(c => c.User)
                    .WithOne(u => u.Client)
                    .HasForeignKey<Client>(c => c.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            modelBuilder.Entity<Specialist>(entity =>
            {
                entity.HasOne(s => s.User)
                    .WithOne(u => u.Specialist)
                    .HasForeignKey<Specialist>(s => s.UserId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.Property(s => s.VerificationStatus)
                    .HasMaxLength(20);
            });

            modelBuilder.Entity<ServiceType>(entity =>
            {
                entity.Property(s => s.Category).HasMaxLength(50);
                entity.HasIndex(s => s.Name);
            });

            modelBuilder.Entity<SpecialistService>(entity =>
            {
                entity.HasOne(ss => ss.Specialist)
                    .WithMany(s => s.Services)
                    .HasForeignKey(ss => ss.SpecialistId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasOne(ss => ss.ServiceType)
                    .WithMany(st => st.SpecialistServices)
                    .HasForeignKey(ss => ss.ServiceTypeId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            modelBuilder.Entity<ServiceArea>(entity =>
            {
                entity.HasOne(sa => sa.Specialist)
                    .WithMany(s => s.ServiceAreas)
                    .HasForeignKey(sa => sa.SpecialistId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasIndex(sa => sa.City);
            });

            modelBuilder.Entity<SpecialistAvailability>(entity =>
            {
                entity.HasOne(sa => sa.Specialist)
                    .WithMany(s => s.Availabilities)
                    .HasForeignKey(sa => sa.SpecialistId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasIndex(sa => sa.Date);
            });

            modelBuilder.Entity<BookedSlot>(entity =>
            {
                entity.HasOne(bs => bs.Specialist)
                    .WithMany(s => s.BookedSlots)
                    .HasForeignKey(bs => bs.SpecialistId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasIndex(bs => bs.StartDateTime);
                entity.HasIndex(bs => bs.EndDateTime);
            });

            modelBuilder.Entity<Appointment>(entity =>
            {
                entity.HasOne(a => a.Client)
                    .WithMany(c => c.Appointments)
                    .HasForeignKey(a => a.ClientId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasOne(a => a.Specialist)
                    .WithMany(s => s.Appointments)
                    .HasForeignKey(a => a.SpecialistId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasOne(a => a.SpecialistService)
                    .WithMany(ss => ss.Appointments)
                    .HasForeignKey(a => a.SpecialistServiceId)
                    .OnDelete(DeleteBehavior.SetNull);

                entity.Property(a => a.AppointmentStatus)
                    .HasMaxLength(20);

                entity.HasIndex(a => a.ScheduledStart);
                entity.HasIndex(a => a.AppointmentStatus);
            });

            modelBuilder.Entity<Payment>(entity =>
            {
                entity.HasOne(p => p.Appointment)
                    .WithOne(a => a.Payment)
                    .HasForeignKey<Payment>(p => p.AppointmentId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasIndex(p => p.AppointmentId).IsUnique();
                entity.Property(p => p.PaymentMethod).HasMaxLength(10);
                entity.Property(p => p.PaymentStatus).HasMaxLength(20);
            });

            modelBuilder.Entity<Review>(entity =>
            {
                entity.HasOne(r => r.Appointment)
                    .WithOne(a => a.Review)
                    .HasForeignKey<Review>(r => r.AppointmentId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasOne(r => r.Client)
                    .WithMany(c => c.Reviews)
                    .HasForeignKey(r => r.ClientId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasOne(r => r.Specialist)
                    .WithMany(s => s.Reviews)
                    .HasForeignKey(r => r.SpecialistId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasIndex(r => r.AppointmentId).IsUnique();
                entity.ToTable(tb => tb.HasCheckConstraint("CK_Review_Rating", "\"Rating\" >= 1 AND \"Rating\" <= 5"));
            });

            modelBuilder.Entity<SpecialistQualification>(entity =>
            {
                entity.HasOne(sq => sq.Specialist)
                    .WithMany(s => s.Qualifications)
                    .HasForeignKey(sq => sq.SpecialistId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasOne(sq => sq.VerifiedByAdmin)
                    .WithMany(a => a.VerifiedQualifications)
                    .HasForeignKey(sq => sq.VerifiedByAdminId)
                    .OnDelete(DeleteBehavior.SetNull);

                entity.Property(sq => sq.Profession).HasMaxLength(50);
            });

            modelBuilder.Entity<Admin>(entity =>
            {
                entity.ToTable("admins");

                entity.HasIndex(a => a.Email).IsUnique();
                entity.Property(a => a.Role).HasMaxLength(20);

                entity.Property(a => a.Role)
                    .IsRequired(false)
                    .HasDefaultValue("support");

                entity.Property(a => a.IsActive)
                    .IsRequired(false)
                    .HasDefaultValue(true);

                entity.Property(a => a.CreatedAt)
                    .IsRequired(false)
                    .HasDefaultValueSql("CURRENT_TIMESTAMP")
                    .HasColumnType("timestamp without time zone");

                entity.Property(a => a.LastLoginAt)
                    .HasColumnType("timestamp without time zone");
            });

            modelBuilder.Entity<VerificationLog>(entity =>
            {
                entity.HasOne(vl => vl.Specialist)
                    .WithMany(s => s.VerificationLogs)
                    .HasForeignKey(vl => vl.SpecialistId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasOne(vl => vl.Admin)
                    .WithMany(a => a.VerificationLogs)
                    .HasForeignKey(vl => vl.AdminId)
                    .OnDelete(DeleteBehavior.SetNull);

                entity.Property(vl => vl.Action).HasMaxLength(50);
            });

            modelBuilder.Entity<Message>(entity =>
            {
                entity.HasOne(m => m.Sender)
                    .WithMany(u => u.SentMessages)
                    .HasForeignKey(m => m.SenderId)
                    .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(m => m.Receiver)
                    .WithMany(u => u.ReceivedMessages)
                    .HasForeignKey(m => m.ReceiverId)
                    .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(m => m.Appointment)
                    .WithMany(a => a.Messages)
                    .HasForeignKey(m => m.AppointmentId)
                    .OnDelete(DeleteBehavior.SetNull);

                entity.HasIndex(m => m.CreatedAt);
            });

            modelBuilder.Entity<Notification>(entity =>
            {
                entity.HasOne(n => n.User)
                    .WithMany(u => u.Notifications)
                    .HasForeignKey(n => n.UserId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.Property(n => n.Type).HasMaxLength(50);
                entity.HasIndex(n => n.IsRead);
                entity.HasIndex(n => n.CreatedAt);
            });

            modelBuilder.Entity<VerificationCode>(entity =>
            {
                entity.HasOne(vc => vc.User)
                    .WithMany()
                    .HasForeignKey(vc => vc.UserId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.Property(vc => vc.Purpose).HasMaxLength(50);
                entity.HasIndex(vc => new { vc.Email, vc.Code, vc.IsUsed });
                entity.HasIndex(vc => vc.ExpiresAt);
            });
        }
    }
}