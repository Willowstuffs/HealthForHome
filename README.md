# HealthForHome
Repozytorium na projekt z przedmiotu Programowanie Zespołowe 2025/2026

Luźne notatki z szerszymi opisami zmian:

COMMIT 1:

Ogarnięto wstępnie SpecialistDto, z przygotowanego wczesniej przez Justynę template'u.

Dodano:
ISpecialistService.cs z metodami potrzebnymi do pobrania i aktualizacji profilu

SpecialistService.cs dziedziczący z ISpecialistService z pobraniem profilu

Zarejestrowano w Program.cs

Dodanie komentarzy XMLowych w ApiResponse. Również w swoim kodzie używam komentarzy XML by pomagać w wyjaśnieniu kodu, oraz by pokazywało te objaśnienia przy używaniu tych funkcji poza kodem macierzystym.

Po stworzeniu "profilu" przeszedłem do rejestracji, dla specjalisty, która utworzy zarówno użytkownika jak i specjaliste.

Wypchnięto na backend nadpisując wszystko

COMMIT 2:

Stworzono SpecialistRegisterDto.cs, todo: ogarnąć fragmenty 

Zmodyfikowano AuthService.cs. Z jakiegoś powodu było tam using H4H_API.Dtos.Auth jak i H4H_API.DTOs.Auth. Ten drugi jest prawidłowy. Był mess że jeszcze w dwóch miejscach było Dtos z małej. Jest też ten problem w innych plikach.

Dodano mapowanie z modelu Specialist na SpecialistDto w MappingProfile.cs

Stworzono InquiryFilterDto.cs z filtrami oraz InquiryListItemDto.cs zgodnie z tym co chciała Kasia. Zostały dodane do SpecialistService.

Zmiana SpecialistService.cs by uwzględnić zapytania i zmianę numeru PWZ (LicenseNumber)

Dodano oba endpointy do kontrolera, usunięto stare try-catche które były niepotrzebne.

Wypchnięto na Wiktor, nowy branch by utrzymać konsensus nazw.

COMMIT 3: 10.01.2026

Stworzono SpecialistServiceManageDto.cs do dodawania/edycji usługi. W tej chwili nałożyłem range na DurationMinutes, od 5 minut do 12 godzin. Jeśli niepotrzebne lub potrzebna zmiana, mogę to zrobić.

Stworzono ServiceAreaManageDto.cs do ustalania zasięgu dojazdu specjalisty. Dodano dwa zakomentowane pola pod przyszłą geolokalizacje Latitude i Longitude. MaxDistanceKm ma zasięg 0-500.

ISpecialistService:
Dodano sygnatury nowych metod: pobieranie pwz, dodawanie/zmienianie/usuwanie uslug, zarzadzanie zasiegiem uslug

SpecialistService:
Dodano logike powyzszych metod operujac na tabelach powiazanych. W UpdateServiceAreaAsync zakładamy, że specjalista ma jeden ServiceArea.

Utworzono leksykon błędów w H4H.Core/Helpers/ErrorCodes.

Zmieniono ApiResponse by obsługiwało ErrorCodes. WAŻNE: ApiResponse, konkretnie ErrorResponse urósł do trzech argumentów. (zarówno ten z typem generycznym jak i bez)

Utworzono H4H.Api/Exceptions/AppException.cs z własnym wyjątkiem

Napisano na nowo ErrorHandlingMiddleware.cs uwzględniając leksykon

Dodano nowe metody do SpecialistController.

COMMIT 4: 14.01.2026
(I)SpecialistService(Controller): Dodano sygnature i logike metody od zatwierdzania statusu wizyty. Dodano do kontrolera.
Dodano E-mail i nr telefonu do SpecialistDto

Commit 5: 20.02.2026
Poprawiono elementy związane z geolokalizacją

Zmodyfikowano IAuthService.cs i AuthService.cs dodając logikę generowania, sprawdzania i wygasania 6-cyfrowego kodu OTP, oraz obsługę maili poprzez API SMTP GMaila pod adresem h4h.noreply@gmail.com

W kontrolerze Auth dodano endpointy odnośnie wysyłania i sprawdzania kodów OTP

Zmieniono domyślny status IsActive na false przy rejestracji (!!!)

Zarejestrowano EmailService w Program.cs

Utworzono stosowne Data Transfer Object do emaili: VerifyCodeDto i SendVerificationCodeDto

W AppSettings dodano pole z informacjami o e-mailu

Auth004 do 006 zaklepane do weryfikacji


