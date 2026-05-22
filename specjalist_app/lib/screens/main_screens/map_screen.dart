import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;

import '../../theme/app_theme.dart';
import '../../services/geo_service.dart';
import '../../services/api_service.dart';
import '../offer_from_screen.dart';
import 'package:specjalist_app/services/user_profile.dart';
import '../../services/address_formatter.dart';

enum MapMode {
  toolbar,
  start,
  upcoming,
}

class MapScreen extends StatefulWidget {
  final List<Map<String, dynamic>> inquiries;
  final List<Map<String, dynamic>>? overrideInquiries;
  final String? highlightId;
  final MapMode mode;

  const MapScreen({
    super.key,
    required this.inquiries,
    this.highlightId,
    required this.mode,
    this.overrideInquiries,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController mapController = MapController();

  final List<Marker> markers = [];
  final Map<String, LatLng> _addressCache = {};

  List<Map<String, dynamic>> inquiriesList = [];
  Map<String, dynamic>? selectedInquiry;

  double zoom = 12;
  LatLng? mapCenter;
  bool loading = true;

  String? highlightedId;

  bool get useBlur => widget.mode != MapMode.upcoming;
  bool get showExactLocation => !useBlur;

  @override
  void initState() {
    super.initState();
    highlightedId = widget.highlightId;
    _fetchAndBuild();
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.mode != widget.mode ||
        oldWidget.highlightId != widget.highlightId) {
      setState(() {
        loading = true;
        markers.clear();
        inquiriesList.clear();
        selectedInquiry = null;
      });

      highlightedId = widget.highlightId;
      _fetchAndBuild();
      _resetMap();
    }
  }

  void _resetMap() {
    if (!mounted) return;
    if (mapCenter != null) {
      mapController.move(mapCenter!, 12);
    }
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

    /// 🔥 USER LOCATION (jak w profil screen)
    final areas = UserSession.profile?.serviceAreas;

    if (areas != null && areas.isNotEmpty) {
      final city = areas.first.city;

      if (city.isNotEmpty) {
        final center = await GeoService.getLatLngFromAddress(city);
        if (center != null) {
          mapCenter = center;
        }
      }
    }

    List<dynamic> data;

    if (widget.overrideInquiries != null) {
      data = widget.overrideInquiries!;
    } else {
      data = await ApiService().getInquiries(
        patientName: "",
        dateFrom: DateTime(now.year, now.month, now.day),
        dateTo: DateTime(now.year, now.month, now.day)
            .add(const Duration(days: 90)),
      );
    }

    inquiriesList = data.map((i) {
  /// 🔥 UPCOMING FORMAT
  if (i.containsKey('distance')) {
    final start = i['start'] as DateTime?;
    final end = i['end'] as DateTime?;

    return {
      'id': i['id'],
      'name': i['name'] ?? '',
      'startDate': start != null
          ? DateFormat('dd-MM-yyyy HH:mm').format(start)
          : '',
      'endDate': end != null
          ? DateFormat('dd-MM-yyyy HH:mm').format(end)
          : '',
      'description': i['service'] ?? '',
      'fullAddress': i['distance'] ?? '',

      'displayAddress': showExactLocation
          ? i['distance']
          : _shortAddress(i['distance'] ?? ''),
    };
  }

  /// 🔥 API FORMAT
  final id = (i['appointmentId'] ?? i['AppointmentId'])?.toString();

  final fullAddress =
      (i['patientAddress'] ?? i['PatientAddress'] ?? '').toString();

  final start = DateTime.tryParse(
    i['scheduledStart'] ?? i['ScheduledStart'] ?? '',
  );

  final end = DateTime.tryParse(
    i['scheduledEnd'] ?? i['ScheduledEnd'] ?? '',
  );

  return {
    'id': id ?? '',
    'name': i['patientName'] ?? '',
    'startDate': start != null
        ? DateFormat('dd-MM-yyyy HH:mm').format(start)
        : '',
    'endDate': end != null
        ? DateFormat('dd-MM-yyyy HH:mm').format(end)
        : '',
    'description': i['description'] ?? '',
    'fullAddress': fullAddress,

   
    'displayAddress': widget.mode == MapMode.upcoming
    ? AddressFormatter.full(fullAddress)
    : AddressFormatter.short(fullAddress),
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
    if (result != null) _addressCache[address] = result;

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
    final address = inquiry['fullAddress'];
    if (address == null || address.isEmpty) continue;

    final latLng = await _getCachedLatLng(address);
    if (latLng == null) continue;

    final point = useBlur
        ? _blur(latLng, inquiry['id'])
        : latLng;

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
            mapController.move(point, 15);

            // 🔥 ZAWSZE pokazuj szczegóły
            _showBottomSheet(inquiry);
          },
          child: _buildMarker(isHighlighted, exact: showExactLocation),
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

  /// auto open highlighted
  if (selectedInquiry != null) {
    Future.delayed(const Duration(milliseconds: 300), () {
      mapController.move(selectedInquiry!['latLng'], 15);
      _showBottomSheet(selectedInquiry!);
    });
  }
}

  Widget _buildMarker(bool highlight, {bool exact = false}) {
    return Container(
      decoration: BoxDecoration(
        color: exact
            ? Colors.green.withOpacity(0.25)
            : Colors.red.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: highlight ? 18 : 14,
          height: highlight ? 18 : 14,
          decoration: BoxDecoration(
            color: exact ? Colors.green : Colors.red,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ),
    );
  }

  void _showBottomSheet(Map<String, dynamic> item) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return FractionallySizedBox(
        widthFactor: 1,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(24, 20, 24, 40 + MediaQuery.of(context).padding.bottom,),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              Text(
                item['name'] ?? '',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(item['displayAddress'] ?? ''),

              const SizedBox(height: 8),

              Text(item['startDate'] ?? ''),
              Text(item['endDate'] ?? ''),

              const SizedBox(height: 12),

              Text(item['description'] ?? ''),

              const SizedBox(height: 24),
              if (widget.mode != MapMode.upcoming)
              Center(
                child: SizedBox(
                  width: 260,
                  height: 52,
                  child: ElevatedButton(
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
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  @override
  void dispose() {
    markers.clear();
    inquiriesList.clear();
    selectedInquiry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter:
                     mapCenter ?? const LatLng(52.2297, 21.0122),
                initialZoom: zoom,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName:
                      'com.healthforhome.marketplace_app',
                ),
                MarkerLayer(markers: markers),
              ],
            ),
    );
  }
}