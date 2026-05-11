import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GooglePlacesService {
  static final GooglePlacesService _instance = GooglePlacesService._internal();
  factory GooglePlacesService() => _instance;
  GooglePlacesService._internal();

  final Dio _dio = Dio();
  Timer? _debounce;
  final Map<String, List<String>> _cache = {};
  Completer<List<String>>? _completer;

  Future<List<String>> getAutocompleteSuggestions(String query) async {
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return [];
    }

    // 1. Check if exact query is in cache
    if (_cache.containsKey(normalizedQuery)) {
      return _cache[normalizedQuery]!;
    }

    // 2. Check for zero-results prefix
    // If "Wrsz" returned 0 results, "Wrsza" will also return 0 results.
    for (var cachedKey in _cache.keys) {
      if (normalizedQuery.startsWith(cachedKey) && _cache[cachedKey]!.isEmpty) {
        return [];
      }
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (_completer != null && !_completer!.isCompleted) {
      // Complete with empty if cancelled
      _completer!.complete([]);
    }

    _completer = Completer<List<String>>();

    _debounce = Timer(const Duration(milliseconds: 800), () async {
      final String apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';

      if (apiKey.isEmpty) {
        debugPrint('Google Places API key is missing.');
        if (!_completer!.isCompleted) _completer!.complete([]);
        return;
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
            final results = suggestions.map((s) {
              final prediction = s['placePrediction'];
              String text = prediction['text']['text'] as String;
              return text.replaceAll(RegExp(r', Polska$|, Poland$'), '');
            }).toList();
            _cache[normalizedQuery] = results;
            if (!_completer!.isCompleted) _completer!.complete(results);
          } else {
             _cache[normalizedQuery] = [];
             if (!_completer!.isCompleted) _completer!.complete([]);
          }
        } else {
          if (!_completer!.isCompleted) _completer!.complete([]);
        }
      } catch (e) {
        if (e is DioException) {
          debugPrint('Dio Error fetching places: ${e.response?.data}');
        } else {
          debugPrint('Error fetching places: $e');
        }
        if (!_completer!.isCompleted) _completer!.complete([]);
      }
    });

    return _completer!.future;
  }
}
