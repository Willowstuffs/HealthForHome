import 'package:flutter/material.dart';
import '../models/specialist.dart';
import '../theme/app_theme.dart';

class SpecialistCard extends StatelessWidget {
  final Specialist specialist;
  final VoidCallback onTap;

  const SpecialistCard({
    super.key,
    required this.specialist,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(),
                const SizedBox(width: 16),
                Expanded(child: _buildSpecialistInfo()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.livingColor20,
                AppColors.livingColor30,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(Icons.person, size: 32, color: AppColors.primary),
        ),
        if (specialist.isVerified)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 3),
              ),
              child: const Icon(Icons.check, size: 12, color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildSpecialistInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                specialist.fullName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                  letterSpacing: 0.1,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.favorite_border, size: 18, color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          specialist.professionalTitle ?? 'Specjalista',
          style: const TextStyle(color: AppColors.secondary),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 16),
            const SizedBox(width: 4),
            Text(
              '${specialist.averageRating} (${specialist.totalReviews})',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(width: 16),
            // dist might be null
            if (specialist.distance != null) ...[
              const Icon(
                Icons.location_on,
                color: AppColors.secondary,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${specialist.distance} km',
                style: const TextStyle(color: AppColors.onSurface),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: specialist.services
              .take(2)
              .map(
                (service) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    service.serviceName,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
