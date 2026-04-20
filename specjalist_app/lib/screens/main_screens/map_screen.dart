import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:specjalist_app/services/user_profile.dart';
import 'dart:math' as math;

import '../../theme/app_theme.dart';
import '../../services/geo_service.dart';
import '../../services/api_service.dart';
import '../offer_from_screen.dart';

class MapScreen extends StatefulWidget {
  final List<Map<String, dynamic>> inquiries;
  final String? highlightId;

  const MapScreen({
    super.key,
    required this.inquiries,
    this.highlightId,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final List<Marker> markers = [];
  final MapController mapController = MapController();
  Map<String, dynamic>? selectedInquiry;
  double zoom = 12;
  LatLng? mapCenter;
  final now = DateTime.now();
  String? highlightedId;
  bool loading = true;
  List<Map<String, dynamic>> inquiriesList = [];
  final Map<String, LatLng> _addressCache = {};
  @override
  void initState() {
    super.initState();
    highlightedId = widget.highlightId;
    _fetchAndLoad();
  }

  Future<void> _fetchAndLoad() async {
    try {
      final areas = UserSession.profile?.serviceAreas;

      if (areas != null && areas.isNotEmpty) {
        final city = areas.first.city;

        final center = await GeoService.getLatLngFromAddress(city);

        if (center != null) {
          mapCenter = center;
        }
      }

      final displayFormatter = DateFormat('dd-MM-yyyy HH:mm');

      inquiriesList = (await ApiService().getInquiries(
        patientName: "",
        dateFrom: DateTime(now.year, now.month, now.day),
        dateTo: DateTime(now.year, now.month, now.day)
            .add(const Duration(days: 90)),
      ))
          .map((i) {
        final id = i['appointmentId'] ?? i['AppointmentId'];

        DateTime? start = i['scheduledStart'] != null
            ? DateTime.tryParse(i['scheduledStart'])
            : (i['ScheduledStart'] != null
                ? DateTime.tryParse(i['ScheduledStart'])
                : null);

        DateTime? end = i['scheduledEnd'] != null
            ? DateTime.tryParse(i['scheduledEnd'])
            : (i['ScheduledEnd'] != null
                ? DateTime.tryParse(i['ScheduledEnd'])
                : null);

        return {
          'id': id?.toString() ?? '',
          'name': i['patientName'] ?? i['PatientName'] ?? '',
          'startDate': start != null ? displayFormatter.format(start) : '',
          'endDate': end != null ? displayFormatter.format(end) : '',
          'description': i['description'] ?? i['Description'] ?? '',
          'address': i['patientAddress'] ?? i['PatientAddress'] ?? '',
        };
      }).toList();
  
      await _buildMarkersAndCircles();

      if (highlightedId != null && selectedInquiry != null) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future.delayed(const Duration(milliseconds: 250), () {
      mapController.move(
        selectedInquiry!['latLng'],
        15, // zoom
      );

      _showInquiryDetails(selectedInquiry!);
    });
  });
}
    } catch (e) {
      debugPrint("MAP ERROR: $e");
    }

    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }
  Future<LatLng?> getCachedLatLng(String address) async {
    if (_addressCache.containsKey(address)) {
      return _addressCache[address];
    }
    final LatLng? latLng = await GeoService.getLatLngFromAddress(address);
    if (latLng != null) _addressCache[address] = latLng;
    return latLng;
  }

  // --- deterministyczne rozmycie lokalizacji ---
  LatLng _getBlurredLocation(LatLng original, String seed) {
    final random = math.Random(seed.hashCode);
    double latOffset = (random.nextDouble() - 0.5) * 0.006;
    double lngOffset = (random.nextDouble() - 0.5) * 0.006;
    return LatLng(original.latitude + latOffset, original.longitude + lngOffset);
  }
