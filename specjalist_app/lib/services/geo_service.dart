import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

class GeoService {
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

  /// 🔥 Reverse geocoding – coordinates → approximate address
  static Future<String?> getAddressFromLatLng(LatLng point) async {
    try {
      final placemarks =
          await placemarkFromCoordinates(point.latitude, point.longitude);

      if (placemarks.isEmpty) return null;

      final place = placemarks.first;

      // Składamy przybliżony adres
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