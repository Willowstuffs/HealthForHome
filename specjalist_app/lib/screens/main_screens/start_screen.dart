import 'package:flutter/material.dart';
import 'package:specjalist_app/services/user_profile.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';
import '../offer_from_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/notification_services.dart';
import '../../services/app_refresh_service.dart';
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
    debugPrint("Profile load error: $e");
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
    try {
      final fetchedInquiries = await ApiService().getInquiries(
        patientName: "",
        dateFrom: DateTime(now.year, now.month, now.day),
        dateTo:
            DateTime(now.year, now.month, now.day).add(const Duration(days: 90)),
      );

      final displayFormatter = DateFormat('dd-MM-yyyy HH:mm');

      List<Map<String, dynamic>> processed = [];

      for (var i in fetchedInquiries) {
        final id = i['appointmentId']?.toString() ?? i['AppointmentId']?.toString();


        DateTime? start = i['scheduledStart'] != null
            ? DateTime.tryParse(i['scheduledStart'])
            : (i['ScheduledStart'] != null
                ? DateTime.tryParse(i['ScheduledStart'])
                : null);

        DateTime? end = i['scheduledEnd'] != null
            ? DateTime.tryParse(i['scheduledEnd'])
            : (i['ScheduledEnd'] != null
                ? DateTime.tryParse(i['ScheduledEnd'])
                : null);

       String originalAddress = i['patientAddress'] ?? i['PatientAddress'] ?? '';
        String streetAndCity = '';

        final parts = originalAddress.split(',');


        
        if (parts.length >= 2) {
          String street = parts[0].trim();
          String city = parts[1].trim();

          street = street.replaceAll(RegExp(r'[\d-]'), '');

          streetAndCity = '$street, $city';
        } else {
          streetAndCity = originalAddress.replaceAll(RegExp(r'[\d-]'), '');
        }
        bool apiIsRead = i['isRead'] == true || i['IsRead'] == true;
        bool isNew = !apiIsRead && !_readIds.contains(id);

        processed.add({
          'id': id?.toString() ?? '',
          'name': i['patientName'] ?? i['PatientName'] ?? '',
          'startDate': start != null ? displayFormatter.format(start) : '',
          'endDate': end != null ? displayFormatter.format(end) : '',
          'service': i['serviceName'] ?? i['ServiceName'] ?? '',
          'address': streetAndCity,
          'description': i['description'] ?? i['Description'] ?? '',
          'distanceKm':i['distanceKm'],
          'isNew': isNew,
        });
      }
      processed.sort((a, b) {
        if (a['isNew'] == b['isNew']) return 0;
        return a['isNew'] ? -1 : 1;
      });
      if (!mounted) return;

      setState(() {
        inquiries = processed;
        isLoading = false;
      });
    } catch (e) {
      print('Błąd pobierania zapytań: $e');

      if (mounted) {
        setState(() => isLoading = false);
      }
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
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MainScreen(startIndex: 4),
                    ),
                  );
                },
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