Future<void> _buildMarkersAndCircles() async {
  final List<Marker> tempMarkers = [];

  selectedInquiry = null;

  // 🔥 najpierw sprawdzamy highlighted
  if (highlightedId != null &&
      !inquiriesList.any((e) => e['id'] == highlightedId)) {

    final confirmed =
        await ApiService().getConfirmedInquiryById(highlightedId!);

    if (confirmed != null) {
      inquiriesList.add(_mapConfirmedToInquiry(confirmed));
    }
  }

  // 🔥 dopiero TERAZ loop
  for (var inquiry in inquiriesList) {
    final address = inquiry['address'];
    if (address == null || address.toString().isEmpty) continue;

    final LatLng? exactLatLng = await getCachedLatLng(address);
    if (exactLatLng == null) continue;

    final LatLng blurredLatLng =
        _getBlurredLocation(exactLatLng, inquiry['id']);

    inquiry['latLng'] = blurredLatLng;

    final bool isHighlighted = inquiry['id'] == highlightedId;

    if (isHighlighted) {
      selectedInquiry = inquiry;
    }

    tempMarkers.add(
      Marker(
        point: blurredLatLng,
        width: isHighlighted ? 60 : 45,
        height: isHighlighted ? 60 : 45,
        child: GestureDetector(
          onTap: () => _showInquiryDetails(inquiry),
          child: _buildCustomMarker(isHighlighted: isHighlighted),
        ),
      ),
    );
  }

  setState(() {
    markers
      ..clear()
      ..addAll(tempMarkers);
  });
}
  Map<String, dynamic> _mapConfirmedToInquiry(dynamic i) {
  final displayFormatter = DateFormat('dd-MM-yyyy HH:mm');

  DateTime? start =
      DateTime.tryParse(i['scheduledStart'] ?? i['ScheduledStart']);

  DateTime? end =
      DateTime.tryParse(i['scheduledEnd'] ?? i['ScheduledEnd']);

  return {
    'id': (i['appointmentId'] ?? i['AppointmentId']).toString(),
    'name': i['patientName'] ?? i['PatientName'] ?? '',
    'startDate': start != null ? displayFormatter.format(start) : '',
    'endDate': end != null ? displayFormatter.format(end) : '',
    'description': i['description'] ?? i['Description'] ?? '',
    'address': i['patientAddress'] ?? i['PatientAddress'] ?? '',
  };
}
  void _showInquiryDetails(Map<String, dynamic> inquiry) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _buildBottomSheetSafe(inquiry),
  );
}

// Opakowanie BottomSheet w SafeArea
Widget _buildBottomSheetSafe(Map<String, dynamic> item) {
  return SafeArea(
    top: false, // ignoruje górny padding SafeArea
    child: _buildBottomSheet(item),
  );
}
  Widget _buildCustomMarker({required bool isHighlighted}) {
  return Container(
    decoration: BoxDecoration(
      color: isHighlighted
          ? Colors.green.withValues(alpha: 0.25)
          : AppColors.error.withValues(alpha: 0.2),
      shape: BoxShape.circle,
    ),
    child: Center(
      child: Container(
        width: isHighlighted ? 18 : 14,
        height: isHighlighted ? 18 : 14,
        decoration: BoxDecoration(
          color: isHighlighted ? Colors.green : AppColors.error,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    ),
  );
}
    
  double getCircleRadius() {
    double radius = zoom * 6; 
    return radius < 50 ? 50 : radius;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: mapCenter ?? const LatLng(52.2297, 21.0122),
                initialZoom: zoom,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.healthforhome.marketplace_app',
                ),
                MarkerLayer(markers: markers),
              ],
            ),
    );
  }
   Widget _buildBottomSheet(Map<String, dynamic> item) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            item['name'] ?? "Brak nazwy",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _infoRow(Icons.calendar_month, item['startDate'] ?? "Brak daty"),
          const SizedBox(height: 8),
          _infoRow(Icons.location_on_outlined, "Okolice: ${item['address']}"),
          const SizedBox(height: 16),
          Text(
            item['description'] ?? "",
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                Navigator.pop(context); // Zamknij modal
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OfferFormScreen(
                      appointmentId: item['id'],
                      patientName: item['name'],
                      startDate: item['startDate'],
                      endDate: item['endDate'] ?? "",
                      description: item['description'],
                    ),
                  ),
                );
              },
              child: const Text("Pokaż szczegóły i odpowiedz", style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.error),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w500))),
      ],
    );
  }

}