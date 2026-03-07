import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:specjalist_app/main.dart';
import 'package:specjalist_app/services/user_profile.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';
import '../offer_from_screen.dart';
import '../../services/notification_services.dart';
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // nazwa
  description: 'Kanał dla ważnych powiadomień', 
  importance: Importance.high,
);

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
  bool isLoading = true;
  String? highlightedId;
  final firstName = UserSession.firstName ?? '';
  final now = DateTime.now();
  @override
  void initState() {
    super.initState();
    highlightedId = widget.highlightAppointmentId;
    _initializeNotifications();
    _fetchData();
  }
  @override
  void didUpdateWidget(covariant StartScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.highlightAppointmentId != oldWidget.highlightAppointmentId) {
      highlightedId = widget.highlightAppointmentId;
      _fetchData();
    }
  }
  Future<void> _initializeNotifications() async {
    await NotificationService().setupInteractions(navigatorKey);
    
    await NotificationService().uploadTokenToServer();
  }
  Future<void> _fetchData() async {
  try {
    final fetchedInquiries = await ApiService().getInquiries(
      patientName: "", // przykładowy filtr
      dateFrom: DateTime(now.year, now.month, now.day), // dziś od 00:00
      dateTo: DateTime(now.year, now.month, now.day).add(const Duration(days: 30)),
    );
  final displayFormatter = DateFormat('dd-MM-yyyy HH:mm');
    setState(() {
  inquiries = fetchedInquiries.map((i) {
    // Sprawdzamy oba warianty: małe 'a' i duże 'A'
    final id = i['appointmentId'] ?? i['AppointmentId'];
     DateTime? start = i['scheduledStart'] != null
      ? DateTime.tryParse(i['scheduledStart'])
      : (i['ScheduledStart'] != null ? DateTime.tryParse(i['ScheduledStart']) : null);

  DateTime? end = i['scheduledEnd'] != null
      ? DateTime.tryParse(i['scheduledEnd'])
      : (i['ScheduledEnd'] != null ? DateTime.tryParse(i['ScheduledEnd']) : null);

    return {
      'id': id?.toString() ?? '', 
      'name': i['patientName'] ?? i['PatientName'] ?? '',
      'startDate': start != null ? displayFormatter.format(start) : '',
      'endDate': end != null ? displayFormatter.format(end) : '',
      'service': i['serviceName'] ?? i['ServiceName'] ?? '',
      'address': i['patientAddress'] ?? i['PatientAddress'] ?? '',
      'description': i['description'] ?? i['Description'] ?? '',
    };
  }).toList();
  isLoading = false;
});

  } catch (e) {
    print('Błąd pobierania zapytań: $e');
    setState(() => isLoading = false);
  }
}
  
@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
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
                      _buildSectionTitle('Nowe zapytania', Icons.notifications_active_outlined),
                      const SizedBox(height: 16),
                      _buildInquiriesList(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
Widget _buildHeader() {
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
                  'Masz ${inquiries.length} nowych zapytań',
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item['service'],
                        style: TextStyle(
                          color: AppColors.livingColor10,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildInfoRow(Icons.calendar_today_outlined, '${item['startDate']} - ${item['endDate']}'),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.location_on_outlined, item['address']),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OfferFormScreen(
                            appointmentId: item['id'],
                            patientName: item['name'],
                            startDate: item['startDate'],
                            endDate: item['endDate'],
                            description: item['description'], // NOWE
                          ),
                        ),
                      ).then((_) => _fetchData());
                    },
                    child: const Text('Szczegóły oferty'),
                  ),
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