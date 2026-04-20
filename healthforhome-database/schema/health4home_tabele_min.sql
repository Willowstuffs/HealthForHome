-- TWORZENIE TABEL
-- uzytkownicy
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    user_type VARCHAR(20) NOT NULL CHECK (user_type IN ('client', 'specialist')),
    phone_number VARCHAR(20),
    avatar_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP
);

-- klienci
CREATE TABLE clients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE,
    address TEXT,
    emergency_contact TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- specjalisci
CREATE TABLE specialists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    professional_title VARCHAR(200),
    bio TEXT,
    hourly_rate DECIMAL(10,2),
    is_verified BOOLEAN DEFAULT false,
    verification_status VARCHAR(20) DEFAULT 'pending' 
        CHECK (verification_status IN ('pending', 'approved', 'rejected', 'needs_revision')),
    average_rating DECIMAL(3,2) DEFAULT 0.00,
    total_reviews INTEGER DEFAULT 0,
    verified_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- katalog uslug
CREATE TABLE service_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL CHECK (category IN ('nursing', 'physiotherapy')),
    default_duration INTEGER,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- uslugi oferowane przez specjalstow
CREATE TABLE specialist_services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    specialist_id UUID REFERENCES specialists(id) ON DELETE CASCADE,
    service_type_id UUID REFERENCES service_types(id) ON DELETE CASCADE,
    duration_minutes INTEGER NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- obszary dzialania specjalistow
CREATE TABLE service_areas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    specialist_id UUID REFERENCES specialists(id) ON DELETE CASCADE,
    city VARCHAR(100) NOT NULL,
    postal_code VARCHAR(10),
    max_distance_km INTEGER DEFAULT 20,
    is_primary BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- dostepnosc specjalistow
CREATE TABLE specialist_availability (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    specialist_id UUID REFERENCES specialists(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_available BOOLEAN DEFAULT true,
    recurrence_pattern VARCHAR(20) CHECK (recurrence_pattern IN ('once', 'daily', 'weekly', 'monthly')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- zablokowane terminy
CREATE TABLE booked_slots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    specialist_id UUID REFERENCES specialists(id) ON DELETE CASCADE,
    start_datetime TIMESTAMP NOT NULL,
    end_datetime TIMESTAMP NOT NULL,
    is_blocked BOOLEAN DEFAULT true,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

--glowna tabela rezwerwacji wizyt
CREATE TABLE appointments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    specialist_id UUID REFERENCES specialists(id) ON DELETE CASCADE,
    specialist_service_id UUID REFERENCES specialist_services(id),
    appointment_status VARCHAR(20) DEFAULT 'pending'
        CHECK (appointment_status IN ('pending', 'confirmed', 'in_progress', 'completed', 'cancelled', 'no_show')),
    scheduled_start TIMESTAMP NOT NULL,
    scheduled_end TIMESTAMP NOT NULL,
    total_price DECIMAL(10,2),
    client_address TEXT,
    client_notes TEXT,
    specialist_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    cancelled_at TIMESTAMP
);

-- paltnosci (robimy bez prowizji i tylko gotowka zeby latwiej)
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    appointment_id UUID UNIQUE REFERENCES appointments(id) ON DELETE CASCADE,
    payment_method VARCHAR(10) DEFAULT 'cash' CHECK (payment_method IN ('cash')),
    payment_status VARCHAR(20) DEFAULT 'pending'
        CHECK (payment_status IN ('pending', 'completed', 'cancelled', 'no_show')),
    cash_received BOOLEAN DEFAULT false,
    received_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- recenzje
CREATE TABLE reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    appointment_id UUID REFERENCES appointments(id) ON DELETE CASCADE,
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    specialist_id UUID REFERENCES specialists(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    is_verified BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- kwalifikacje specjalistow - weryfikacja
CREATE TABLE specialist_qualifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    specialist_id UUID REFERENCES specialists(id) ON DELETE CASCADE,
    profession VARCHAR(50) NOT NULL CHECK (profession IN ('nurse', 'physiotherapist')),
    license_number VARCHAR(100) NOT NULL,
    license_photo_url TEXT,
    id_card_photo_url TEXT,
    verification_notes TEXT,
    verified_by_admin_id UUID, -- dodamy pozniej referencje do admins
    verified_at TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- administratorzy - admin panel
CREATE TABLE admins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) DEFAULT 'support' 
        CHECK (role IN ('super_admin', 'support', 'verifier')),
    full_name VARCHAR(200),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP
);

-- logi weryfikacji - audit trail
CREATE TABLE verification_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    specialist_id UUID REFERENCES specialists(id) ON DELETE CASCADE,
    admin_id UUID REFERENCES admins(id) ON DELETE SET NULL,
    action VARCHAR(50) NOT NULL 
        CHECK (action IN ('submitted', 'approved', 'rejected', 'requested_changes')),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela wiadomości (chat)
CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    appointment_id UUID REFERENCES appointments(id) ON DELETE SET NULL,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela powiadomień
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL CHECK (type IN ('message', 'appointment', 'reminder', 'system')),
    title VARCHAR(200) NOT NULL,
    content TEXT,
    is_read BOOLEAN DEFAULT false,
    related_id UUID,  -- appointment_id, message_id, etc.
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela kodów weryfikacyjnych (6-cyfrowy kod z emaila)
CREATE TABLE IF NOT EXISTS verification_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    code VARCHAR(6) NOT NULL,
    purpose VARCHAR(50) NOT NULL CHECK (purpose IN ('registration', 'password_reset')),
    is_used BOOLEAN DEFAULT false,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ZMIANY W TABELACH

--po dodaniu administratorow dodac klucz obcy w kwalifikacjach
ALTER TABLE specialist_qualifications 
ADD CONSTRAINT fk_verified_by_admin 
FOREIGN KEY (verified_by_admin_id) 
REFERENCES admins(id) 
ON DELETE SET NULL;

-- dodanie UNIQUE constraint w reviews (jedna recenzja na wizyte)
ALTER TABLE reviews 
ADD CONSTRAINT unique_appointment_review UNIQUE (appointment_id);

-- DODANIE POSTGISA:

CREATE EXTENSION IF NOT EXISTS postgis;
-- SELECT PostGIS_Version();

-- DODAJEMY KOLUMNY DO service_areas
ALTER TABLE service_areas
ADD COLUMN IF NOT EXISTS location geography(Point, 4326),
ADD COLUMN IF NOT EXISTS location_updated_at TIMESTAMP;

-- DODAJEMY KOLUMNY DO clients
ALTER TABLE clients
ADD COLUMN IF NOT EXISTS address_point geography(Point, 4326),
ADD COLUMN IF NOT EXISTS address_geocoded_at TIMESTAMP;

-- TABELA CACHE'U GEOKODOWANIA 
CREATE TABLE IF NOT EXISTS address_geocache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    address_hash VARCHAR(64) UNIQUE NOT NULL,
    address TEXT NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    formatted_address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_service_areas_location ON service_areas USING GIST(location);
CREATE INDEX idx_clients_address_point ON clients USING GIST(address_point);
CREATE INDEX idx_address_geocache_hash ON address_geocache(address_hash);


-- POPRAWKA W WIZYTACH:

-- Tabelka od Kasi
CREATE TABLE appointments_specialists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    appointment_id UUID NOT NULL,
    specialist_id UUID NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_appointments_specialists_appointment
        FOREIGN KEY (appointment_id) REFERENCES appointments(id) ON DELETE CASCADE,

    CONSTRAINT fk_appointments_specialists_specialist
        FOREIGN KEY (specialist_id) REFERENCES specialists(id) ON DELETE CASCADE,

    CONSTRAINT uq_appointments_specialists_unique
        UNIQUE (appointment_id, specialist_id)
);

