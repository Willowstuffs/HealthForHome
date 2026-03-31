import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_theme.dart';

class MapScreen extends StatelessWidget {
  final LatLng? initialLocation;

  const MapScreen({super.key, this.initialLocation});

  @override
  Widget build(BuildContext context) {
    // Domyślna lokalizacja (Toruń)
    final LatLng center = initialLocation ?? const LatLng(53.013790, 18.598444);

    return Scaffold(
      body: FlutterMap(
        options: MapOptions(initialCenter: center, initialZoom: 13.0),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.healthforhome.marketplace_app',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: center,
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.location_on,
                  color: AppColors.primary,
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
