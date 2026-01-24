import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';

class UpcomingScreen extends StatefulWidget {
  const UpcomingScreen({super.key});

  @override
  State<UpcomingScreen> createState() => _UpcomingScreenState();
}

class _UpcomingScreenState extends State<UpcomingScreen> {

  List<Map<String, dynamic>> upcoming = [];
  List<Map<String, dynamic>> archive = [];
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    _fetchData();
  }
  final displayFormatter = DateFormat('dd-MM-yyyy HH:mm');
  final now = DateTime.now();
  Future<void> _fetchData() async {
    try {
      final fetchedUpcoming = await ApiService().getCommingInquiries(
        patientName: "", // przykładowy filtr
        dateFrom: DateTime(now.year, now.month, now.day), // dziś od 00:00
        dateTo: DateTime(now.year, now.month, now.day).add(const Duration(days: 30)),
      );
      final fetchedArchive = await ApiService().getArchiveInquiries();
      setState(() {
        upcoming = fetchedUpcoming.map((i) {
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
            'price': i['price'] ?? i['Price'] ?? '',
         };
        }).toList();
      });
      setState(() {
        archive = fetchedArchive.map((i) {
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
                  const SizedBox(height: 40),// margines od dołu
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
                          child: _buildSection('Nadchodzące wizyty', upcoming, isUpcoming: true),
                        ),
                        const SizedBox(height: 16),
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
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _buildSection('Archiwum', archive),
                        ),
                      ],
                    )
                  ],
                ),
              ),
      ),
      
    );
  }

  Widget _buildSection(String title,  List<Map<String, dynamic>> items,
    {bool isUpcoming = false}) {
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
                              fontSize: 20),
                        ),
                        const SizedBox(height: 8),
                        if (isUpcoming) ...[
                          Text('Od: ${item['startDate']}',
                          style: const TextStyle(
                              fontSize: 15),
                        ),
                        Text('do: ${item['endDate']}',
                          style: const TextStyle(
                              fontSize: 15),
                        ),
                          Text('Usługa: ${item['service']}',
                          style: const TextStyle(
                              fontSize: 15),
                        ),
                          Text('Koszt: ${item['price']}',
                          style: const TextStyle(
                              fontSize: 15),
                        ),
                          Text('adres: ${item['distance']}',
                          style: const TextStyle(
                              fontSize: 15),
                        ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.onSurface,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    fixedSize: const Size(125, 29),
                                  ),
                                  child: const Text('Wiadomość'),
                                ),

                                const SizedBox(width: 8), // odstęp między przyciskami

                              ElevatedButton(
                                onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.onSurface,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    fixedSize: const Size(125, 29),
                                  ),
                                child: const Text('Zrezygnuj'),
                              ),
                            ],
                          ),
                        ] else ...[
                          
                          Text('Od: ${item['startDate']}',
                          style: const TextStyle(
                              fontSize: 15),
                        ),
                        Text('do: ${item['endDate']}',
                          style: const TextStyle(
                              fontSize: 15),
                        ),
                          Text('Usługa: ${item['service']}',
                          style: const TextStyle(
                              fontSize: 15),
                        ),
                        ],
                        
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

  @override
  void dispose() {
    super.dispose();
  }
}