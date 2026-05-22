import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

class UpcomingScreen extends StatefulWidget {
  final Function(Map<String, dynamic> appointment)? onOpenMap;
 const UpcomingScreen({
    super.key,
    this.onOpenMap,
  });

  @override
  State<UpcomingScreen> createState() => _UpcomingScreenState();
}


class _UpcomingScreenState extends State<UpcomingScreen> {
  List<Map<String, dynamic>> upcoming = [];
  List<Map<String, dynamic>> archive = [];
 // static const _ratingCooldownHours = 1;
  bool isLoading = true;
  final displayFormatter = DateFormat('dd.MM.yyyy HH:mm');
  final now = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  static const _confirmedCooldownMinutes = 10;
  
  final List<String> _availableStatuses = [
    'confirmed',
    'completed'
  ];

  final Set<String> _selectedStatuses = {
    'confirmed',
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

await Future.delayed(Duration.zero);

_checkForNewConfirmedVisit();
    } catch (e) {
      debugPrint('Błąd pobierania zapytań: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }
  Future<void> _checkForNewConfirmedVisit() async {
  final prefs = await SharedPreferences.getInstance();

  final lastShownMillis =
      prefs.getInt('last_confirmed_popup_time');

  if (lastShownMillis != null) {
    final diff = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(lastShownMillis),
    );

    if (diff.inMinutes < _confirmedCooldownMinutes) {
      debugPrint('⏳ Confirm popup cooldown aktywny');
      return;
    }
  }

  /// szukamy pierwszej confirmed wizyty
  final confirmedVisit = upcoming.firstWhere(
    (e) => e['status'] == 'confirmed',
    orElse: () => {},
  );

  if (confirmedVisit.isEmpty) return;

  /// czy popup już był dla tej wizyty
  final shownForId =
      prefs.getString('last_confirmed_popup_id');

  if (shownForId == confirmedVisit['id']) {
    return;
  }

  /// zapis BEFORE show (anti double popup)
  await prefs.setString(
    'last_confirmed_popup_id',
    confirmedVisit['id'],
  );

  await prefs.setInt(
    'last_confirmed_popup_time',
    DateTime.now().millisecondsSinceEpoch,
  );

  if (!mounted) return;

  Future.delayed(const Duration(milliseconds: 400), () {
    if (!mounted) return;
    _showConfirmedPopup(confirmedVisit);
  });
}
  List<Map<String, dynamic>> get _currentSource {
    return [...upcoming, ...archive];
  }

  List<Map<String, dynamic>> _mapInquiries(List<dynamic> data) {
    return data.map((i) {
      final id = i['appointmentId'] ?? i['AppointmentId'];
      DateTime? finalDate = DateTime.tryParse(i['finalDate'] ?? i['FinalDate'] ?? '');

      return {
        'id': id?.toString() ?? '',
        'name': i['patientName'] ?? i['PatientName'] ?? 'Nieznany pacjent',
        'finalDate': finalDate,
        'service': i['serviceName'] ?? i['ServiceName'] ?? 'Brak usługi',
        'distance': i['patientAddress'] ?? i['PatientAddress'] ?? '',
        'price': i['price'] ?? i['Price'] ?? '0.00',
        'status': i['status'] ?? i['Status'] ?? 'confirmed',
        'phoneNumber': i['phonenumber'] ?? i['Phonenumber'],
        'clientRating': i['clientRating'] ?? i['ClientRating'],
        'clientComment': i['clientRaatingNote'] ?? i['ClientRaatingNote'] ?? 'Brak opini', // Dodane dla spójności
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

  /// ===== LOGIKA SPRAWDZANIA POPUPU (1 na godzinę) =====
  // Future<void> _checkForUnratedVisit() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final lastShownMillis = prefs.getInt('last_rating_popup');

  //   if (lastShownMillis != null) {
  //     final lastShown = DateTime.fromMillisecondsSinceEpoch(lastShownMillis);
  //     final diff = DateTime.now().difference(lastShown);

  //     if (diff.inHours < _ratingCooldownHours) {
  //       debugPrint('⏳ Cooldown aktywny. Do następnego popupu zostało: ${_ratingCooldownHours * 60 - diff.inMinutes} minut.');
  //       return; // ❌ Za wcześnie, blokujemy wyskoczenie
  //     }
  //   }

  //   // Szukamy pierwszej nieocenionej wizyty w archiwum
  //   final unrated = archive.cast<Map<String, dynamic>?>().firstWhere(
  //     (e) =>
  //         e != null &&
  //         (e['clientRating'] == null ||
  //             e['clientRating'] == 'none' ||
  //             e['clientRating'] == ''),
  //     orElse: () => null,
  //   );

  //   if (unrated == null) {
  //     debugPrint('✅ Wszystkie wizyty z archiwum są już ocenione.');
  //     return; 
  //   }

  //   // 🔑 Zapisujemy czas natychmiast przed pokazaniem, aby kolejne wejście nie dublowało okna
  //   await prefs.setInt(
  //     'last_rating_popup',
  //     DateTime.now().millisecondsSinceEpoch,
  //   );

  //   if (!mounted) return;

  //   Future.delayed(const Duration(milliseconds: 400), () {
  //     if (!mounted) return;
  //     _showRatingPopup(unrated);
  //   });
  // }

  Future<void> _rateClient(
    String appointmentId,
    String rating,
    String comment,
  ) async {
    try {
      await ApiService().rateClient(
        appointmentId,
        rating,
        comment,
      );
      await _fetchData(); // Odświeżenie list z API
    } catch (e) {
      debugPrint("Błąd podczas oceniania: ${e.toString()}");
    }
  }

  void _updateUpcomingMap() {
    _upcomingMap.clear();
    for (var item in _currentSource) {
      final status = item['status'];
      final finalDate = item['finalDate'] as DateTime?;

      if (finalDate == null) continue;

      final day = DateTime(finalDate.year, finalDate.month, finalDate.day);

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
                    _buildStatusFilters(),
                    const SizedBox(height: 16),
                    _buildCalendar(),
                    const SizedBox(height: 16),
                    _buildSelectedDayAppointments(),
                    const SizedBox(height: 32),
                    _buildSectionHeader('Archiwum', Icons.history_rounded),
                    const SizedBox(height: 16),
                    _buildList(archive, isUpcoming: false),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCalendar() {
    return TableCalendar<Map<String, dynamic>>(
      locale: 'pl_PL', 
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
      availableCalendarFormats: const {
        CalendarFormat.month: 'Miesiąc',
      },
      calendarFormat: CalendarFormat.month,
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
    );
  }

  Widget _buildSelectedDayAppointments() {
    final items = _selectedDay != null ? _getEventsForDay(_selectedDay!) : [];

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
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: !isUpcoming 
          ? () => _showRatingPopup(item) 
          : null,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: AppColors.surfaceContainer, 
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.getStatusColor(item['status']).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _formatStatusLabel(item['status']),
                  style: TextStyle(
                    color: AppColors.getStatusColor(item['status']),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const Divider(height: 24),
              _buildInfoRow(Icons.access_time_rounded, item['finalDate'] != null ? displayFormatter.format(item['finalDate']) : ''),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.medical_services_outlined, item['service']),
              
              if (isUpcoming && item['distance'].isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildInfoRow(Icons.location_on_outlined, item['distance']),
                _buildInfoRow(Icons.medical_services_outlined, item['phoneNumber']),
              ],
              if (!isUpcoming) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      _ratingIcon(item['clientRating']),
                      color: _ratingColor(item['clientRating']),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatRating(item['clientRating']),
                      style: TextStyle(
                        color: _ratingColor(item['clientRating']),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
              if (isUpcoming) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // TODO: API cancel
                        },
                        child: const Text('Zrezygnuj'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          widget.onOpenMap?.call(item);
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
      ),
    );
  }

  Widget _buildStatusFilters() {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _availableStatuses.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final status = _availableStatuses[index];
          final isSelected = _selectedStatuses.contains(status);
          final statusColor = AppColors.getStatusColor(status);

          return FilterChip(
            label: Text(
              _formatStatusLabel(status),
              style: TextStyle(
                color: isSelected ? Colors.white : statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
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
            backgroundColor: statusColor.withValues(alpha: 0.12),
            selectedColor: statusColor,
            checkmarkColor: Colors.white,
            side: BorderSide(color: statusColor.withValues(alpha: 0.4)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          );
        },
      ),
    );
  }

  /// ===== BEZPIECZNY DIALOG Z POPRAWNYM CYKLEM ŻYCIA KONTROLERA =====
  void _showRatingPopup(Map<String, dynamic> visit) {
    String initialRating = visit['clientRating']?.toString() ?? '';
    if (initialRating == 'none') initialRating = '';

    final bool isReadOnly = initialRating.isNotEmpty;
    String selectedRating = initialRating;

    final formattedDate = visit['finalDate'] != null
        ? displayFormatter.format(visit['finalDate'])
        : '';

    showDialog(
      context: context,
      barrierDismissible: isReadOnly, 
      builder: (_) {
        // Inicjalizujemy kontroler wewnątrz builder'a okna dialogowego
        final dialogCommentController = TextEditingController(text: visit['clientComment'] ?? '');

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              scrollable: true,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isReadOnly ? "Podgląd oceny wizyty" : "Oceń wizytę",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 14),
                    _infoLine(icon: Icons.person_outline, label: "Pacjent", value: visit['name'], fontSize: 13),
                    _infoLine(icon: Icons.medical_services_outlined, label: "Usługa", value: visit['service'], fontSize: 13),
                    _infoLine(icon: Icons.calendar_today_outlined, label: "Data wizyty", value: formattedDate, fontSize: 13),
                    const SizedBox(height: 20),
                    Text(
                      isReadOnly ? "Twoja ocena klienta" : "Jak oceniasz klienta?",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 14),
                    IgnorePointer(
                      ignoring: isReadOnly,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ratingButton(icon: Icons.thumb_up, value: 'good', selected: selectedRating, onTap: (v) => setState(() => selectedRating = v)),
                          _ratingButton(icon: Icons.thumbs_up_down, value: 'neutral', selected: selectedRating, onTap: (v) => setState(() => selectedRating = v)),
                          _ratingButton(icon: Icons.thumb_down, value: 'bad', selected: selectedRating, onTap: (v) => setState(() => selectedRating = v)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    TextField(
                      controller: dialogCommentController,
                      maxLines: 3,
                      enabled: !isReadOnly,
                      style: TextStyle(fontSize: 14, color: isReadOnly ? Colors.black87 : null),
                      decoration: InputDecoration(
                        labelText: "Komentarz (opcjonalny)",
                        hintText: isReadOnly ? "Brak komentarza" : "Np. punktualny, dobry kontakt...",
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              actions: isReadOnly
                  ? [
                      TextButton(
                        onPressed: () => Navigator.pop(context), // Kontroler zostanie zniszczony automatycznie przy zamknięciu dialogu
                        child: const Text("Zamknij", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                    ]
                  : [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Pomiń", style: TextStyle(fontSize: 14)),
                      ),
                      ElevatedButton(
                        onPressed: selectedRating.isEmpty
                            ? null
                            : () async {
                                final navigator = Navigator.of(context);
                                await _rateClient(
                                  visit['id'],
                                  selectedRating,
                                  dialogCommentController.text,
                                );
                                navigator.pop();
                              },
                        child: const Text("Zapisz ocenę", style: TextStyle(fontSize: 14)),
                      ),
                    ],
            );
          },
        );
      },
    );
  }

  Widget _infoLine({required IconData icon, required String label, required String value, double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.black87, fontSize: fontSize),
                children: [
                  TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.w600)),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingButton({required IconData icon, required String value, required String selected, required Function(String) onTap}) {
    final isSelected = selected == value;
    Color getColor() {
      switch (value) {
        case 'good': return Colors.green;
        case 'neutral': return Colors.orange;
        case 'bad': return Colors.red;
        default: return Colors.grey;
      }
    }
    final color = getColor();

    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: 2),
        ),
        child: Icon(icon, size: 28, color: isSelected ? color : Colors.grey),
      ),
    );
  }
  void _showConfirmedPopup(Map<String, dynamic> visit) {
  final formattedDate = visit['finalDate'] != null
      ? displayFormatter.format(visit['finalDate'])
      : '';

  showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text("Wizyta potwierdzona"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoLine(
              icon: Icons.person_outline,
              label: "Pacjent",
              value: visit['name'],
            ),
            _infoLine(
              icon: Icons.calendar_today_outlined,
              label: "Termin",
              value: formattedDate,
            ),
            _infoLine(
              icon: Icons.medical_services_outlined,
              label: "Usługa",
              value: visit['service'],
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("OK"),
                ),
              ),
              const SizedBox(width: 5), // Odstęp między przyciskami
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon((Icons.location_on_outlined)),
                  label: const Text("mapa"),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onOpenMap?.call(visit);
                  },
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}

  IconData _ratingIcon(String? rating) {
    switch (rating) {
      case 'good': return Icons.thumb_up;
      case 'neutral': return Icons.thumbs_up_down;
      case 'bad': return Icons.thumb_down;
      default: return Icons.help_outline;
    }
  }

  Color _ratingColor(String? rating) {
    switch (rating) {
      case 'good': return Colors.green;
      case 'neutral': return Colors.orange;
      case 'bad': return Colors.red;
      default: return AppColors.textSecondary;
    }
  }

  String _formatRating(String? rating) {
    switch (rating) {
      case 'good': return 'Pozytywna';
      case 'neutral': return 'Neutralna';
      case 'bad': return 'Negatywna';
      case null:
      case '':
      case 'none': return 'Brak oceny';
      default: return rating;
    }
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