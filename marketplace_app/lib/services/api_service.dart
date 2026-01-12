import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import '../models/auth_models.dart';
import '../models/client_profile.dart';
import '../models/client_update_dto.dart';

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

  void setToken(String token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
  }

  // Auth

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
          if (phoneNumber != null) "phoneNumber": phoneNumber,
          if (dateOfBirth != null)
            "dateOfBirth": dateOfBirth.toIso8601String().split('T')[0],
          if (address != null) "address": address,
          if (emergencyContact != null) "emergencyContact": emergencyContact,
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
      setToken(loginResponse.accessToken);
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
      clearToken();
    }
  }

  // Client Profile

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

  // ERROR HANDLING

  Exception _handleDioError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response?.statusCode;

      switch (statusCode) {
        case 400:
          return Exception(e.response?.data['message'] ?? 'Niepoprawne dane');
        case 401:
          return Exception('Brak autoryzacji');
        case 403:
          return Exception('Brak dostępu');
        case 409:
          return Exception('Użytkownik już istnieje');
        case 500:
          return Exception('Błąd serwera');
        default:
          return Exception(e.response?.data['message'] ?? 'Wystąpił błąd');
      }
    } else {
      return Exception('Brak połączenia z serwerem');
    }
  }
}
