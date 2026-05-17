import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:specjalist_app/services/user_profile.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';
import '../offer_from_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/notification_services.dart';
import '../../services/app_refresh_service.dart';
import '../../services/address_formatter.dart';
import 'package:specjalist_app/screens/main_screens/maintoolbar_screen.dart';

class StartScreen extends StatefulWidget {
  final String? highlightAppointmentId;

  const StartScreen({
    super.key,
    this.highlightAppointmentId,
  });

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  List<Map<String, dynamic>> inquiries = [];
  final Set<String> _readIds = {};
  bool isLoading = true;
  String? highlightedId;
  String get firstName => UserSession.firstName ?? '';
  final now = DateTime.now();
 @override
  void initState() {
    super.initState();
    _initializeData(); 
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadServices(); // zawsze sprawdzaj usługi
  }

  Future<void> _initializeData() async {
    await _loadProfile();   
    await _loadServices();
    await _loadReadStatus(); 
    await _initializeNotifications();
    await _fetchData(); 

    AppRefreshService().stream.listen((_) => _fetchData());
  }
  Future<void> _loadServices() async {
  try {
    final result = await ApiService().getServices();
    UserSession.services = result;
  } catch (e) {
    debugPrint("Services load error: $e");
  }
}

void _goToProfileFix() {
  final hasCity = UserSession.profile?.serviceAreas?.any(
        (a) => a.city.trim().isNotEmpty,
      ) ??
      false;

  final hasService = UserSession.services.isNotEmpty;

  int targetIndex;

  if (!hasService) {
    targetIndex = 1; // 👉 zakładka USŁUGI
  } else if (!hasCity) {
    targetIndex = 4; // 👉 PROFIL / LOKALIZACJA
  } else {
    return;
  }

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => MainScreen(startIndex: targetIndex),
    ),
  );
}
 bool get _hasValidProfile {
  final hasCity = UserSession.profile?.serviceAreas?.any(
        (a) => a.city.trim().isNotEmpty,
      ) ??
      false;

  final hasService = UserSession.services.isNotEmpty;

  return hasCity && hasService;
}
Future<void> _loadProfile() async {
    try {
      final profileJson = await ApiService().getProfile();
      UserSession.setProfileFromApi(profileJson, UserSession.token ?? '');


      
    } catch (e) {
      debugPrint("Profile/Firebase load error: $e");
    }
  }
 Future<void> _loadReadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedIds = prefs.getStringList('read_appointments');
    if (savedIds != null) {
      setState(() {
        _readIds.addAll(savedIds);
      });
    }
  }
  Future<void> markAsRead(String id) async {
    if (!mounted) return;

    setState(() {
      _readIds.add(id);
      final index = inquiries.indexWhere((i) => i['id'] == id);
      if (index != -1) {
        inquiries[index]['isNew'] = false;
      }
      
      
      inquiries.sort((a, b) {
        if (a['isNew'] == b['isNew']) return 0;
        return a['isNew'] ? -1 : 1;
      });
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('read_appointments', _readIds.toList());
  }
  Future<void> _initializeNotifications() async {
    await NotificationService().requestPermissionsAndToken();
    
    await NotificationService().uploadTokenToServer();
  }
Future<void> _fetchData() async {
  if (!_hasValidProfile) {
    setState(() {
      inquiries = [];
      isLoading = false;
    });
    return;
  }

  try {
    final fetchedInquiries = await ApiService().getInquiries(
      patientName: "",
      dateFrom: DateTime(now.year, now.month, now.day),
      dateTo: DateTime(now.year, now.month, now.day)
          .add(const Duration(days: 90)),
    );

    final formatter = DateFormat('dd-MM-yyyy HH:mm');

    final List<Map<String, dynamic>> processed = [];

    for (final i in fetchedInquiries) {
      final id = (i['appointmentId'] ?? i['AppointmentId'])?.toString();
      final clientId = (i['clientId'] ?? i['ClientId'])?.toString();

      final start = DateTime.tryParse(
        i['scheduledStart'] ?? i['ScheduledStart'] ?? '',
      );

      final end = DateTime.tryParse(
        i['scheduledEnd'] ?? i['ScheduledEnd'] ?? '',
      );

      final rawAddress = i['patientAddress'] ?? i['PatientAddress'] ?? '';
      final address = AddressFormatter.short(rawAddress);

      final apiIsRead = i['isRead'] == true || i['IsRead'] == true;
      final isNew = !apiIsRead && !_readIds.contains(id);

      dynamic reviewsRaw = i['reviews'] ?? i['Reviews'];

// Jeśli to String, zdekoduj go
      if (reviewsRaw is String) {
        reviewsRaw = jsonDecode(reviewsRaw);
      }
      debugPrint("TYPE: ${reviewsRaw.runtimeType}");
debugPrint("VALUE: $reviewsRaw");
      // Mapujemy na ustandaryzowany format małych liter, aby uniknąć problemów w widgetach
      Map<String, int> cleanReviews = {
        'goodCount': (reviewsRaw?['GoodCount'] ?? reviewsRaw?['goodCount'] ?? 0) as int,
        'neutralCount': (reviewsRaw?['NeutralCount'] ?? reviewsRaw?['neutralCount'] ?? 0) as int,
        'badCount': (reviewsRaw?['BadCount'] ?? reviewsRaw?['badCount'] ?? 0) as int,
      };

      processed.add({
        'id': id ?? '',
        'clientId': clientId,
        'name': i['patientName'] ?? i['PatientName'] ?? '',
        'startDate': start != null ? formatter.format(start) : '',
        'endDate': end != null ? formatter.format(end) : '',
        'service': i['serviceName'] ?? i['ServiceName'] ?? '',
        'address': address,
        'description': i['description'] ?? i['Description'] ?? '',
        'distanceKm': i['distanceKm'],
        'isNew': isNew,

        // 🔥 NAJWAŻNIEJSZE — STATYSTYKI Z API
        'reviews': cleanReviews,
      });
    }

    setState(() {
      inquiries = processed;
      isLoading = false;
    });

    // DEBUG całej listy
    debugPrint("📦 PROCESSED INQUIRIES:");
    for (final p in processed) {
      debugPrint("${p['clientId']} => ${p['reviews']}");
    }

  } catch (e) {
    debugPrint('❌ Błąd pobierania zapytań: $e');
    if (mounted) setState(() => isLoading = false);
  }
}

@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
  child: isLoading
      ? const Center(child: CircularProgressIndicator())
      : !_hasValidProfile
          ? _buildIncompleteProfileInfo()
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildSectionTitle(
                        'Nowe zapytania',
                        Icons.notifications_active_outlined),
                    const SizedBox(height: 16),
                    _buildInquiriesList(),
                  ],
                ),
              ),
            ),
),
    );
  }
  Widget _buildDebugInfo() {
  final cities = UserSession.profile?.serviceAreas ?? [];
  final specs = UserSession.profile?.specializations ?? [];

  return Container(
    padding: const EdgeInsets.all(12),
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.black12,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("DEBUG PROFIL", style: TextStyle(fontWeight: FontWeight.bold)),
        Text("Miasta: ${cities.map((e) => e.city).join(', ')}"),
        Text("Usługi: ${specs.join(', ')}"),
      ],
    ),
  );
}
  Widget _buildIncompleteProfileInfo() {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline,
                size: 56, color: AppColors.primary),

            const SizedBox(height: 20),

            Text(
              "Uzupełnij profil, aby otrzymywać oferty",
              
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          _buildDebugInfo(),
            const SizedBox(height: 12),

            Text(
              "Dodaj przynajmniej jedną usługę oraz ustaw miejsce pracy (miasto). Bez tego zapytania nie będą wyświetlane.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _goToProfileFix,
                child: const Text("Uzupełnij profil"),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
Widget _buildHeader() {
   final newCount = inquiries.where((i) => i['isNew'] == true).length;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceContainerHighest,
            AppColors.surfaceContainerHighest.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dzień dobry,',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  firstName.isNotEmpty ? firstName : 'Specjalisto',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Masz $newCount nowych zapytań',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.medical_services_outlined, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }

  Widget _buildInquiriesList() {
    if (inquiries.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'Brak nowych zapytań',
              style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: inquiries.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = inquiries[index];
        
        // Pobieramy naszą ustandaryzowaną mapę
        final reviews = item['reviews'] as Map<String, int>?;

        // Wyciągamy wartości używając kluczy, które zdefiniowałeś w processed.add
        int good = reviews?['goodCount'] ?? 0;
        int neutral = reviews?['neutralCount'] ?? 0;
        int bad = reviews?['badCount'] ?? 0;
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: AppColors.outlineVariant),
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
                    const SizedBox(height: 8),

                  Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildRatingCompact(Icons.thumb_up, good, Colors.green),
                      const SizedBox(width: 10),
                      _buildRatingCompact(Icons.thumbs_up_down, neutral, Colors.orange),
                      const SizedBox(width: 10),
                      _buildRatingCompact(Icons.thumb_down, bad, Colors.red),
                    ],
                  ),
                ),
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: item['isNew']
                            ? AppColors.secondary.withValues(alpha: 0.15)
                            : Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: item['isNew']
                              ? AppColors.secondary
                              : Colors.green,
                          width: 1.5,
                        ),
                      ),
                      child: item['isNew']
                          ? null
                          : const Icon(
                              Icons.check,
                              size: 18,
                              color: Colors.green,
                            ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildInfoRow(Icons.calendar_today_outlined, '${item['startDate']} - ${item['endDate']}'),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.location_on_outlined, item['address']),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () async{
                            markAsRead(item['id']);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OfferFormScreen(
                                  appointmentId: item['id'],
                                  patientName: item['name'],
                                  startDate: item['startDate'],
                                  endDate: item['endDate'],
                                  description: item['description'],
                                ),
                              ),
                            ).then((_) => _fetchData());
                          },
                          child: const Text('Szczegóły'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 60,
                        width: 60,
                        child: OutlinedButton.icon(
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
                        )
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
Widget _buildRatingCompact(IconData icon, int count, Color color) {
  final isEmpty = count == 0;

  return Row(
    children: [
      Icon(
        icon,
        size: 14,
        color: isEmpty ? color.withValues(alpha: 0.3) : color,
      ),
      const SizedBox(width: 4),
      Text(
        count.toString(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isEmpty ? color.withValues(alpha: 0.4) : color,
        ),
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
                  color: AppColors.textSecondary,
                ),
          ),
        ),
      ],
    );
  }
}