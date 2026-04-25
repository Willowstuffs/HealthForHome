import 'package:flutter/material.dart';
import 'package:specjalist_app/screens/main_screens/maintoolbar_screen.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class UpcomingScreen extends StatefulWidget {
  final Function(String inquiryId)? onOpenMap;
 const UpcomingScreen({
    super.key,
    this.onOpenMap,
  });

  @override
  State<UpcomingScreen> createState() => _UpcomingScreenState();
}

enum CalendarViewType {
  all,
  upcoming,
  archive,
}

CalendarViewType _calendarView = CalendarViewType.upcoming;

class _UpcomingScreenState extends State<UpcomingScreen> {
  List<Map<String, dynamic>> upcoming = [];
  List<Map<String, dynamic>> archive = [];
  bool isLoading = true;
  final displayFormatter = DateFormat('dd.MM.yyyy HH:mm');
  final now = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final List<String> _availableStatuses = [
  'confirmed',
  'cancelled',
  'completed'
];

final Set<String> _selectedStatuses = {
  'confirmed',
  'cancelled',
  'completed'
};
  Map<DateTime, List<Map<String, dynamic>>> _upcomingMap = {};
  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final fetchedUpcoming = await ApiService().getCommingInquiries(
        patientName: "",
        dateFrom: DateTime(now.year, now.month, now.day),
        dateTo: DateTime(now.year, now.month, now.day).add(const Duration(days: 30)),
      );
      final fetchedArchive = await ApiService().getArchiveInquiries();

      if (!mounted) return;

