import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/appointment.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/appointment_card.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<Appointment> _allAppointments = [];
  final Map<DateTime, List<Appointment>> _appointmentsMap = {};
  bool _isLoading = true;

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
    _selectedDay = _focusedDay;
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

      final date = DateTime(
        appt.scheduledStart.year,
        appt.scheduledStart.month,
        appt.scheduledStart.day,
      );
      if (_appointmentsMap[date] == null) {
        _appointmentsMap[date] = [];
      }
      _appointmentsMap[date]!.add(appt);
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
                    'Kalendarz Wizyt',
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
            selectedColor: AppColors.primary.withValues(alpha: 0.15),
            checkmarkColor: AppColors.primary,
            backgroundColor: AppColors.surfaceContainerHighest,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            labelStyle: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
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
          firstDay: DateTime.now().subtract(const Duration(days: 365)),
          lastDay: DateTime.now().add(const Duration(days: 365)),
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
                'Wizyty w wybranym dniu',
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
                    'Brak wizyt w tym dniu.',
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
                return AppointmentCard(
                  appointment: selectedAppointments[index],
                );
              },
            ),
        ],
      ),
    );
  }
}
