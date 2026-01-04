import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import '../services/login_response.dart';
import '../services/token_storage.dart';

class ApiService {
  static const String _baseUrl = 'https://10.0.2.2:7026';

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
Future<void> certyficatenurse({
  required String licenseNumber
}) async {
  try {
    print('📤 Wysyłam PWZ: "$licenseNumber"'); // dla debugu
    await _dio.post(
      '/api/specialist/license',
      data: '"$licenseNumber"', // <-- kluczowa zmiana
      options: Options(
        contentType: Headers.jsonContentType, // wymusza application/json
      ),
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
      data: {
        "email": email,
        "password": password,
      },
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

  // pobieranie licensenumber
  Future<Map<String, dynamic>?> getQualification() async {
    try {
      final response = await _dio.get('/api/specialist/qualification');
      print("📦 Backend 2 zwrócił profile: ${response.data}");
      return response.data['data'];
      
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ERROR HANDLING

  Exception _handleDioError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response?.statusCode;

      switch (statusCode) {
        case 401:
          return Exception('Brak tokenu');
        case 400:
          return Exception('Niepoprawne dane rejestracyjne');
        case 409:
          return Exception('Użytkownik już istnieje');
        case 500:
          return Exception('Błąd serwera');
        default:
          return Exception(e.response?.data['message'] ?? 'Błąd rejestracji');
      }
    } else {
      return Exception('Brak połączenia z serwerem');
    }
  }
}
