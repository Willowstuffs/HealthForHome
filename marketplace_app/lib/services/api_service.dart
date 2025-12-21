import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

class ApiService {
  // 10.0.2.2 - bridge localhost dla emulatora Android
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
      LogInterceptor(
        request: true,
        requestBody: true,
        responseBody: true,
        error: true,
      ),
    );
  }

  // Auth

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      await _dio.post(
        '/api/Auth/register',
        data: {
          "email": email,
          "password": password,
          "firstName": firstName,
          "lastName": lastName,
        },
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (_) {
      throw Exception('Nieznany błąd');
    }
  }

  // ERROR HANDLING

  Exception _handleDioError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response?.statusCode;

      switch (statusCode) {
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