      setState(() {
        upcoming = _mapInquiries(fetchedUpcoming);
        archive = _mapInquiries(fetchedArchive);

        _updateUpcomingMap();

        isLoading = false;
      });
    } catch (e) {
      debugPrint('Błąd pobierania zapytań: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }
  List<Map<String, dynamic>> get _currentSource {
    switch (_calendarView) {
      case CalendarViewType.archive:
        return archive;
      case CalendarViewType.upcoming:
        return upcoming;
      case CalendarViewType.all:
        return [...upcoming, ...archive];
    }
  }
  List<Map<String, dynamic>> _mapInquiries(List<dynamic> data) {
    return data.map((i) {
      final id = i['appointmentId'] ?? i['AppointmentId'];
      DateTime? start = DateTime.tryParse(i['scheduledStart'] ?? i['ScheduledStart'] ?? '');
      DateTime? end = DateTime.tryParse(i['scheduledEnd'] ?? i['ScheduledEnd'] ?? '');

      return {
        'id': id?.toString() ?? '',
        'name': i['patientName'] ?? i['PatientName'] ?? 'Nieznany pacjent',

        // 🔥 TRZYMAMY PRAWDZIWE DATY
        'start': start,
        'end': end,

        'service': i['serviceName'] ?? i['ServiceName'] ?? 'Brak usługi',
        'distance': i['patientAddress'] ?? i['PatientAddress'] ?? '',
        'price': i['price'] ?? i['Price'] ?? '0.00',
        'status': i['status'] ?? i['Status'] ?? 'confirmed',
      };
    }).toList();
  }
  String _formatStatusLabel(String status) {
  switch (status) {
    case 'open': return 'Otwarte';
    case 'confirmed': return 'Potwierdzone';
    case 'cancelled': return 'Anulowane';
    case 'completed': return 'Zakończone';
    case 'pending': return 'Oczekujące';
    default: return status;
  }
}
  void _updateUpcomingMap() {
  _upcomingMap.clear();

  for (var item in _currentSource) {
    final status = item['status'];
    final start = item['start'] as DateTime?;

    if (start == null) continue;

    final day = DateTime(start.year, start.month, start.day);

    if (!_selectedStatuses.contains(status)) continue;

    _upcomingMap.putIfAbsent(day, () => []);
    _upcomingMap[day]!.add(item);
  }
}
  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _upcomingMap[date] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary)))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wizyty',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Nadchodzące', Icons.calendar_today_rounded),
                    const SizedBox(height: 16),
                    _buildCalendarTypeFilters(),
                    const SizedBox(height: 16),
                    _buildStatusFilters(),
                    const SizedBox(height: 16),
                    _buildCalendar(),
                    const SizedBox(height: 16),
                    _buildSelectedDayAppointments(),
                    const SizedBox(height: 32),
                    _buildSectionHeader('Archiwum', Icons.history_rounded),
                    const SizedBox(height: 16),
                    _buildList(archive, isUpcoming: false),
                    const SizedBox(height: 100), // Spacing dla BottomNav
                  ],
                ),
              ),
            ),
    );
  }
  Widget _buildCalendar() {
    return TableCalendar<Map<String, dynamic>>(
      firstDay: DateTime.now().subtract(const Duration(days: 365)),
      lastDay: DateTime.now().add(const Duration(days: 365)),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      eventLoader: _getEventsForDay,
      startingDayOfWeek: StartingDayOfWeek.monday,
    );
  }
  Widget _buildSelectedDayAppointments() {
    final items =
        _selectedDay != null ? _getEventsForDay(_selectedDay!) : [];

    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text("Brak wizyt w tym dniu"),
      );
    }

    return Column(
      children: items
          .map((item) {
            final isUpcoming = upcoming.contains(item);
            return _buildInquiryCard(item, isUpcoming);
          })
          .toList(),
    );
  }
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items, {required bool isUpcoming}) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Text(
          'Brak wizyt w tej sekcji',
          style: TextStyle(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: items.map((item) => _buildInquiryCard(item, isUpcoming)).toList(),
    );
  }

  Widget _buildInquiryCard(Map<String, dynamic> item, bool isUpcoming) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      // Używamy koloru z AppTheme (surfaceContainer) dla czystego wyglądu
      color: AppColors.surfaceContainer, 
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.5),),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item['name'],
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (isUpcoming)
                  Text(
                    '${item['price']} zł',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.access_time_rounded, '${item['start']} - ${item['end']}'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.medical_services_outlined, item['service']),
            if (isUpcoming && item['distance'].isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.location_on_outlined, item['distance']),
            ],
            if (isUpcoming) ...[
            const SizedBox(height: 20),

            Row(
              children: [
                // ❌ ZREZYGNUJ
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: API cancel
                    },
                    child: const Text('Zrezygnuj'),
                  ),
                ),

                const SizedBox(width: 12),

                // 🗺 MAPA
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MainScreen(
                            startIndex: 2,
                            highlightAppointmentId: item['id'],
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.location_on_outlined),
                    label: const Text('Mapa'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}
  Widget _buildStatusFilters() {
  return SizedBox(
    height: 50,
    child: ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      scrollDirection: Axis.horizontal,
      itemCount: _availableStatuses.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final status = _availableStatuses[index];
        final isSelected = _selectedStatuses.contains(status);

        return FilterChip(
          label: Text(_formatStatusLabel(status)),
          selected: isSelected,
          onSelected: (_) {
            setState(() {
              if (isSelected) {
                _selectedStatuses.remove(status);
              } else {
                _selectedStatuses.add(status);
              }
              _updateUpcomingMap();
            });
          },
          selectedColor: AppColors.primary.withValues(alpha: 0.15),
          backgroundColor: AppColors.surfaceContainerHighest,
        );
      },
    ),
  );
}
Widget _buildCalendarTypeFilters() {
  return Row(
    children: [
      ChoiceChip(
        label: const Text("Wszystkie"),
        selected: _calendarView == CalendarViewType.all,
        onSelected: (_) {
          setState(() {
            _calendarView = CalendarViewType.all;
            _updateUpcomingMap();
          });
        },
      ),
      const SizedBox(width: 8),
      ChoiceChip(
        label: const Text("Nadchodzące"),
        selected: _calendarView == CalendarViewType.upcoming,
        onSelected: (_) {
          setState(() {
            _calendarView = CalendarViewType.upcoming;
            _updateUpcomingMap();
          });
        },
      ),
      const SizedBox(width: 8),
      ChoiceChip(
        label: const Text("Archiwum"),
        selected: _calendarView == CalendarViewType.archive,
        onSelected: (_) {
          setState(() {
            _calendarView = CalendarViewType.archive;
            _updateUpcomingMap();
          });
        },
      ),
    ],
  );
}
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurface.withValues(alpha: 0.5),
                ),
          ),
        ),
      ],
    );
  }
}