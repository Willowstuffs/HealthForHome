import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

class GeoService {

  /// ADDRESS → LAT LNG
  static Future<LatLng?> getLatLngFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);

      if (locations.isEmpty) return null;

      final location = locations.first;

      return LatLng(location.latitude, location.longitude);
    } catch (e) {
      print("Geocoding error: $e");
      return null;
    }
  }

  /// SERVICE AREA PAYLOAD
  static Future<Map<String, dynamic>> getServiceAreaPayload({
    required String city,
    String? postalCode,
    int maxDistanceKm = 50,
  }) async {
    LatLng? point;

    try {
      final query = postalCode != null && postalCode.isNotEmpty
          ? '$city, $postalCode'
          : city;

      final locations = await locationFromAddress(query);

      if (locations.isNotEmpty) {
        final loc = locations.first;
        point = LatLng(loc.latitude, loc.longitude);
      }
    } catch (e) {
      print("Geocoding error: $e");
    }

    return {
      "city": city,
      "postalCode": postalCode ?? "",
      "maxDistanceKm": maxDistanceKm,
      "latitude": point?.latitude,
      "longitude": point?.longitude,
    };
  }

  /// ✅ REAL ADDRESS VALIDATION (OpenStreetMap)
  static Future<bool> validateAddress({
    required String city,
    required String postalCode,
  }) async {
    try {
      final uri = Uri.parse(
        "https://nominatim.openstreetmap.org/search"
        "?city=$city&postalcode=$postalCode&format=json&limit=1",
      );

      final response = await http.get(
        uri,
        headers: {"User-Agent": "specjalist-app"},
      );

      if (response.statusCode != 200) {
        return false;
      }

      final data = jsonDecode(response.body);

      return data != null && data.isNotEmpty;
    } catch (e) {
      print("Validation error: $e");
      return false;
    }
  }

  /// COORDINATES → ADDRESS
  static Future<String?> getAddressFromLatLng(LatLng point) async {
    try {
      final placemarks =
          await placemarkFromCoordinates(point.latitude, point.longitude);

      if (placemarks.isEmpty) return null;

      final place = placemarks.first;

      final parts = [
        place.street,
        place.locality,
        place.postalCode,
        place.country
      ].where((e) => e != null && e.isNotEmpty).toList();

      return parts.join(", ");
    } catch (e) {
      print("Reverse geocoding error: $e");
      return null;
    }
  }
}