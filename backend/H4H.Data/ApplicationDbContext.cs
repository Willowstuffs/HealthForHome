using Microsoft.EntityFrameworkCore;
using H4H.Core.Models;
using NetTopologySuite;

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
        public DbSet<SpecialistAvailability> specialist_availability { get; set; }
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
        public DbSet<AddressGeocache> address_geocache { get; set; }
        public DbSet<AppointmentSpecialist> appointments_specialists { get; set; }
        public DbSet<DeviceToken> device_tokens { get; set; }

        // dla PostGIS i NetTopologySuite
        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
            if (!optionsBuilder.IsConfigured)
            {
                // upewnaieamy sie ze UseNetTopologySuite jest włączone
                optionsBuilder.UseNpgsql(
                    "ConnectionString", 
                    options => options.UseNetTopologySuite() // TO JEST NAJWAŻNIEJSZE (podobno)
                );
            }
        }
        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Włącz rozszerzenie PostGIS
            modelBuilder.HasPostgresExtension("postgis");


            // NOWA MIGRACJA IGNORUJEMY ISTNIEJĄCE TABELE
            modelBuilder.Entity<User>().ToTable("users", t => t.ExcludeFromMigrations());
            modelBuilder.Entity<Client>().ToTable("clients", t => t.ExcludeFromMigrations());
            modelBuilder.Entity<Specialist>().ToTable("specialists", t => t.ExcludeFromMigrations());
            modelBuilder.Entity<ServiceType>().ToTable("service_types", t => t.ExcludeFromMigrations());
            modelBuilder.Entity<SpecialistService>().ToTable("specialist_services", t => t.ExcludeFromMigrations());
            modelBuilder.Entity<ServiceArea>().ToTable("service_areas", t => t.ExcludeFromMigrations());
            modelBuilder.Entity<SpecialistAvailability>().ToTable("specialist_availability", t => t.ExcludeFromMigrations());
            modelBuilder.Entity<BookedSlot>().ToTable("booked_slots", t => t.ExcludeFromMigrations());
            modelBuilder.Entity<Appointment>().ToTable("appointments", t => t.ExcludeFromMigrations());
            modelBuilder.Entity<Payment>().ToTable("payments", t => t.ExcludeFromMigrations());
            modelBuilder.Entity<Review>().ToTable("reviews", t => t.ExcludeFromMigrations());
            modelBuilder.Entity<SpecialistQualification>().ToTable("specialist_qualifications", t => t.ExcludeFromMigrations());
            modelBuilder.Entity<Admin>().ToTable("admins", t => t.ExcludeFromMigrations());
            modelBuilder.Entity<VerificationLog>().ToTable("verification_logs", t => t.ExcludeFromMigrations());
            modelBuilder.Entity<Message>().ToTable("messages", t => t.ExcludeFromMigrations());
            modelBuilder.Entity<Notification>().ToTable("notifications", t => t.ExcludeFromMigrations());
            modelBuilder.Entity<VerificationCode>().ToTable("verification_codes", t => t.ExcludeFromMigrations());

            // SKONFIGURUJEMY TYLKO NOWE KOLUMNY
            modelBuilder.Entity<Client>(entity =>
            {
                entity.Property(e => e.AddressPoint)
                    .HasColumnType("geography(Point, 4326)");

                entity.Property(e => e.AddressGeocodedAt)
                    .HasColumnType("timestamp without time zone");
            });

            modelBuilder.Entity<ServiceArea>(entity =>
            {
                entity.Property(e => e.Location)
                    .HasColumnType("geography(Point, 4326)");

                entity.Property(e => e.LocationUpdatedAt)
                    .HasColumnType("timestamp without time zone");
            });




            // Konfiguracja tabel
            modelBuilder.Entity<User>(entity =>
            {
                entity.HasIndex(e => e.Email).IsUnique();
                entity.Property(e => e.UserType).HasMaxLength(20);
            });

            // Relacja jeden-do-jednego User <=> Client z kaskadowym usuwaniem
            modelBuilder.Entity<Client>(entity =>
            {
                entity.HasOne(c => c.User)
                    .WithOne(u => u.Client)
                    .HasForeignKey<Client>(c => c.UserId)
                    .OnDelete(DeleteBehavior.Cascade); // Usunięcie użytkownika usuwa klienta

                // KONFIGURACJA POSTGIS DLA Client:
                entity.Property(e => e.AddressPoint)
                    .HasColumnType("geography(Point, 4326)");
            });

            // Relacja jeden-do-jednego User <=> Specialist z kaskadowym usuwaniem
            modelBuilder.Entity<Specialist>(entity =>
            {
                entity.HasOne(s => s.User)
                    .WithOne(u => u.Specialist)
                    .HasForeignKey<Specialist>(s => s.UserId)
                    .OnDelete(DeleteBehavior.Cascade); // Usunięcie użytkownika usuwa specjalistę

                entity.Property(s => s.VerificationStatus)
                    .HasMaxLength(20); // Status weryfikacji specjalisty
            });

            // Konfiguracja typów usług
            modelBuilder.Entity<ServiceType>(entity =>
            {
                entity.Property(s => s.Category).HasMaxLength(50); // Kategoria usługi
                entity.HasIndex(s => s.Name); // Indeks na nazwie usługi
            });

            // Relacja wiele-do-wielu przez tabelę pośrednią SpecialistService
            modelBuilder.Entity<SpecialistService>(entity =>
            {
                // Relacja ze Specjalista
                entity.HasOne(ss => ss.Specialist)
                    .WithMany(s => s.Services) // Jeden specjalista ma wiele usług
                    .HasForeignKey(ss => ss.SpecialistId)
                    .OnDelete(DeleteBehavior.Cascade); // Usunięcie specjalisty usuwa jego usługi

                // Relacja z ServiceType
                entity.HasOne(ss => ss.ServiceType)
                    .WithMany(st => st.SpecialistServices) // Jeden typ usługi może być oferowany przez wielu specjalistów
                    .HasForeignKey(ss => ss.ServiceTypeId)
                    .OnDelete(DeleteBehavior.Cascade); // Usunięcie typu usługi usuwa powiązania
            });

            // Obszary działania specjalistów
            modelBuilder.Entity<ServiceArea>(entity =>
            {
                entity.HasOne(sa => sa.Specialist)
                    .WithMany(s => s.ServiceAreas) // Jeden specjalista może działać w wielu obszarach
                    .HasForeignKey(sa => sa.SpecialistId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasIndex(sa => sa.City); // Indeks na mieście dla szybkiego wyszukiwania

                // KONFIGURACJA POSTGIS DLA ServiceArea:
                entity.Property(e => e.Location)
                    .HasColumnType("geography(Point, 4326)");
            });

            // Dostępność specjalistów (kalendarz)
            modelBuilder.Entity<SpecialistAvailability>(entity =>
            {
                entity.HasOne(sa => sa.Specialist)
                    .WithMany(s => s.Availabilities) // Jeden specjalista ma wiele slotów dostępności
                    .HasForeignKey(sa => sa.SpecialistId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasIndex(sa => sa.Date); // Indeks na dacie dla optymalizacji zapytań
            });

            // Zarezerwowane sloty czasowe
            modelBuilder.Entity<BookedSlot>(entity =>
            {
                entity.HasOne(bs => bs.Specialist)
                    .WithMany(s => s.BookedSlots) // Jeden specjalista ma wiele zarezerwowanych slotów
                    .HasForeignKey(bs => bs.SpecialistId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasIndex(bs => bs.StartDateTime); // Indeks na początku slotu
                entity.HasIndex(bs => bs.EndDateTime); // Indeks na końcu slotu
            });

            // Wizyty - centralna encja systemu
            modelBuilder.Entity<Appointment>(entity =>
            {

                entity.ToTable("appointments"); // Upewnienie się co do nazwy tabeli

                // 1. RELACJE
                // Relacja z Klientem (opcjonalna dla gości)
                entity.HasOne(a => a.Client)
                    .WithMany(c => c.Appointments)
                    .HasForeignKey(a => a.ClientId)
                    .IsRequired(false) // KLUCZOWE dla ogłoszeń "open"
                    .OnDelete(DeleteBehavior.SetNull);

                // Relacja z Specjalistą (opcjonalna dla ogłoszeń "open")
                entity.HasOne(a => a.Specialist)
                    .WithMany(s => s.Appointments)
                    .HasForeignKey(a => a.SpecialistId)
                    .IsRequired(false) // KLUCZOWE dla ogłoszeń "open"
                    .OnDelete(DeleteBehavior.SetNull);

                // Relacja z typem usługi (kategoria)
                entity.HasOne(a => a.ServiceType)
                      .WithMany()
                      .HasForeignKey(a => a.ServiceTypeId)
                      .IsRequired(false);

                // Relacja z konkretną usługa specjalisty
                entity.HasOne(a => a.SpecialistService)
                    .WithMany(ss => ss.Appointments)
                    .HasForeignKey(a => a.SpecialistServiceId)
                    .OnDelete(DeleteBehavior.SetNull);

                // 2. NOWE KOLUMNY PRZESTRZENNE I MAPOWANIE
                entity.Property(a => a.Location)
                    .HasColumnName("location"); // Wymuszenie nazwy małą literą

                entity.Property(a => a.ServiceTypeId)
                    .HasColumnName("service_type_id");

                // 3. POZOSTAŁE WŁAŚCIWOŚCI
                entity.Property(a => a.AppointmentStatus)
                    .HasMaxLength(20);

                // 4. INDEKSY
                entity.HasIndex(a => a.ScheduledStart);
                entity.HasIndex(a => a.AppointmentStatus);
            });
            // Płatności
            modelBuilder.Entity<Payment>(entity =>
            {
                // Relacja jeden-do-jednego z Wizytą
                entity.HasOne(p => p.Appointment)
                    .WithOne(a => a.Payment) // Jedna wizyta ma jedną płatność
                    .HasForeignKey<Payment>(p => p.AppointmentId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasIndex(p => p.AppointmentId).IsUnique();
                entity.Property(p => p.PaymentMethod).HasMaxLength(10);
                entity.Property(p => p.PaymentStatus).HasMaxLength(20);
            });

            // Recenzje
            modelBuilder.Entity<Review>(entity =>
            {
                // Relacja z Wizytą
                entity.HasOne(r => r.Appointment)
                    .WithOne(a => a.Review)
                    .HasForeignKey<Review>(r => r.AppointmentId)
                    .OnDelete(DeleteBehavior.Cascade);

                // Relacja z Klientem
                entity.HasOne(r => r.Client)
                    .WithMany(c => c.Reviews)
                    .HasForeignKey(r => r.ClientId)
                    .OnDelete(DeleteBehavior.Cascade);

                // Relacja z Specialista
                entity.HasOne(r => r.Specialist)
                    .WithMany(s => s.Reviews)
                    .HasForeignKey(r => r.SpecialistId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasIndex(r => r.AppointmentId).IsUnique();
                // Constraint w bazie: ocena musi być między 1 a 5
                entity.ToTable(tb => tb.HasCheckConstraint("CK_Review_Rating", "\"Rating\" >= 1 AND \"Rating\" <= 5"));
            });

            // Kwalifikacje specjalistów
            modelBuilder.Entity<SpecialistQualification>(entity =>
            {
                entity.HasOne(sq => sq.Specialist)
                    .WithMany(s => s.Qualifications) // Jeden specjalista ma wiele kwalifikacji
                    .HasForeignKey(sq => sq.SpecialistId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasOne(sq => sq.VerifiedByAdmin)
                    .WithMany(a => a.VerifiedQualifications) // Jeden admin może zweryfikować wiele kwalifikacji
                    .HasForeignKey(sq => sq.VerifiedByAdminId)
                    .OnDelete(DeleteBehavior.SetNull); // Usunięcie admina ustawia NULL

                entity.Property(sq => sq.Profession).HasMaxLength(50); // Nazwa zawodu
            });

            // Administratorzy systemu
            modelBuilder.Entity<Admin>(entity =>
            {
                entity.ToTable("admins");

                entity.HasIndex(a => a.Email).IsUnique(); // Unikalny email admina
                entity.Property(a => a.Role).HasMaxLength(20); // Rola admina (super_admin, support)

                // Ustawienia domyślne dla pól
                entity.Property(a => a.Role)
                    .IsRequired(false)
                    .HasDefaultValue("support"); // Domyślnie rola "support"

                entity.Property(a => a.IsActive)
                    .IsRequired(false)
                    .HasDefaultValue(true); // Domyślnie aktywny

                // Domyślna wartość timestamp z SQL
                entity.Property(a => a.CreatedAt)
                    .IsRequired(false)
                    .HasDefaultValueSql("CURRENT_TIMESTAMP")
                    .HasColumnType("timestamp without time zone");

                entity.Property(a => a.LastLoginAt)
                    .HasColumnType("timestamp without time zone");
            });

            // Logi weryfikacji specjalistów
            modelBuilder.Entity<VerificationLog>(entity =>
            {
                entity.HasOne(vl => vl.Specialist)
                    .WithMany(s => s.VerificationLogs) // Jeden specjalista ma wiele logów weryfikacji
                    .HasForeignKey(vl => vl.SpecialistId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasOne(vl => vl.Admin)
                    .WithMany(a => a.VerificationLogs) // Jeden admin ma wiele logów weryfikacji
                    .HasForeignKey(vl => vl.AdminId)
                    .OnDelete(DeleteBehavior.SetNull); // Usunięcie admina ustawia NULL

                entity.Property(vl => vl.Action).HasMaxLength(50); // Akcja weryfikacji
            });

            // Wiadomości między użytkownikami
            modelBuilder.Entity<Message>(entity =>
            {
                // Nadawca wiadomości
                entity.HasOne(m => m.Sender)
                    .WithMany(u => u.SentMessages) // Jeden użytkownik wysłał wiele wiadomości
                    .HasForeignKey(m => m.SenderId)
                    .OnDelete(DeleteBehavior.Restrict); // Restrict - nie można usunąć użytkownika z wysłanymi wiadomościami

                // Odbiorca wiadomości
                entity.HasOne(m => m.Receiver)
                    .WithMany(u => u.ReceivedMessages) // Jeden użytkownik otrzymał wiele wiadomości
                    .HasForeignKey(m => m.ReceiverId)
                    .OnDelete(DeleteBehavior.Restrict);

                // Relacja z Wizytą (wiadomości mogą dotyczyć konkretnej wizyty)
                entity.HasOne(m => m.Appointment)
                    .WithMany(a => a.Messages) // Jedna wizyta może mieć wiele wiadomości
                    .HasForeignKey(m => m.AppointmentId)
                    .OnDelete(DeleteBehavior.SetNull);

                entity.HasIndex(m => m.CreatedAt);
            });
            // Powiadomienia
            modelBuilder.Entity<Notification>(entity =>
            {
                entity.HasOne(n => n.User)
                    .WithMany(u => u.Notifications) // Jeden użytkownik ma wiele powiadomień
                    .HasForeignKey(n => n.UserId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.Property(n => n.Type).HasMaxLength(50); // Typ powiadomienia
                entity.HasIndex(n => n.IsRead);
                entity.HasIndex(n => n.CreatedAt);
            });

            // Kody weryfikacyjne 
            modelBuilder.Entity<VerificationCode>(entity =>
            {
                entity.HasOne(vc => vc.User)
                    .WithMany() // Relacja z użytkownikiem
                    .HasForeignKey(vc => vc.UserId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.Property(vc => vc.Purpose).HasMaxLength(50); // Cel kodu (email_verification)
                entity.HasIndex(vc => new { vc.Email, vc.Code, vc.IsUsed });
                entity.HasIndex(vc => vc.ExpiresAt);
            });

            // konfiguracja dla AddressGeocache 
            modelBuilder.Entity<AddressGeocache>(entity =>
            {
                entity.ToTable("address_geocache");

                entity.HasIndex(e => e.AddressHash).IsUnique();

                entity.Property(e => e.Latitude)
                    .HasColumnType("decimal(10, 8)");

                entity.Property(e => e.Longitude)
                    .HasColumnType("decimal(11, 8)");

                entity.Property(e => e.CreatedAt)
                    .HasColumnType("timestamp without time zone");
            });

            // Konfiguracja tabeli łączącej Appointment i Specialist (wiele-do-wielu)
            modelBuilder.Entity<AppointmentSpecialist>(entity =>
            {
                // Relacja z Appointment
                entity.HasOne(a => a.Appointment)
                    .WithMany(a => a.AppointmentSpecialists)
                    .HasForeignKey(a => a.AppointmentId)
                    .OnDelete(DeleteBehavior.Cascade);

                // Relacja ze Specialist
                entity.HasOne(a => a.Specialist)
                    .WithMany()
                    .HasForeignKey(a => a.SpecialistId)
                    .OnDelete(DeleteBehavior.Cascade);

                // Unikalna para appointment + specialist
                entity.HasIndex(a => new { a.AppointmentId, a.SpecialistId }).IsUnique();
            });

            // Konfiguracja tabeli DeviceToken dla powiadomień push
            modelBuilder.Entity<DeviceToken>(entity =>
            {
                entity.ToTable("device_tokens");

                entity.HasKey(e => e.Id);

                // Relacja z użytkownikiem
                entity.HasOne(e => e.User)
                      .WithMany(u => u.DeviceTokens)
                      .HasForeignKey(e => e.UserId)
                      .OnDelete(DeleteBehavior.Cascade);

                entity.HasIndex(e => e.UserId).HasDatabaseName("idx_device_tokens_user");
                entity.HasIndex(e => e.FcmToken).HasDatabaseName("idx_device_tokens_fcm_token");

                entity.HasIndex(e => new { e.UserId, e.FcmToken }).IsUnique();
            });


            // usuniecie service_requests

        }
    }
}