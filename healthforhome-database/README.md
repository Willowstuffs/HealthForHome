# Dokumentacja Schematu Bazy Danych - HealthForHome

### Autor: Justyna <3

## Przegląd projektu
Kompletny (prawie) schemat bazy danych PostgreSQL dla platformy HealthForHome.
System wspiera obsługę wizyt domowych pielęgniarek i fizjoterapeutów, w tym zaawansowany system ofertowania, geolokalizację PostGIS oraz bezpieczną autoryzację JWT.

## Struktura bazy danych

#### Główne tabele (21 tabel merytorycznych)
* **Autoryzacja i powiadomienia:**
    * `users` - główna tabela użytkowników systemu.
    * `refresh_tokens` - przechowywanie tokenów sesji (bezpieczne odświeżanie Access Tokenów).
    * `device_tokens` - tokeny FCM dla powiadomień push (iOS/Android).
    * `verification_codes` - 6-cyfrowe kody weryfikacyjne (OTP) do rejestracji i resetu haseł.
* **Profile:**
    * `clients` - dane pacjentów wraz z adresem domowym.
    * `specialists` - dane medyków (biografia, stawki, status weryfikacji).
    * `specialist_qualifications` - certyfikaty i weryfikacja uprawnień zawodowych.
* **Usługi i Dostępność:**
    * `service_types` - ogólny katalog usług medycznych.
    * `specialist_services` - indywidualne cenniki i czasy trwania usług u specjalistów.
    * `service_areas` - obszary dojazdu (geografia PostGIS).
    * `specialist_availability` - harmonogram tygodniowy specjalisty.
    * `booked_slots` - konkretne terminy zajęte w kalendarzu.
* **Wizyty i Marketplace:**
    * `appointments` - centralna tabela wizyt (obsługuje `final_date` po negocjacjach).
    * `appointments_specialists` - system ofertowania; pozwala specjalistom licytować wizyty 'open' i proponować własne terminy (`proposed_date`).
* **Komunikacja i Oceny:**
    * `messages` - historia chatu między użytkownikami.
    * `notifications` - system powiadomień wewnątrz aplikacji.
    * `reviews` - system ocen i recenzji po wizytach.
* **Administracja i Narzędzia:**
    * `admins` - konta z uprawnieniami do panelu zarządzania.
    * `verification_logs` - pełna historia akcji administracyjnych (weryfikacja specjalistów).
    * `payments` - rejestr płatności gotówkowych.
    * `address_geocache` - cache geokodowania dla optymalizacji zapytań PostGIS.

## Diagram relacji
* diagrams/schemat.png
* diagrams/schemat.svg

## Jak uruchomić bazę danych lokalnie
### Wymagania:
* PostgreSQL 12+ (zalecane PostgreSQL 17)
* Rozszerzenie uuid-ossp (zwykle domyślnie zainstalowane)
* PostGIS (do geolokalizacji)

### Krok po kroku:
<pre> <code>
# 1. Utwórz bazę danych
CREATE DATABASE health4home;

# 2. Połącz się z bazą i wykonaj główny skrypt
psql -U postgres -d health4home -f schema/health4home_tabele.sql

# 3. Sprawdź czy wszystkie tabele zostały utworzone
SELECT COUNT(*) FROM information_schema.tables 
WHERE table_schema = 'public';  -- powinno zwrócić 21
</code> </pre>

### Używając pgAdmin:
* Połącz się z serwerem PostgreSQL
* Utwórz nową bazę danych o nazwie health4home
* Otwórz Query Tool i wklej zawartość health4home_tabele.sql
* Wykonaj skrypt (F5)

# Struktura plików
<pre> 
healthforhome-database/
├── README.md                        ← Ten plik
├── schema/
│   └── health4home_tabele.sql       ← Główny skrypt tworzący wszystkie tabele
└── diagrams/
    ├── schemat.png                  ← Diagram ER (PNG)
    └── schemat.svg                  ← Diagram ER (SVG - do edycji)
</pre> 

# Kluczowe funkcjonalności

### Autoryzacja i bezpieczeństwo (Nowość!)
* **JWT Refresh Tokens**: System rotacji tokenów umożliwiający długotrwałe sesje bez utraty bezpieczeństwa.
* **Weryfikacja OTP**: 6-cyfrowe kody weryfikacyjne wysyłane przy rejestracji i resetowaniu hasła.
* **Device Tokens**: Integracja z Firebase Cloud Messaging (FCM) dla powiadomień push na systemach Android.

### System weryfikacji specjalistów
* **Sprawdzanie kwalifikacji**: Obsługa numerów licencji i terminów ważności dokumentów
* **Weryfikacja dokumentów**: (dyplomy, licencje)
* **Panel administracyjny** do zatwierdzania
* **Logi** wszystkich operacji weryfikacyjnych

### Kalendarz i rezerwacje
* **Indywidualna dostępność** każdego specjalisty
* **System blokowania terminów**
* **Statusy wizyt** (open, pending, confirmed, in_progress, completed, cancelled, no_show)
* **Notatki** dla klientów i specjalistów

### Płatności i oceny
* **System gotówkowy**
* **Proste potwierdzenia płatności**
* **Recenzje 1:1**: System ocen powiązany bezpośrednio z unikalnym ID wizyty

### Komunikacja
* Możliwość wymiany wiadomości między pacjentami a specjalistami
* System powiadomień o nowych wiadomościach oraz nadchodzących wizytach

### Geolokalizacja (PostGIS)
* Przechowywanie współrzędnych geograficznych klientów i specjalistów
* Cache geokodowania adresów dla wydajności
* Obszary działania specjalistów z maksymalnym dystansem

# Szczegóły techniczne
### Typy danych:
* UUID jako klucze główne (bezpieczeństwo, skalowalność)
* CHECK constraints - walidacja na poziomie bazy
* TIMESTAMP z domyślną wartością CURRENT_TIMESTAMP
* CASCADE usuwanie powiązanych rekordów
* Typy geograficzne PostGIS (geography(Point, 4326))

### Relacje:
* Jeden użytkownik może być klientem LUB specjalistą
* Jeden specjalista może oferować wiele usług
* Jeden klient może mieć wiele wizyt
* Każda wizyta ma dokładnie jedną płatność i jedną recenzję
* Każda wizyta może mieć wielu potencjalnych specjalistów (appointments_specialists)
* Każda wizyta ma dokładnie jednego wybranego specjalistę (selected_specialist_id)
* Administratorzy mogą weryfikować kwalifikacje specjalistów

# Możliwe rozszerzenia
## Krótkoterminowe:
* ?
## Długoterminowe
* ?

# Znane ograniczenia
* ?

# Przykładowe zapytania:
(będą kiedyś)

