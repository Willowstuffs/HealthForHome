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

enum MapMode {
  detailed, // StartScreen
  simple,   // UpcomingScreen
}

class MapScreen extends StatefulWidget {
  final List<Map<String, dynamic>> inquiries;
  final String? highlightId;
  final MapMode mode;

  const MapScreen({
    super.key,
    required this.inquiries,
    this.highlightId,
    this.mode = MapMode.detailed,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final List<Marker> markers = [];
  final MapController mapController = MapController();

  Map<String, dynamic>? selectedInquiry;
  List<Map<String, dynamic>> inquiriesList = [];

  double zoom = 12;
  LatLng? mapCenter;
  bool loading = true;

  String? highlightedId;

  final Map<String, LatLng> _addressCache = {};
  bool get isSimpleMode => widget.mode == MapMode.simple;

  bool get isDetailed => widget.mode == MapMode.detailed;

  @override
  void initState() {
    super.initState();
    highlightedId = widget.highlightId;
    _fetchAndBuild();
  }

  @override
  void deactivate() {
    selectedInquiry = null;
    highlightedId = null;
    super.deactivate();
  }

  @override
  void dispose() {
    markers.clear();
    selectedInquiry = null;
    highlightedId = null;
    inquiriesList.clear();
    super.dispose();
  }
  String _shortAddress(String original) {
    final parts = original.split(',');

    if (parts.length >= 2) {
      String street = parts[0].trim();
      String city = parts[1].trim();

      street = street.replaceAll(RegExp(r'[\d-]'), '');

      return '$street, $city';
    }

    return original.replaceAll(RegExp(r'[\d-]'), '');
  }

  Future<void> _fetchAndBuild() async {
    try {
      final now = DateTime.now();
      final areas = UserSession.profile?.serviceAreas;

      if (areas != null && areas.isNotEmpty) {
        final city = areas.first.city;
        final center = await GeoService.getLatLngFromAddress(city);

        if (center != null) {
          mapCenter = center;
        }
      }
      inquiriesList = (await ApiService().getInquiries(
        patientName: "",
        dateFrom: DateTime(now.year, now.month, now.day),
        dateTo: DateTime(now.year, now.month, now.day)
            .add(const Duration(days: 90)),
      ))
          .map((i) {
        final id = i['appointmentId'] ?? i['AppointmentId'];
        final fullAddress = (i['patientAddress'] ?? i['PatientAddress'] ?? '').toString();

        DateTime? start = DateTime.tryParse(
          i['scheduledStart'] ?? i['ScheduledStart'] ?? '',
        );

        DateTime? end = DateTime.tryParse(
          i['scheduledEnd'] ?? i['ScheduledEnd'] ?? '',
        );

        return {
          'id': id?.toString() ?? '',
          'name': i['patientName'] ?? '',
          'startDate': start != null ? DateFormat('dd-MM-yyyy HH:mm').format(start) : '',
          'endDate': end != null ? DateFormat('dd-MM-yyyy HH:mm').format(end) : '',
          'description': i['description'] ?? '',
          'address': isSimpleMode
              ? _shortAddress(fullAddress)
              : fullAddress,

          'fullAddress': fullAddress,

        };
      }).toList();

      await _buildMarkers();

      if (!mounted) return;
      setState(() => loading = false);
    } catch (e) {
      debugPrint("MAP ERROR: $e");
      setState(() => loading = false);
    }
  }

  Future<LatLng?> _getCachedLatLng(String address) async {
    if (_addressCache.containsKey(address)) {
      return _addressCache[address];
    }

    final result = await GeoService.getLatLngFromAddress(address);

    if (result != null) {
      _addressCache[address] = result;
    }

    return result;
  }

  LatLng _blur(LatLng original, String seed) {
    final random = math.Random(seed.hashCode);
    final latOffset = (random.nextDouble() - 0.5) * 0.006;
    final lngOffset = (random.nextDouble() - 0.5) * 0.006;

    return LatLng(
      original.latitude + latOffset,
      original.longitude + lngOffset,
    );
  }

  Future<void> _buildMarkers() async {
    final List<Marker> temp = [];
    selectedInquiry = null;

    for (final inquiry in inquiriesList) {
      final address = inquiry['address'];
      if (address == null || address.isEmpty) continue;

      final latLng = await _getCachedLatLng(address);
      if (latLng == null) continue;

      final point = _blur(latLng, inquiry['id']);
      inquiry['latLng'] = point;

      final isHighlighted = inquiry['id'] == highlightedId;

      if (isHighlighted) {
        selectedInquiry = inquiry;
      }

      temp.add(
        Marker(
          point: point,
          width: isHighlighted ? 60 : 45,
          height: isHighlighted ? 60 : 45,
          child: GestureDetector(
            onTap: () {
              if (isDetailed) {
                _showBottomSheet(inquiry);
              } else {
                mapController.move(point, 15);
              }
            },
            child: _buildMarker(isHighlighted),
          ),
        ),
      );
    }

    if (!mounted) return;

    setState(() {
      markers
        ..clear()
        ..addAll(temp);
    });

    if (isDetailed &&
        selectedInquiry != null &&
        highlightedId != null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        mapController.move(selectedInquiry!['latLng'], 15);
        _showBottomSheet(selectedInquiry!);
      });
    }
  }

  Widget _buildMarker(bool highlight) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.red.withOpacity(0.2),
      shape: BoxShape.circle,
    ),
    child: Center(
      child: Container(
        width: highlight ? 18 : 14,
        height: highlight ? 18 : 14,
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    ),
  );
}

  void _showBottomSheet(Map<String, dynamic> item) {
    if (!isDetailed) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item['name'] ?? ''),
                const SizedBox(height: 8),
                Text(item['address'] ?? ''),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OfferFormScreen(
                          appointmentId: item['id'],
                          patientName: item['name'],
                          startDate: item['startDate'],
                          endDate: item['endDate'],
                          description: item['description'],
                        ),
                      ),
                    );
                  },
                  child: const Text("Szczegóły"),
                ),
              ],
            ),
          ),
        );
      },
    );
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
}