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

  const MapScreen({
    super.key,
    required this.inquiries,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final List<Marker> markers = [];
  final List<CircleMarker> circles = [];
  final MapController mapController = MapController();
  Map<String, dynamic>? selectedInquiry;
  double zoom = 12;
  LatLng? mapCenter;
  final now = DateTime.now();
  bool loading = true;
  List<Map<String, dynamic>> inquiriesList = [];
  @override
  void initState() {
    super.initState();
    _fetchAndLoad();
  }

  Future<void> _fetchAndLoad() async {
    try {
      final areas = UserSession.profile?.serviceAreas;

      if (areas != null && areas.isNotEmpty) {
        final city = areas.first.city;

        final center =
            await GeoService.getLatLngFromAddress(city);

        if (center != null) {
          mapCenter = center;
        }
      }

      final displayFormatter = DateFormat('dd-MM-yyyy HH:mm');

      inquiriesList = (await ApiService().getInquiries(
        patientName: "",
        dateFrom: DateTime(now.year, now.month, now.day),
        dateTo: DateTime(now.year, now.month, now.day)
            .add(const Duration(days: 30)),
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

    } catch (e) {
      debugPrint("MAP ERROR: $e");
    }

    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }
  LatLng _getBlurredLocation(LatLng original) {
    final random = math.Random();
    
    // Przesunięcie o ok. 0.003 to mniej więcej 300-500 metrów
    // Możesz dostosować tę wartość, aby obszar był większy lub mniejszy
    double latOffset = (random.nextDouble() - 0.5) * 0.006;
    double lngOffset = (random.nextDouble() - 0.5) * 0.006;

    return LatLng(original.latitude + latOffset, original.longitude + lngOffset);
  }
  Future<void> _buildMarkersAndCircles() async {
    final List<Marker> tempMarkers = [];
    final List<CircleMarker> tempCircles = [];

    for (var inquiry in inquiriesList) {
      final address = inquiry['address'];

      if (address == null || address.toString().isEmpty) continue;

      final LatLng? exactLatLng = await GeoService.getLatLngFromAddress(address);
      if (exactLatLng == null) continue;
      final LatLng blurredLatLng = _getBlurredLocation(exactLatLng);
      final String? blurredAddress = await GeoService.getAddressFromLatLng(blurredLatLng);
       inquiry['address'] = blurredAddress ?? address;

      inquiry['latLng'] = blurredLatLng;
      tempMarkers.add(
        Marker(
          point: blurredLatLng,
          width: 40,
          height: 40,
          child: Icon(
            Icons.person,
            color: AppColors.accent,
            size: 40,
          ),
        ),
      );

      tempCircles.add(
        CircleMarker(
          point: blurredLatLng,
          radius: getCircleRadius(),
          color: AppColors.accent.withValues(alpha: 0.2),
          borderStrokeWidth: 2,
          borderColor: AppColors.accent,
        ),
      );
    }

    markers.clear();
    circles.clear();

    markers.addAll(tempMarkers);
    circles.addAll(tempCircles);
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
        : Stack(
            children: [
              FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: mapCenter ?? const LatLng(52.2297, 21.0122),
                  initialZoom: zoom,
                   interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  onTap: (tapPosition, point) {
                    setState(() {
                      selectedInquiry = null;
                    });
                  },

                  onPositionChanged: (position, hasGesture) {
                    if (!mounted) return;
                      setState(() {
                        
                          zoom = position.zoom;
                        
                      });
                    
                  },

                  
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName:
                        'com.healthforhome.marketplace_app',
                  ),
                  CircleLayer(
                      circles: circles
                          .map(
                            (c) => CircleMarker(
                              point: c.point,
                              radius: getCircleRadius(),
                              color: c.color,
                              borderColor: c.borderColor,
                              borderStrokeWidth: c.borderStrokeWidth,
                            ),
                          )
                          .toList(),
                    ),
                  MarkerLayer(
                      markers: markers.map((marker) {
                        return Marker(
                          point: marker.point,
                          width: marker.width,
                          height: marker.height,
                          child: GestureDetector(
                            onTap: () {
                              final inquiry =
                                  _findInquiryByPosition(marker.point);

                              if (inquiry != null) {
                                setState(() {
                                  selectedInquiry = inquiry;
                                });
                              }
                            },
                            child: marker.child,
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),

              if (selectedInquiry != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 40,
                  child: _buildMapPopup(),
                ),
            ],
      ),
    );
  }
   Map<String, dynamic>? _findInquiryByPosition(LatLng point) {
    const tolerance = 0.0005;
      for (var inquiry in inquiriesList) {
      final LatLng? latLng = inquiry['latLng'];
      if (latLng == null) continue;

      if ((latLng.latitude - point.latitude).abs() < tolerance &&
          (latLng.longitude - point.longitude).abs() < tolerance) {
        return inquiry;
      }
    }

    return null;
  }
  Widget _buildMapPopup() {
  final item = selectedInquiry!;

  return Material(
    elevation: 8,
    borderRadius: BorderRadius.circular(24),
    color: AppColors.surfaceContainer,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // Wyrównanie do lewej
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // IMIĘ I NAZWISKO
                    Text(
                      item['name'] ?? "Brak nazwy",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4), // Odstęp
                    
                    // DATA WIZYTY
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          item['startDate'] ?? "Data nieustalona",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // KRÓTKI OPIS
                    Text(
                      item['description'] ?? "Brak opisu",
                      maxLines: 2, // Ograniczenie do 2 linii
                      overflow: TextOverflow.ellipsis, // Wielokropek jeśli tekst jest za długi
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    selectedInquiry = null;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OfferFormScreen(
                
                      appointmentId: (item['id'] ?? "").toString(),
                      patientName: item['name'] ?? "Brak danych",
                      startDate: item['startDate'] ?? "",
                      endDate: item['endDate'] ?? "",
                      description: item['description'] ?? "Brak opisu",
                    ),
                  ),
                );
              },
              child: const Text("Szczegóły oferty"),
            ),
          ),
        ],
      ),
    ),
  );
}

}