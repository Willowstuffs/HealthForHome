import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../theme/app_theme.dart';

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback? onTap;

  const AppointmentCard({super.key, required this.appointment, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _buildLeftIcon(),
                const SizedBox(width: 16),
                Expanded(child: _buildMiddleContent()),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeftIcon() {
    if (appointment.appointmentStatus == 'pending') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.group_add_rounded,
          color: AppColors.primary,
          size: 28,
        ),
      );
    } else if (appointment.appointmentStatus == 'open' ||
        appointment.appointmentStatus == 'cancelled') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.assignment_rounded,
          color: AppColors.primary,
          size: 28,
        ),
      );
    } else {
      // confirmed, completed
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.livingColor80,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.livingColor20.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              (appointment.finalDate ?? appointment.scheduledStart).day
                  .toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            Text(
              _getMonthName(
                (appointment.finalDate ?? appointment.scheduledStart).month,
              ),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildMiddleContent() {
    final title = appointment.serviceNames?.isEmpty ?? true
        ? 'Wizyta domowa'
        : appointment.serviceNames!.join(', ');

    if (appointment.appointmentStatus == 'pending') {
      final desc = appointment.clientNotes ?? '';
      final truncatedDesc = desc.length > 30
          ? '${desc.substring(0, 30)}...'
          : desc;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          if (truncatedDesc.isNotEmpty) ...[
            Text(
              truncatedDesc,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
          ],
          _buildStatusChip(),
        ],
      );
    } else if (appointment.appointmentStatus == 'open' ||
        appointment.appointmentStatus == 'cancelled') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          _buildStatusChip(),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.date_range_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                '${appointment.scheduledStart.day.toString().padLeft(2, '0')}.${appointment.scheduledStart.month.toString().padLeft(2, '0')} - ${appointment.scheduledEnd.day.toString().padLeft(2, '0')}.${appointment.scheduledEnd.month.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      // confirmed, completed, cancelled
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appointment.specialistName ?? 'Specjalista',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          _buildStatusChip(),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                appointment.finalDate != null
                    ? _formatTime(appointment.finalDate!)
                    : (appointment.scheduledStart.year ==
                                  appointment.scheduledEnd.year &&
                              appointment.scheduledStart.month ==
                                  appointment.scheduledEnd.month &&
                              appointment.scheduledStart.day ==
                                  appointment.scheduledEnd.day
                          ? '${_formatTime(appointment.scheduledStart)} - ${_formatTime(appointment.scheduledEnd)}'
                          : '${_formatDateTime(appointment.scheduledStart)} - ${_formatDateTime(appointment.scheduledEnd)}'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildStatusChip() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.getStatusColor(
              appointment.appointmentStatus,
            ).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _formatStatusLabel(appointment.appointmentStatus),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.getStatusColor(appointment.appointmentStatus),
            ),
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'STY',
      'LUT',
      'MAR',
      'KWI',
      'MAJ',
      'CZE',
      'LIP',
      'SIE',
      'WRZ',
      'PAŹ',
      'LIS',
      'GRU',
    ];
    return months[month - 1];
  }

  String _formatStatusLabel(String status) {
    switch (status) {
      case 'open':
        return 'Otwarte';
      case 'confirmed':
        return 'Potwierdzone';
      case 'cancelled':
        return 'Anulowane';
      case 'completed':
        return 'Zakończone';
      case 'pending':
        return 'Oczekujące';
      default:
        return status;
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')} ${_formatTime(date)}';
  }
}
