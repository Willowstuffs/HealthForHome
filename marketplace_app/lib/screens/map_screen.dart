import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_theme.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        options: MapOptions(
          initialCenter: const LatLng(53.013790, 18.598444), // Toruń
          initialZoom: 13.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.healthforhome.marketplace_app',
          ),
          // Placeholder for specialist markers
          MarkerLayer(
            markers: [
              Marker(
                point: const LatLng(53.013790, 18.598444),
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
