import 'package:flutter/material.dart';
import 'package:specjalist_app/services/user_profile.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';
class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {

  List<Map<String, dynamic>> inquiries = [];
  bool isLoading = true;
  final firstName = UserSession.firstName ?? '';
  @override
  void initState() {
    super.initState();
    _fetchData();
  }
final now = DateTime.now();
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
      'distance': i['patientAddress'] ?? i['PatientAddress'] ?? '',
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
  return Container(
    color: AppColors.onBackground,
    child: Center(
      child: isLoading
          ? const CircularProgressIndicator()
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 335,
                    child: Text(
                      'Witaj, $firstName!',
                      style: Theme.of(context)
                          .textTheme
                          .headlineLarge!
                          .copyWith(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                    const SizedBox(height: 40), // margines od dołu
                    Column(
                      children: [
                        Container(
                          width: 350,
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.background,
                                AppColors.onBackground,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12), // opcjonalnie zaokrąglone rogi
                          ),
                          child: _buildSection('Zapytania', inquiries, isZapytania: true),
                        ),
                      ],
                    )
                  ],
                ),
              ),
      ),
      
    );
  }

  Widget _buildSection(String title, List<Map<String, dynamic>> items, {bool isZapytania = false}) {
  return ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 400), // maksymalna szerokość
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
         // Jeżeli lista jest pusta
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              isZapytania ? 'Brak zgłoszeń' : 'Brak nadchodzących wizyt',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          )
        else
        Column(
          children: items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  color: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 3,
                  child: SizedBox(
                    width: 310,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          item['name'] ?? '',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (isZapytania) ...[
                          Text('Od: ${item['startDate']}',
                          style: const TextStyle(
                              fontSize: 15),
                          ),
                          Text('Od: ${item['endDate']}',
                          style: const TextStyle(
                              fontSize: 15),
                          ),
                          Text('Usługa: ${item['service']}',
                          style: const TextStyle(
                              fontSize: 15),
                          ),
                          Text('Odległość: BRAK',
                          style: const TextStyle(
                              fontSize: 15),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              _showConfirmDialog(
                                appointmentId: item['id'],
                                patientName: item['name'],
                                );
                              },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.onSurface,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 0),
                              shape: RoundedRectangleBorder(
                                 borderRadius: BorderRadius.circular(10),
                              ),
                              fixedSize: const Size(125, 29),
                            ),
                            child: const Text('Wyślij ofertę'),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  Future<void> _showConfirmDialog({
    required String appointmentId,
    required String patientName,
  }) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'Potwierdzenie',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Czy na pewno chcesz przyjąć:\n\n$patientName?\n\n'
          'W razie pomyłki można później zrezygnować.',
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.onSurface,
            foregroundColor: Colors.white,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            fixedSize: const Size(125, 29),
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text('Zrezygnuj'),
      ),
      ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.onSurface,
            foregroundColor: Colors.white,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            fixedSize: const Size(125, 29),
          ),
          onPressed: () async {
            Navigator.pop(context);

            try {
              await ApiService().confirmAppointment(appointmentId);
              _fetchData();
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Błąd: $e')),
              );
            }
          },
          child: const Text('Potwierdź'),
        ),
      ],
    ),
  );
}
  @override
  void dispose() {
    super.dispose();
  }
}