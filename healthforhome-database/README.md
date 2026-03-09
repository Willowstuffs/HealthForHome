# Dokumentacja Schematu Bazy Danych - HealthForHome

### Autor: Justyna <3

## Przegląd projektu
Kompletny (prawie) schemat bazy danych PostgreSQL dla platformy HealthForHome.

## Struktura bazy danych

#### Główne tabele (22 tabele)
* <code>users</code> - główna tabela użytkowników systemu
* <code>clients</code> - pacjenci korzystający z usług
* <code>specialists</code> - pielęgniarki i fizjoterapeuci
* <code>service_types</code> - katalog dostępnych usług medycznych
* <code>specialist_services</code> - usługi oferowane przez konkretnych specjalistów
* <code>service_areas</code> - obszary działania specjalistów
* <code>specialist_availability</code> - kalendarz dostępności
* <code>booked_slots</code> - zablokowane terminy
* <code>appointments</code> - rezerwacje wizyt
* <code>payments</code> - system płatności gotówkowych
* <code>reviews</code> - system ocen i recenzji
* <code>specialist_qualifications</code> - weryfikacja kwalifikacji
* <code>admins</code> - panel administracyjny
* <code>verification_logs</code> - logi weryfikacji specjalistów
* <code>messages</code> - wiadomości na chacie między pacjentem a specjalistą
* <code>notifications</code> - powiadomienia o wizytach/wiadomościach
* <code>verification_codes</code> - 6-cyfrowe kody weryfikacyjne do zakładania konta
* <code>address_geocache</code> - cache geokodowania adresów
* <code>appointments_specialists</code> - relacja wiele-do-wielu między wizytami a specjalistami
* <code>device_tokens</code> - przechowywanie tokenów FCM (Firebase Cloud Messaging) dla systemu powiadomień
* <code>service_requests</code> - przechowywanie ofert zgłoszeń wysyłanych przez klientów
* <code>__EFMigrationsHistory</code> - tabelka z migracjami

## Diagram relacji
* diagrams/schemat.png
* diagrams/schemat.svg
na diagramach brakuje jeszcze najnowszej tabelki (device_tokens)

## Jak uruchomić bazę danych
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
WHERE table_schema = 'public';  -- powinno zwrócić 20
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
### System weryfikacji specjalistów
* Sprawdzanie kwalifikacji (KIF dla fizjoterapeutów)
* Weryfikacja dokumentów (dyplomy, licencje)
* Panel administracyjny do zatwierdzania
* Logi wszystkich operacji weryfikacyjnych

### Kalendarz i rezerwacje
* Indywidualna dostępność każdego specjalisty
* System blokowania terminów
* Statusy wizyt (pending, confirmed, completed, cancelled)
* Notatki dla klientów i specjalistów

### Płatności
* System gotówkowy (innego nie obsługujemy)
* Proste potwierdzenia płatności

### System ocen
* Możliwość recenzji po każdej wizycie
* Średnia ocena specjalisty
* Weryfikacja czy recenzja pochodzi od realnej wizyty

### Komunikacja
* Możliwość wymiany wiadomości mięcy pacjentami a specjalistami
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

