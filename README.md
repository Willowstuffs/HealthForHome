# HealthForHome
Repozytorium na projekt z przedmiotu Programowanie Zespołowe 2025/2026

Luźne notatki ze zmianami:
Commit 1:

Ogarnięto wstępnie SpecialistDto, z przygotowanego wczesniej przez Justynę template'u.

Dodano:
ISpecialistService.cs z metodami potrzebnymi do pobrania i aktualizacji profilu

SpecialistService.cs dziedziczący z ISpecialistService z pobraniem profilu

Zarejestrowano w Program.cs

Dodanie komentarzy XMLowych w ApiResponse. Również w swoim kodzie używam komentarzy XML by pomagać w wyjaśnieniu kodu, oraz by pokazywało te objaśnienia przy używaniu tych funkcji poza kodem macierzystym.

Po stworzeniu "profilu" przeszedłem do rejestracji, dla specjalisty, która utworzy zarówno użytkownika jak i specjaliste.

Wypchnięto na backend nadpisując wszystko

Commit 2:

Stworzono SpecialistRegisterDto.cs, todo: ogarnąć fragmenty 

Zmodyfikowano AuthService.cs. Z jakiegoś powodu było tam using H4H_API.Dtos.Auth jak i H4H_API.DTOs.Auth. Ten drugi jest prawidłowy. Był mess że jeszcze w dwóch miejscach było Dtos z małej. Jest też ten problem w innych plikach.

Dodano mapowanie z modelu Specialist na SpecialistDto w MappingProfile.cs

Stworzono InquiryFilterDto.cs z filtrami oraz InquiryListItemDto.cs zgodnie z tym co chciała Kasia. Zostały dodane do SpecialistService.

Zmiana SpecialistService.cs by uwzględnić zapytania i zmianę numeru PWZ (LicenseNumber)

Dodano oba endpointy do kontrolera, usunięto stare try-catche które były niepotrzebne.

Wypchnięto na Wiktor, nowy branch by utrzymać konsensus nazw.
