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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.background,
            border: Border.all(color: AppColors.outline, width: 2),
            // Use placeholder as ImageUrl is not in DTO
            image: const DecorationImage(
              image: AssetImage('lib/images/logo.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: const Icon(Icons.person, size: 40, color: Colors.grey),
        ),
        if (specialist
            .isVerified) // isAvailable replaced by isVerified or logic? MockData had isAvailable. DTO has IsVerified.
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.blue, // Verified badge
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 2),
              ),
              child: const Icon(Icons.check, size: 10, color: Colors.white),
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
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.favorite_border, color: AppColors.secondary),
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
