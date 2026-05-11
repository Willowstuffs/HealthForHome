import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GooglePlacesService {
  final Dio _dio = Dio();

  Future<List<String>> getAutocompleteSuggestions(String query) async {
    if (query.isEmpty) {
      return [];
    }

    final String apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';

    if (apiKey.isEmpty) {
      debugPrint('Google Places API key is missing.');
      return [];
    }

    final String url = 'https://places.googleapis.com/v1/places:autocomplete';

    try {
      final response = await _dio.post(
        url,
        options: Options(
          headers: {
            'X-Goog-Api-Key': apiKey,
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'input': query,
          'includedRegionCodes': ['pl'],
          'languageCode': 'pl',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['suggestions'] != null) {
          final suggestions = data['suggestions'] as List;
          return suggestions.map((s) {
            final prediction = s['placePrediction'];
            String text = prediction['text']['text'] as String;
            return text.replaceAll(RegExp(r', Polska$|, Poland$'), '');
          }).toList();
        }
      }
    } catch (e) {
      if (e is DioException) {
        debugPrint('Dio Error fetching places: ${e.response?.data}');
      } else {
        debugPrint('Error fetching places: $e');
      }
    }

    return [];
  }
}