-- Kto ostatecznie wziął to zlecenie (PIERWSZY który zaakceptował)
ALTER TABLE appointments ADD COLUMN IF NOT EXISTS selected_specialist_id UUID REFERENCES specialists(id);

-- Aktualizacja 08.02.26

-- 1. Dodanie tabeli dla tokenów urządzeń (FCM) - Kasia
CREATE TABLE device_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    last_used_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, fcm_token) 
);

-- 2. Indeksy dla wydajności wyszukiwania
CREATE INDEX idx_device_tokens_user ON device_tokens(user_id);
CREATE INDEX idx_device_tokens_fcm_token ON device_tokens(fcm_token);


-- AKTUALIZACJA JEDNAK NARA SERVICE REQUESR

-- 1. Dodanie kolumn do tabeli appointments
ALTER TABLE appointments 
ADD COLUMN IF NOT EXISTS location geography(Point, 4326),
ADD COLUMN IF NOT EXISTS service_type_id uuid;

-- 2. Utworzenie relacji (Klucza obcego) z tabelą service_types
ALTER TABLE appointments
ADD CONSTRAINT "FK_appointments_service_types_service_type_id" 
FOREIGN KEY (service_type_id) 
REFERENCES service_types (id) 
ON DELETE SET NULL;

-- 3. Utworzenie indeksu dla wydajności wyszukiwania po kategorii
CREATE INDEX "IX_appointments_service_type_id" 
ON appointments (service_type_id);

-- 4. Usunięcie nieużywanej już tabeli service_requests
DROP TABLE IF EXISTS service_requests;


-- 1. Usuwamy stare ograniczenie
ALTER TABLE appointments 
DROP CONSTRAINT appointments_appointment_status_check;

-- 2. Dodajemy nowe ograniczenie z uwzględnieniem statusu 'open'
ALTER TABLE appointments 
ADD CONSTRAINT appointments_appointment_status_check 
CHECK (appointment_status IN ('open', 'confirmed', 'cancelled', 'completed', 'pending'));


-- aktualizacja 01.03.2026 funkcje do czyszczenia kodow i martwych kont
-- przez prace lokalną kazdy musi sobie odpalic raz u siebie w bazie te funkcje zeby dzialaly

-- 1. Funkcja do usuwania wygasłych kodów OTP
CREATE OR REPLACE FUNCTION delete_expired_codes()
RETURNS integer AS $$
DECLARE
    deleted_count integer;
