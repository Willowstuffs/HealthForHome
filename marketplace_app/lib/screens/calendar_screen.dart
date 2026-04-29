import 'package:flutter/material.dart';
import 'package:marketplace_app/widgets/screen_status_bar.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/appointment.dart';
import '../../models/review.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/appointment_card.dart';

class CalendarScreen extends StatefulWidget {
  final String? initialEventId;
  final DateTime? initialDate;

  const CalendarScreen({super.key, this.initialEventId, this.initialDate});

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
              final dateToUse = appt.finalDate ?? appt.scheduledStart;
              _selectedDay = DateTime(
                dateToUse.year,
                dateToUse.month,
                dateToUse.day,
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
      final finalDay = appt.finalDate != null
          ? DateTime(
              appt.finalDate!.year,
              appt.finalDate!.month,
              appt.finalDate!.day,
            )
          : null;

      // add appointment for every day between start and end inclusive
      // if appointment is confirmed/completed, add it only for the final day
      if (appt.appointmentStatus == 'confirmed' ||
          appt.appointmentStatus == 'completed') {
        if (finalDay != null) {
          if (_appointmentsMap[finalDay] == null) {
            _appointmentsMap[finalDay] = [];
          }
          _appointmentsMap[finalDay]!.add(appt);
        } else {
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
      } else if (appt.appointmentStatus == 'cancelled') {
        if (_appointmentsMap[start] == null) {
          _appointmentsMap[start] = [];
        }
        _appointmentsMap[start]!.add(appt);
      } else {
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
    return ScreenStatusBar(
      child: Scaffold(
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
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
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
                          SizedBox(height: 32),
                          _buildAppointmentList(),
                          SizedBox(height: 32), // spacing for bottom nav
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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
            selectedColor: AppColors.getStatusColor(
              status,
            ).withValues(alpha: 0.15),
            checkmarkColor: AppColors.getStatusColor(status),
            backgroundColor: AppColors.surfaceContainerHighest,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            labelStyle: TextStyle(
              color: isSelected
                  ? AppColors.getStatusColor(status)
                  : AppColors.textSecondary,
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
              if (appt.appointmentStatus != 'cancelled' &&
                  appt.appointmentStatus != 'open' &&
                  appt.appointmentStatus != 'pending')
                _buildDetailRow(
                  Icons.person,
                  'Specjalista:',
                  appt.specialistName ?? 'Brak danych',
                ),
              if (appt.appointmentStatus != 'cancelled' &&
                  appt.appointmentStatus != 'open')
                _buildDetailRow(
                  Icons.medical_services,
                  'Usługa:',
                  appt.serviceNames?.isEmpty ?? true
                      ? 'Brak danych'
                      : appt.serviceNames!.join(', '),
                ),
              if (appt.appointmentStatus == 'pending')
                FutureBuilder<List<AppointmentOffer>>(
                  future: ApiService().getAppointmentOffers(appt.id),
                  builder: (context, snapshot) {
                    final offersCount = snapshot.data?.length ?? 0;
                    return _buildDetailRow(
                      Icons.local_offer_rounded,
                      'Otrzymane oferty:',
                      snapshot.connectionState == ConnectionState.waiting
                          ? 'Ładowanie...'
                          : '$offersCount',
                    );
                  },
                ),
              _buildDetailRow(
                Icons.info_outline,
                'Status:',
                _formatStatusLabel(appt.appointmentStatus),
              ),
              _buildDetailRow(
                Icons.calendar_today,
                'Termin:',
                appt.finalDate != null
                    ? '${appt.finalDate!.day.toString().padLeft(2, '0')}.${appt.finalDate!.month.toString().padLeft(2, '0')}.${appt.finalDate!.year}  ${appt.finalDate!.hour.toString().padLeft(2, '0')}:${appt.finalDate!.minute.toString().padLeft(2, '0')}'
                    : (appt.scheduledStart.year == appt.scheduledEnd.year &&
                              appt.scheduledStart.month ==
                                  appt.scheduledEnd.month &&
                              appt.scheduledStart.day == appt.scheduledEnd.day
                          ? '${appt.scheduledStart.day.toString().padLeft(2, '0')}.${appt.scheduledStart.month.toString().padLeft(2, '0')}.${appt.scheduledStart.year}  '
                                '${appt.scheduledStart.hour.toString().padLeft(2, '0')}:${appt.scheduledStart.minute.toString().padLeft(2, '0')} - '
                                '${appt.scheduledEnd.hour.toString().padLeft(2, '0')}:${appt.scheduledEnd.minute.toString().padLeft(2, '0')}'
                          : 'Początek: ${appt.scheduledStart.day.toString().padLeft(2, '0')}.${appt.scheduledStart.month.toString().padLeft(2, '0')}.${appt.scheduledStart.year} '
                                '${appt.scheduledStart.hour.toString().padLeft(2, '0')}:${appt.scheduledStart.minute.toString().padLeft(2, '0')}\n'
                                'Koniec: ${appt.scheduledEnd.day.toString().padLeft(2, '0')}.${appt.scheduledEnd.month.toString().padLeft(2, '0')}.${appt.scheduledEnd.year} '
                                '${appt.scheduledEnd.hour.toString().padLeft(2, '0')}:${appt.scheduledEnd.minute.toString().padLeft(2, '0')}'),
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
                  isLongText: true,
                ),
              SizedBox(height: 32),
              if (appt.appointmentStatus == 'completed') ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      if (!appt.isRated) {
                        _showRatingDialog(context, appt.id);
                      } else {
                        _showReviewDialog(context, appt.id);
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: !appt.isRated
                          ? AppColors.accent
                          : AppColors.surfaceContainerHighest,
                      foregroundColor: !appt.isRated
                          ? Colors.white
                          : AppColors.primary,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      !appt.isRated ? 'Oceń wizytę' : 'Wyświetl opinię',
                      style: !appt.isRated
                          ? TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            )
                          : TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.onSurface.withValues(
                                alpha: 0.75,
                              ),
                            ),
                    ),
                  ),
                ),
                SizedBox(height: 12),
              ],
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

  Widget _buildDetailRow(
    IconData icon,
    String title,
    String value, {
    bool isLongText = false,
  }) {
    Widget textWidget = Text(
      value,
      style: TextStyle(
        color: AppColors.onSurface,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
    );

    if (isLongText) {
      textWidget = Container(
        constraints: BoxConstraints(maxHeight: 100),
        child: RawScrollbar(
          thumbVisibility: true,
          thumbColor: AppColors.primary.withValues(alpha: 0.5),
          radius: Radius.circular(4),
          thickness: 4,
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: textWidget,
            ),
          ),
        ),
      );
    }

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
                textWidget,
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(BuildContext context, String appointmentId) {
    int rating = 0;
    final TextEditingController commentController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Oceń wizytę',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Jak oceniasz wykonaną usługę?',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          onPressed: () {
                            setLocalState(() {
                              rating = index + 1;
                            });
                          },
                          icon: Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 36,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Dodaj komentarz (opcjonalnie)',
                        filled: true,
                        fillColor: AppColors.surfaceContainer,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isSubmitting
                              ? null
                              : () => Navigator.pop(context),
                          child: const Text(
                            'Anuluj',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: rating == 0 || isSubmitting
                              ? null
                              : () async {
                                  setLocalState(() => isSubmitting = true);
                                  try {
                                    await ApiService().rateSpecialist(
                                      appointmentId,
                                      rating,
                                      commentController.text,
                                    );
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Dziękujemy za opinię!',
                                          ),
                                        ),
                                      );
                                      _fetchAppointments();
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text('Błąd: $e')),
                                      );
                                      setLocalState(() => isSubmitting = false);
                                    }
                                  }
                                },
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Oceń'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showReviewDialog(BuildContext context, String appointmentId) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: AppColors.surface,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: FutureBuilder<Review>(
              future: ApiService().getReview(appointmentId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 150,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Wystąpił błąd',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Zamknij'),
                      ),
                    ],
                  );
                }

                final review = snapshot.data!;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Wystawiona opinia',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return Icon(
                          index < review.rating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 36,
                        );
                      }),
                    ),
                    if (review.comment != null &&
                        review.comment!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          review.comment!,
                          style: TextStyle(color: AppColors.onSurface),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Zamknij',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
