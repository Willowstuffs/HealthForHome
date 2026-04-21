import 'dart:convert';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:dio/io.dart';
import '../models/auth_models.dart';
import '../models/client_profile.dart';
import '../models/client_update_dto.dart';
import '../models/appointment.dart';
import '../models/specialist.dart';
import '../models/nearby_specialist.dart';
import '../models/specialist_profile_details.dart';
import '../models/specialist_offer.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const bool isDev = false;
  static const String _baseUrl = isDev
      ? 'https://10.0.2.2:7026'
      : 'https://h4h.makolino.com';

  late final Dio _dio;
  String? _accessToken;
  String? _refreshToken;
  UserInfoDto? _currentUser;

  bool get isLoggedIn => _accessToken != null;
  UserInfoDto? get currentUser => _currentUser;

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
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
        onRequest: (options, handler) {
          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
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

  Future<void> initToken() async {
    const storage = FlutterSecureStorage();
    _accessToken = await storage.read(key: 'auth_token');
    _refreshToken = await storage.read(key: 'refresh_token');
    final accessTokenExpiresStr = await storage.read(
      key: 'access_token_expires',
    );
    final refreshTokenExpiresStr = await storage.read(
      key: 'refresh_token_expires',
    );

    final userJson = await storage.read(key: 'user');
    if (userJson != null) {
      try {
        _currentUser = UserInfoDto.fromJson(jsonDecode(userJson));
      } catch (_) {}
    }

    if (_accessToken != null && _refreshToken != null) {
      bool isAccessTokenValid = false;
      bool isRefreshTokenValid = false;

      final now = DateTime.now().add(
        const Duration(minutes: 1),
      ); // 1 min buffer

      if (accessTokenExpiresStr != null) {
        try {
          final expDate = DateTime.parse(accessTokenExpiresStr);
          if (expDate.isAfter(now)) {
            isAccessTokenValid = true;
          }
        } catch (_) {}
      }

      if (refreshTokenExpiresStr != null) {
        try {
          final refreshExpDate = DateTime.parse(refreshTokenExpiresStr);
          if (refreshExpDate.isAfter(now)) {
            isRefreshTokenValid = true;
          }
        } catch (_) {}
      }

      if (isAccessTokenValid) {
        return;
      } else if (isRefreshTokenValid) {
        await refreshSession();
      } else {
        await clearToken();
      }
    } else {
      await clearToken();
    }
  }

  Future<void> refreshSession() async {
    try {
      final response = await _dio.post(
        '/api/Auth/refresh-token',
        data: {"accessToken": _accessToken, "refreshToken": _refreshToken},
        options: Options(
          validateStatus: (status) =>
              true, // Przepuść wszystkie statusy (nawet 400) bez rzucania wyjątku
        ),
      );

      if (response.data != null &&
          response.data['success'] == true &&
          response.data['data'] != null) {
        final loginResponse = LoginResponse.fromJson(response.data['data']);
        await saveSession(loginResponse);
      } else {
        await clearToken();
      }
    } catch (_) {
      await clearToken();
    }
  }

  Future<void> saveSession(LoginResponse response) async {
    _accessToken = response.accessToken;
    _refreshToken = response.refreshToken;
    _currentUser = response.user;

    const storage = FlutterSecureStorage();
    await storage.write(key: 'auth_token', value: response.accessToken);
    await storage.write(key: 'refresh_token', value: response.refreshToken);
    await storage.write(
      key: 'access_token_expires',
      value: response.accessTokenExpires.toIso8601String(),
    );
    await storage.write(
      key: 'refresh_token_expires',
      value: response.refreshTokenExpires.toIso8601String(),
    );
    await storage.write(key: 'user', value: jsonEncode(response.user.toJson()));
  }

  Future<void> clearToken() async {
    _accessToken = null;
    _refreshToken = null;
    _currentUser = null;

    const storage = FlutterSecureStorage();
    await storage.delete(key: 'auth_token');
    await storage.delete(key: 'refresh_token');
    await storage.delete(key: 'access_token_expires');
    await storage.delete(key: 'refresh_token_expires');
    await storage.delete(key: 'user');
  }

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? address,
    String? emergencyContact,
  }) async {
    try {
      await _dio.post(
        '/api/Auth/register/client',
        data: {
          "email": email,
          "password": password,
          "firstName": firstName,
          "lastName": lastName,
          "phoneNumber": ?phoneNumber,
          if (dateOfBirth != null)
            "dateOfBirth": dateOfBirth.toIso8601String().split('T')[0],
          "address": ?address,
          "emergencyContact": ?emergencyContact,
        },
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (_) {
      throw Exception('Nieznany błąd');
    }
  }

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/Auth/login',
        data: {"email": email, "password": password},
      );

      final loginResponse = LoginResponse.fromJson(response.data['data']);

      if (loginResponse.user.userType.toLowerCase() != 'client') {
        throw Exception('Tylko klienci mogą się zalogować do tej aplikacji.');
      }

      await saveSession(loginResponse);
      return loginResponse;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e.toString().contains('Tylko klienci')) {
        rethrow;
      }
      throw Exception('Nieznany błąd logowania');
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/api/Auth/logout');
    } catch (_) {
      // Ignore errors on logout
    } finally {
      await clearToken();
    }
  }

  Future<void> updateDeviceToken(String token) async {
    try {
      await _dio.post('/api/Auth/device-token', data: {"token": token});
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (_) {
      throw Exception('Nie udało się zaktualizować tokenu urządzenia.');
    }
  }

  Future<void> sendVerificationCode(String email) async {
    try {
      await _dio.post(
        '/api/Auth/send-verification-code',
        data: {"email": email},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (_) {
      throw Exception('Nieznany błąd podczas wysyłania kodu weryfikacyjnego');
    }
  }

  Future<void> verifyCode(String email, String code) async {
    try {
      await _dio.post(
        '/api/Auth/verify-code',
        data: {"email": email, "code": code},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (_) {
      throw Exception('Nieznany błąd podczas weryfikacji kodu');
    }
  }

  Future<ClientProfile> getClientProfile() async {
    try {
      final response = await _dio.get('/api/Client/profile');
      return ClientProfile.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (_) {
      throw Exception('Błąd pobierania profilu');
    }
  }

  Future<ClientProfile> updateClientProfile(ClientUpdateDto dto) async {
    try {
      final response = await _dio.put(
        '/api/Client/profile',
        data: dto.toJson(),
      );
      return ClientProfile.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (_) {
      throw Exception('Błąd aktualizacji profilu');
    }
  }

  Future<List<Specialist>> searchSpecialists({String? category}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null) {
        queryParams['ServiceType'] = category;
      }

      final response = await _dio.get(
        '/api/Client/specialists/search',
        queryParameters: queryParams,
      );

      final List<dynamic> list = response.data['data']['items'];
      return list.map((e) => Specialist.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Appointment>> getAppointments({
    int page = 1,
    int pageSize = 10,
    String? status,
  }) async {
    try {
      final queryParams = {
        'Page': page,
        'PageSize': pageSize,
        'status': ?status,
      };

      final response = await _dio.get(
        '/api/Client/appointments',
        queryParameters: queryParams,
      );
      final List<dynamic> list = response.data['data']['items'];
      return list.map((e) => Appointment.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Appointment> getAppointmentDetails(String id) async {
    try {
      final response = await _dio.get('/api/Client/appointments/$id');
      return Appointment.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (_) {
      throw Exception('Błąd pobierania szczegółów wizyty');
    }
  }

  Future<void> cancelAppointment(String id) async {
    try {
      await _dio.post('/api/Client/appointments/$id/cancel');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (_) {
      throw Exception('Nieznany błąd podczas anulowania wizyty');
    }
  }

  Future<String> createServiceRequest(CreateServiceRequestDto dto) async {
    try {
      final response = await _dio.post(
        '/api/Client/service-requests',
        data: dto.toJson(),
      );

      // The backend returns the GUID as a string in the data field
      final requestId = response.data['data']?.toString();
      if (requestId == null || requestId.isEmpty) {
        throw Exception('Niepoprawna odpowiedź serwera');
      }

      return requestId;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Nieznany błąd podczas tworzenia ogłoszenia: $e');
    }
  }

  Future<List<ServiceRequest>> getMyServiceRequests() async {
    try {
      final response = await _dio.get('/api/Client/service-requests');

      // Handle the response data structure
      final data = response.data;
      List<dynamic> list;

      if (data is Map<String, dynamic>) {
        // If response is wrapped in ApiResponse format
        list = data['data'] ?? [];
      } else if (data is List) {
        // If response is direct list
        list = data;
      } else {
        throw Exception('Niepoprawny format odpowiedzi serwera');
      }

      return list.map((e) => ServiceRequest.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Błąd podczas pobierania ogłoszeń: $e');
    }
  }

  Future<List<AppointmentOffer>> getAppointmentOffers(
    String appointmentId,
  ) async {
    try {
      final response = await _dio.get(
        '/api/Client/appointments/$appointmentId/offers',
      );
      final List<dynamic> list = response.data['data'] ?? [];
      return list.map((e) => AppointmentOffer.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Nie udało się pobrać ofert: $e');
    }
  }

  Future<void> acceptAppointmentOffer(
    String appointmentId,
    String specialistId,
  ) async {
    try {
      await _dio.post(
        '/api/Client/appointments/$appointmentId/accept-offer/$specialistId',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Nie udało się zaakceptować oferty: $e');
    }
  }

  Future<List<NearbySpecialist>> getNearbySpecialistsByAddressText(
    String address,
  ) async {
    try {
      final response = await _dio.get(
        '/api/Client/specialists/nearby/by-address-text',
        queryParameters: {'address': address},
      );
      final List<dynamic> list = response.data['data'] ?? [];
      return list.map((e) => NearbySpecialist.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (_) {
      throw Exception('Nie udało się pobrać specjalistów po adresie.');
    }
  }

  Future<List<NearbySpecialist>> getNearbySpecialists(
    double lat,
    double lng,
  ) async {
    try {
      final response = await _dio.get(
        '/api/Client/specialists/nearby',
        queryParameters: {'lat': lat, 'lng': lng},
      );
      final List<dynamic> list = response.data['data'] ?? [];
      return list.map((e) => NearbySpecialist.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (_) {
      throw Exception('Nie udało się pobrać pobliskich specjalistów.');
    }
  }

  Future<List<NearbySpecialist>> getNearbySpecialistsMyAddress() async {
    try {
      final response = await _dio.get(
        '/api/Client/specialists/nearby/my-address',
      );
      final List<dynamic> list = response.data['data'] ?? [];
      return list.map((e) => NearbySpecialist.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (_) {
      throw Exception('Nie udało się pobrać specjalistów dla twojego adresu.');
    }
  }

  Future<SpecialistProfileDetails> getSpecialistProfileDetails(
    String id,
  ) async {
    try {
      final response = await _dio.get('/api/Client/specialist/$id/profile');
      return SpecialistProfileDetails.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (_) {
      throw Exception('Błąd podczas pobierania profilu specjalisty.');
    }
  }

  Future<List<SpecialistOffer>> getSpecialistFullOffer(String id) async {
    try {
      final response = await _dio.get('/api/Client/specialist/$id/full-offer');
      final List<dynamic> list = response.data['data'] ?? [];
      return list.map((e) => SpecialistOffer.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (_) {
      throw Exception('Błąd podczas pobierania oferty specjalisty.');
    }
  }

  // ERROR HANDLING

  Exception _handleDioError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;

      // Try to extract error message from response
      String errorMessage = 'Wystąpił błąd';
      if (responseData is Map<String, dynamic>) {
        errorMessage =
            responseData['message'] ?? responseData['error'] ?? errorMessage;
      }

      switch (statusCode) {
        case 400:
          return Exception('Niepoprawne dane: $errorMessage');
        case 401:
          return Exception('Brak autoryzacji. Zaloguj się ponownie.');
        case 403:
          return Exception('Brak uprawnień: $errorMessage');
        case 404:
          return Exception('Nie znaleziono zasobu: $errorMessage');
        case 409:
          return Exception('Konflikt danych: $errorMessage');
        case 422:
          return Exception('Niepoprawne dane: $errorMessage');
        case 500:
          return Exception('Błąd serwera: $errorMessage');
        default:
          return Exception('Błąd HTTP $statusCode: $errorMessage');
      }
    } else {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return Exception('Przekroczono limit czasu połączenia');
      } else if (e.type == DioExceptionType.connectionError) {
        return Exception('Brak połączenia z serwerem');
      } else {
        return Exception('Błąd sieciowy: ${e.message}');
      }
    }
  }
}
