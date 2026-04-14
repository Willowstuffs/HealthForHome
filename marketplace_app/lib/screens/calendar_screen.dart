import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/appointment.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/appointment_card.dart';

class CalendarScreen extends StatefulWidget {
  final String? initialEventId;
  final DateTime? initialDate;

  const CalendarScreen({
    super.key,
    this.initialEventId,
    this.initialDate,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<Appointment> _allAppointments = [];
  final Map<DateTime, List<Appointment>> _appointmentsMap = {};
  bool _isLoading = true;
  bool _hasOpenedInitialEvent = false;

  final List<String> _availableStatuses = [
    'open',
    'confirmed',
    'cancelled',
    'completed',
    'pending',
  ];
  final Set<String> _selectedStatuses = {
    'open',
    'confirmed',
    'cancelled',
    'completed',
    'pending',
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) {
      _focusedDay = widget.initialDate!;
      _selectedDay = _focusedDay;
    } else {
      _selectedDay = _focusedDay;
    }
    _fetchAppointments();
  }

  void _fetchAppointments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final list = await ApiService().getAppointments(page: 1, pageSize: 100);
      _allAppointments = list;
      _updateAppointmentsMap();
    } catch (e) {
      debugPrint('Error fetching appointments: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (widget.initialEventId != null && !_hasOpenedInitialEvent) {
          _hasOpenedInitialEvent = true;
          final apptIndex = _allAppointments.indexWhere(
            (a) => a.id == widget.initialEventId,
          );
          if (apptIndex != -1) {
            final appt = _allAppointments[apptIndex];
            setState(() {
              _selectedDay = DateTime(
                appt.scheduledStart.year,
                appt.scheduledStart.month,
                appt.scheduledStart.day,
              );
              _focusedDay = _selectedDay!;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showAppointmentDetails(context, appt);
            });
          }
        }
      }
    }
  }

  void _updateAppointmentsMap() {
    _appointmentsMap.clear();
    for (var appt in _allAppointments) {
      // filter by status
      final status = appt.appointmentStatus;

      // if filtering, only add if the selected statuses contain the status
      if (!_selectedStatuses.contains(status)) {
        continue;
      }

      final start = DateTime(
        appt.scheduledStart.year,
        appt.scheduledStart.month,
        appt.scheduledStart.day,
      );
      final end = DateTime(
        appt.scheduledEnd.year,
        appt.scheduledEnd.month,
        appt.scheduledEnd.day,
      );

      // add appointment for every day between start and end inclusive
      for (
        var d = start;
        d.isBefore(end.add(const Duration(days: 1)));
        d = d.add(const Duration(days: 1))
      ) {
        if (_appointmentsMap[d] == null) {
          _appointmentsMap[d] = [];
        }
        _appointmentsMap[d]!.add(appt);
      }
    }
  }

  List<Appointment> _getEventsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _appointmentsMap[date] ?? [];
  }

  void _toggleStatus(String status) {
    setState(() {
      if (_selectedStatuses.contains(status)) {
        _selectedStatuses.remove(status);
      } else {
        _selectedStatuses.add(status);
      }
      _updateAppointmentsMap();
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    left: 24.0,
                    top: 16.0,
                    right: 24.0,
                    bottom: 8.0,
                  ),
                  child: Text(
                    'Kalendarz',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                _buildStatusFilters(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildCalendar(),
                        SizedBox(height: 16),
                        _buildAppointmentList(),
                        SizedBox(height: 100), // spacing for bottom nav
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatusFilters() {
    return Container(
      height: 50,
      margin: EdgeInsets.only(bottom: 16),
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: _availableStatuses.length,
        separatorBuilder: (context, index) => SizedBox(width: 8),
        itemBuilder: (context, index) {
          final status = _availableStatuses[index];
          final isSelected = _selectedStatuses.contains(status);
          return FilterChip(
            label: Text(_formatStatusLabel(status)),
            selected: isSelected,
            onSelected: (_) => _toggleStatus(status),
            selectedColor: AppColors.getStatusColor(status).withValues(alpha: 0.15),
            checkmarkColor: AppColors.getStatusColor(status),
            backgroundColor: AppColors.surfaceContainerHighest,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            labelStyle: TextStyle(
              color: isSelected ? AppColors.getStatusColor(status) : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalendar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(8),
        child: TableCalendar<Appointment>(
          firstDay: DateTime.now().subtract(Duration(days: 365)),
          lastDay: DateTime.now().add(Duration(days: 365)),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            if (!isSameDay(_selectedDay, selectedDay)) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            }
          },
          eventLoader: _getEventsForDay,
          startingDayOfWeek: StartingDayOfWeek.monday,
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
            leftChevronIcon: Icon(
              Icons.chevron_left_rounded,
              color: AppColors.onSurface,
            ),
            rightChevronIcon: Icon(
              Icons.chevron_right_rounded,
              color: AppColors.onSurface,
            ),
          ),
          calendarStyle: CalendarStyle(
            markersMaxCount: 3,
            markerDecoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            todayTextStyle: TextStyle(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
            defaultTextStyle: TextStyle(color: AppColors.onSurface),
            weekendTextStyle: TextStyle(color: AppColors.error),
            outsideTextStyle: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            weekendStyle: TextStyle(
              color: AppColors.error.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentList() {
    final selectedAppointments = _selectedDay != null
        ? _getEventsForDay(_selectedDay!)
        : [];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.list_alt_rounded,
                  color: AppColors.accent,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Ogłoszenia w wybranym dniu',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (selectedAppointments.isEmpty)
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Brak ogłoszeń w tym dniu.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          if (selectedAppointments.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: selectedAppointments.length,
              separatorBuilder: (context, index) => SizedBox(height: 12),
              itemBuilder: (context, index) {
                final appt = selectedAppointments[index];
                return AppointmentCard(
                  appointment: appt,
                  onTap: () => _showAppointmentDetails(context, appt),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showAppointmentDetails(BuildContext context, Appointment appt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Szczegóły ogłoszenia',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              SizedBox(height: 24),
              _buildDetailRow(
                Icons.person,
                'Specjalista:',
                appt.specialistName ?? 'Brak danych',
              ),
              _buildDetailRow(
                Icons.medical_services,
                'Usługa:',
                appt.serviceName ?? 'Brak danych',
              ),
              _buildDetailRow(
                Icons.info_outline,
                'Status:',
                _formatStatusLabel(appt.appointmentStatus),
              ),
              _buildDetailRow(
                Icons.calendar_today,
                'Termin:',
                appt.scheduledStart.year == appt.scheduledEnd.year &&
                        appt.scheduledStart.month == appt.scheduledEnd.month &&
                        appt.scheduledStart.day == appt.scheduledEnd.day
                    ? '${appt.scheduledStart.day.toString().padLeft(2, '0')}.${appt.scheduledStart.month.toString().padLeft(2, '0')}.${appt.scheduledStart.year}  '
                          '${appt.scheduledStart.hour.toString().padLeft(2, '0')}:${appt.scheduledStart.minute.toString().padLeft(2, '0')} - '
                          '${appt.scheduledEnd.hour.toString().padLeft(2, '0')}:${appt.scheduledEnd.minute.toString().padLeft(2, '0')}'
                    : 'Początek: ${appt.scheduledStart.day.toString().padLeft(2, '0')}.${appt.scheduledStart.month.toString().padLeft(2, '0')}.${appt.scheduledStart.year} '
                          '${appt.scheduledStart.hour.toString().padLeft(2, '0')}:${appt.scheduledStart.minute.toString().padLeft(2, '0')}\n'
                          'Koniec: ${appt.scheduledEnd.day.toString().padLeft(2, '0')}.${appt.scheduledEnd.month.toString().padLeft(2, '0')}.${appt.scheduledEnd.year} '
                          '${appt.scheduledEnd.hour.toString().padLeft(2, '0')}:${appt.scheduledEnd.minute.toString().padLeft(2, '0')}',
              ),
              if (appt.clientAddress != null && appt.clientAddress!.isNotEmpty)
                _buildDetailRow(
                  Icons.location_on,
                  'Adres:',
                  appt.clientAddress!,
                ),
              if (appt.totalPrice != null)
                _buildDetailRow(
                  Icons.attach_money,
                  'Cena:',
                  '${appt.totalPrice!.toStringAsFixed(2)} PLN',
                ),
              if (appt.clientNotes != null && appt.clientNotes!.isNotEmpty)
                _buildDetailRow(
                  Icons.note,
                  'Twoje notatki:',
                  appt.clientNotes!,
                ),
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Zamknij',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
