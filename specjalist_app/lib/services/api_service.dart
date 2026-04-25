import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import '../services/login_response.dart';
import '../services/token_storage.dart';
import '../services/specjalist_service.dart';
import 'package:http_parser/http_parser.dart';

// class ApiService {
//   static const String _baseUrl = 'https://h4h.makolino.com';
//   late final Dio _dio;

//   ApiService() {
//     _dio = Dio(
//       BaseOptions(
//         baseUrl: _baseUrl,
//         connectTimeout: const Duration(seconds: 600), // 10 minut
//         receiveTimeout: const Duration(seconds: 600),
//         headers: {'Content-Type': 'application/json'},
//       ),
//     );
class ApiService {
  static const bool isEmulator = true;
  static const String _baseUrl = isEmulator
      ? 'https://192.168.100.24:7026'
      : 'https://10.0.2.2:7026';
  late final Dio _dio;
  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // TODO: usunac w produkcji (samo podpisany certyfikat)
    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
        return client;
      },
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestBody: true,
        responseBody: true,
        error: true,
      ),
    );
  }

  // register

  Future<void> registerSpecialist({
    required String specialization,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      await _dio.post(
        '/api/auth/register/specialist',
        data: {
          "email": email,
          "password": password,
          "firstName": firstName,
          "lastName": lastName,
          "specialization": specialization,
        },
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  //post: zapisywanie numeru pwz
  Future<void> certyficatenurse({required String licenseNumber}) async {
    try {
      await _dio.post(
        '/api/specialist/license',
        data: '"$licenseNumber"',
        options: Options(contentType: Headers.jsonContentType),
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  //logowanie
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: {"email": email, "password": password},
      );

      final data = response.data['data'];
      return LoginResponse.fromJson(data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  //pobieranie danych do logowania
  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get('/api/specialist/profile');
    final data = response.data['data'];
    if (data == null) return {};
    print("📦 Backend zwrócił profile: ${response.data}");
    return Map<String, dynamic>.from(data);
  }

  Future<List<Map<String, dynamic>>> getAvailableOffers() async {
    try {
      print("➡️ CALLING /available-offers");

      final response = await _dio.get('/api/specialist/available-offers');

      print("✅ RESPONSE STATUS: ${response.statusCode}");
      print("✅ RESPONSE DATA: ${response.data}");

      final data = response.data as List<dynamic>;

      return data.map((item) => Map<String, dynamic>.from(item)).toList();
    } on DioException catch (e) {
      print("❌ DIO ERROR: ${e.response?.statusCode}");
      print(e.response?.data);
      throw _handleDioError(e);
    }
  }

  Future<List<ServiceType>> getServiceTypes() async {
    try {
      final response = await _dio.get('/api/specialist/service-types');
      final data = response.data['data'];
      print("📦 Backend zwrócił typyusług: $data");
      if (data == null || data.isEmpty) return [];
      return (data as List)
          .map((e) => ServiceType.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // GET: pobranie numeru PWZ (może być null)
  Future<String?> getLicense() async {
    try {
      final response = await _dio.get('/api/specialist/license');
      return response.data['data'];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<SpecialistService>> getServices() async {
    try {
      final response = await _dio.get('/api/specialist/services');
      final dynamic responseData = response.data['data'];

      if (responseData == null) return [];

      final List list = responseData as List;
      return list.map((e) {
        return SpecialistService.fromJson(Map<String, dynamic>.from(e));
      }).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      print('Błąd krytyczny: $e');
      return [];
    }
  }

  //POST: zapisz nową usługę
  Future<void> addService({
    String? serviceTypeId,
    String? customName,
    required String category,
    required double price,
    required int durationMinutes,
    String? description,
  }) async {
    try {
      /// walidacja lokalna
      if (serviceTypeId == null && customName == null) {
        throw Exception('Musisz podać typ usługi lub własną nazwę');
      }

      final payload = {
        "serviceTypeId": serviceTypeId,
        "serviceName": customName,
        "category": category,
        "price": price,
        "durationMinutes": durationMinutes,
        "description": description,
      };

      /// usuń null-e (BARDZO WAŻNE)
      payload.removeWhere((key, value) => value == null);

      await _dio.post('/api/specialist/services', data: payload);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          'Błąd dodawania usługi: '
          '${e.response?.data['title'] ?? e.message}',
        );
      } else {
        throw Exception('Brak połączenia z serwerem');
      }
    }
  }

  Future<List<Map<String, dynamic>>> getInquiries({
    String? appointmentId,
    String? patientName,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? serviceName,
    int? maxDistanceKm,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (appointmentId != null) queryParams['appointmentId'] = appointmentId;
      if (patientName != null) queryParams['patientName'] = patientName;
      if (dateFrom != null)
        queryParams['dateFrom'] = dateFrom.toIso8601String();
      if (dateTo != null) queryParams['dateTo'] = dateTo.toIso8601String();
      if (serviceName != null) queryParams['serviceName'] = serviceName;
      if (maxDistanceKm != null) queryParams['maxDistanceKm'] = maxDistanceKm;

      final response = await _dio.get(
        '/api/specialist/inquiries',
        queryParameters: queryParams,
      );
      print("📦 Backend  zwrócił zapytania: ${response.data}");
      final raw = response.data['data'];

if (raw == null) return [];

final data = raw as List<dynamic>;
      return data.map((item) => Map<String, dynamic>.from(item)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getCommingInquiries({
    String? appointmentId,
    String? patientName,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? serviceName,
    String? patientAddress,
    String? price,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (appointmentId != null) queryParams['appointmentId'] = appointmentId;
      if (patientName != null) queryParams['patientName'] = patientName;
      if (dateFrom != null)
        queryParams['dateFrom'] = dateFrom.toIso8601String();
      if (dateTo != null) queryParams['dateTo'] = dateTo.toIso8601String();
      if (serviceName != null) queryParams['serviceName'] = serviceName;
      if (patientAddress != null)
        queryParams['patientAddress'] = patientAddress;
      if (price != null) queryParams['price'] = price;

      final response = await _dio.get(
        '/api/specialist/inquiries/comming',
        queryParameters: queryParams,
      );
      final data = response.data['data'] as List<dynamic>;
      return data.map((item) => Map<String, dynamic>.from(item)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getArchiveInquiries({
    String? appointmentId,
    String? patientName,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? serviceName,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (appointmentId != null) queryParams['appointmentId'] = appointmentId;
      if (patientName != null) queryParams['patientName'] = patientName;
      if (dateFrom != null)
        queryParams['dateFrom'] = dateFrom.toIso8601String();
      if (dateTo != null) queryParams['dateTo'] = dateTo.toIso8601String();
      if (serviceName != null) queryParams['serviceName'] = serviceName;
      final response = await _dio.get(
        '/api/specialist/inquiries/archive',
        queryParameters: queryParams,
      );
      final data = response.data['data'] as List<dynamic>;
      return data.map((item) => Map<String, dynamic>.from(item)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // PUT /services/{id}
  Future<void> updateService({
    required String id,
    required double price,
    required int durationMinutes,
    required String serviceTypeId,
    String? description,
  }) async {
    // To musi być poprawny GUID. Jeśli będzie pusty, backend rzuci błąd 400.
    if (serviceTypeId.isEmpty) {
      throw Exception("Błąd: Nie odnaleziono ID typu usługi (ServiceTypeId).");
    }

    final payload = {
      "serviceTypeId": serviceTypeId,
      "price": price,
      "durationMinutes": durationMinutes,
      "description": description ?? "",
    };

    try {
      await _dio.put('/api/specialist/services/$id', data: payload);
    } on DioException catch (e) {
      print("BŁĄD SERWERA: ${e.response?.data}");
      throw _handleDioError(e);
    }
  }

  //UPDATE/area
  Future<void> updateArea(Map<String, dynamic> dto) async {
    try {
      await _dio.put('/api/specialist/area', data: dto);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // PATCH: potwierdzenie wizyty przez specjalistę
  Future<void> confirmAppointment(
    String appointmentId,
    List<String> serviceTypeIds,
    DateTime proposedDate,
    double price,
  ) async {
    try {
      await _dio.patch(
        '/api/specialist/appointments/$appointmentId/confirm',
        data: {
          "serviceTypeIds": serviceTypeIds,
          "price": price,
          "proposedDate": proposedDate.toIso8601String(),
        },
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // DELETE /services/{id}
  Future<void> deleteService(String id) async {
    await _dio.delete('/api/specialist/services/$id');
  }

  Future<void> sendDeviceToken(String token) async {
    await _dio.post('/api/auth/device-token', data: {"token": token});
  }
  
  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    String? phoneNumber,
    String? professionalTitle,
    String? bio,
    double? hourlyRate,
    File? avatar,
  }) async {
    final formDataMap = <String, dynamic>{
      "FirstName": firstName,
      "LastName": lastName,
      "Email": email,
      if (phoneNumber != null) "PhoneNumber": phoneNumber,
      if (professionalTitle != null) "ProfessionalTitle": professionalTitle,
      if (bio != null) "Bio": bio,
      if (hourlyRate != null) "HourlyRate": hourlyRate,
    };

    if (avatar != null) {
      formDataMap["Avatar"] = await MultipartFile.fromFile(
        avatar.path,
        filename: "avatar.jpg",
        contentType: MediaType("image", "jpeg"),
      );
    }

    final formData = FormData.fromMap(formDataMap);

    try {
      final response = await _dio.put(
        '/api/specialist/profile',
        data: formData,
        options: Options(
          contentType:
              'multipart/form-data', // nagłówek Content-Type dla multipart
        ),
      );

      if (response.statusCode == 200) {
        print('Profil updated successfully!');
      } else {
        print('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating profile: $e');
    }
  }

  // POST: wyślij kod ponownie
  Future<void> sendVerificationCode(String email) async {
    try {
      await _dio.post(
        '/api/auth/send-verification-code',
        data: {"email": email},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<dynamic> getConfirmedInquiryById(String id) async {
  final list = await getCommingInquiries(
    patientName: "",
    dateFrom: DateTime.now().subtract(const Duration(days: 365)),
    dateTo: DateTime.now().add(const Duration(days: 365)),
  );

  for (final e in list) {
    final appointmentId =
        (e['appointmentId'] ?? e['AppointmentId']).toString();

    if (appointmentId == id) {
      return e;
    }
  }

  return null;
}

  // POST: weryfikacja kodu
  Future<void> verifyCode({required String email, required String code}) async {
    try {
      await _dio.post(
        '/api/auth/verify-code',
        data: {"email": email, "code": code},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  // ERROR HANDLING

  Exception _handleDioError(DioException e) {
    if (e.response != null) {
      final data = e.response?.data;
      final statusCode = e.response?.statusCode;

      // Obsługa walidacji
      if (data is Map && data.containsKey('errors')) {
        final errors = data['errors'];

        if (errors is Map && errors.isNotEmpty) {
          final firstFieldErrors = errors.values.first;

          if (firstFieldErrors is List && firstFieldErrors.isNotEmpty) {
            return Exception(firstFieldErrors.first.toString());
          }
        }
      }

      // Obsługa message z backendu
      if (data is Map && data['message'] != null) {
        return Exception(data['message']);
      }

      // Obsługa errorCode
      final String? errorCode = data is Map ? data['errorCode'] : null;

      if (errorCode != null) {
        switch (errorCode) {
          case "AUTH_001":
            return Exception('Niepoprawny e-mail lub hasło.');
          case "AUTH_002":
            return Exception('Ten adres e-mail jest już zajęty.');
          case "AUTH_003":
            return Exception('Użytkownik nie został odnaleziony.');
          case "AUTH_005":
            return Exception('Niepoprawny kod weryfikacyjny.');
          case "AUTH_006":
            return Exception('Kod weryfikacyjny wygasł.');
          case "VAL_001":
            return Exception('Błąd walidacji danych.');
        }
      }

      // Fallback HTTP
      switch (statusCode) {
        case 401:
          return Exception('Sesja wygasła. Zaloguj się ponownie.');
        case 403:
          return Exception('Brak uprawnień.');
        case 500:
          return Exception('Błąd serwera.');
        default:
          return Exception('Nieoczekiwany błąd ($statusCode)');
      }
    }

    if (e.type == DioExceptionType.connectionTimeout) {
      return Exception('Timeout połączenia.');
    }

    return Exception('Brak internetu.');
  }
}
