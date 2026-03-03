import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import '../models/auth_models.dart';
import '../models/client_profile.dart';
import '../models/client_update_dto.dart';
import '../models/appointment.dart';
import '../models/specialist.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // 10.0.2.2 - bridge localhost dla emulatora Android
  static const String _baseUrl = 'https://10.0.2.2:7026';

  late final Dio _dio;
  String? _token;

  bool get isLoggedIn => _token != null;

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
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
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
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
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
      await setToken(loginResponse.accessToken);
      return loginResponse;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (_) {
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