BEGIN
    DELETE FROM verification_codes 
    WHERE expires_at < CURRENT_TIMESTAMP;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- 2. Funkcja do czyszczenia martwych kont (nieaktywne > 30 dni)
CREATE OR REPLACE FUNCTION cleanup_inactive_users()
RETURNS integer AS $$
DECLARE
    deleted_count integer;
BEGIN
    DELETE FROM users 
    WHERE is_active = false 
      AND created_at < (CURRENT_TIMESTAMP - INTERVAL '30 days');
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;



-- AKTUALIZACJA 09.03.2026 - Dodanie ceny i obsługi wielu usług do appointments_specialists

-- 1. Dodanie kolumn do appointments_specialists
ALTER TABLE appointments_specialists 
ADD COLUMN IF NOT EXISTS price DECIMAL(10,2),           -- cena za wszystkie usługi
ADD COLUMN IF NOT EXISTS service_type_ids UUID[] DEFAULT '{}'; -- tablica ID usług

-- 2. Indeks dla GIST (szybsze wyszukiwanie w tablicy)
CREATE INDEX IF NOT EXISTS idx_appointments_specialists_service_ids 
ON appointments_specialists USING GIN (service_type_ids);

-- Aktualizacja 14.03.2026 - Podzial client_notes na osobne pola dla czytelnosci

-- 1. Dodanie nowych kolumn do tabeli appointments
ALTER TABLE appointments ADD COLUMN IF NOT EXISTS contact_name VARCHAR(200);
ALTER TABLE appointments ADD COLUMN IF NOT EXISTS contact_phone_number VARCHAR(20);
ALTER TABLE appointments ADD COLUMN IF NOT EXISTS contact_email VARCHAR(150);



-- Aktualizacja 10.04.2026 - Dostosowanie bazy do potrzeb panelu administratora

-- 1. users
-- Aktualizacja typów użytkowników (dodanie admina)
-- Najpierw usuwamy stary warunek, potem dodajemy nowy, który pozwala na 'admin'
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_user_type_check;
ALTER TABLE users ADD CONSTRAINT users_user_type_check 
    CHECK (user_type IN ('client', 'specialist', 'admin'));

-- 2. appointments - pola contact_name, contact_phone_number, contact_email juz byly dodawane

-- 3. specialists
-- Aktualizacja tabeli specialists (obsługa zawieszeń kont)
ALTER TABLE specialists 
    ADD COLUMN IF NOT EXISTS is_suspended BOOLEAN DEFAULT false,
    ADD COLUMN IF NOT EXISTS suspended_at TIMESTAMP;

-- 4. specialist_qualifications
-- Aktualizacja kwalifikacji (termin ważności licencji)
ALTER TABLE specialist_qualifications 
    ADD COLUMN IF NOT EXISTS license_valid_until DATE;

-- 5. appointments -> appointment_status
-- Usuwamy stare ograniczenie
ALTER TABLE appointments DROP CONSTRAINT IF EXISTS appointments_appointment_status_check;
-- Nowa lista z wszystkimi statusami żeby juz nie zmieniac
ALTER TABLE appointments ADD CONSTRAINT appointments_appointment_status_check 
    CHECK (appointment_status IN (
        'open',          
        'pending',      
        'confirmed',     
        'in_progress',   -- dodane
        'completed',     
        'cancelled',     
        'no_show'        -- dodane
    ));


-- Aktualizacja 17.04.2026 - uzupelnienie wizyt o propozycje daty z godzinami

-- 1. Dodajemy proponowaną datę do ofert
ALTER TABLE appointments_specialists 
ADD COLUMN IF NOT EXISTS proposed_date TIMESTAMP;

-- 2. Dodajemy pole na ostatecznie wybraną datę do wizyty
ALTER TABLE appointments 
ADD COLUMN IF NOT EXISTS final_date TIMESTAMP;

-- 3. Dodajemy tabele do tokenow 
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    token TEXT NOT NULL,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    revoked_at TIMESTAMP
);


-- Aktualizacja 18.04.2026 - Poprawki w tabeli appointments umozliwiajace prawidlowe dodawanie uslug do oferty

-- Usuwamy stary klucz obcy
ALTER TABLE appointments DROP CONSTRAINT IF EXISTS "FK_appointments_specialist_services_specialist_service_id";

-- Zmiana nazwy specialist_service_id -> specialist_service_ids
DO $$ 
BEGIN 
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='appointments' AND column_name='specialist_service_id') THEN
        ALTER TABLE appointments RENAME COLUMN specialist_service_id TO specialist_service_ids;
    END IF;
END $$;

-- Zmiana typu na tablicę UUID[]
ALTER TABLE appointments 
    ALTER COLUMN specialist_service_ids TYPE UUID[] 
    USING CASE 
        WHEN specialist_service_ids IS NULL THEN '{}'::UUID[] 
        ELSE ARRAY[specialist_service_ids] 
    END;

ALTER TABLE appointments ALTER COLUMN specialist_service_ids SET DEFAULT '{}';
ALTER TABLE appointments DROP COLUMN IF EXISTS "SpecialistServiceId";