import 'package:flutter/material.dart';
import 'package:marketplace_app/theme/app_theme.dart';
import 'package:marketplace_app/models/nearby_specialist.dart';

class SpecialistCard extends StatelessWidget {
  final NearbySpecialist specialist;
  final VoidCallback onTap;

  const SpecialistCard({
    super.key,
    required this.specialist,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2), width: 1.0),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                  child: ClipOval(
                    child: specialist.avatarUrl != null && specialist.avatarUrl!.isNotEmpty
                        ? Image.network(specialist.avatarUrl!, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.person, size: 32, color: AppColors.onPrimary))
                        : const Icon(Icons.person, size: 32, color: AppColors.onPrimary),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        specialist.fullName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        specialist.serviceArea,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: (specialist.serviceNames.take(3)).map((s) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(color: AppColors.textSecondary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                              child: Text(s, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                            )).toList(),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
