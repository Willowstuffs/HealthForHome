import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {

  List<Map<String, dynamic>> inquiries = [];
  bool isLoading = true;



  final upcomingVisits = [
    {
      'name': 'Leon',
      'address': 'ul. Jana Pawła 2, Bydgoszcz',
      'date': '10.11.2020',
    },
  ];

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

    setState(() {
  inquiries = fetchedInquiries.map((i) => {
  'name': i['patientName']?.toString() ?? '',
  'startDate': i['scheduledStart']?.toString() ?? '',
  'endDate': i['scheduledEnd']?.toString() ?? '',
  'service': i['serviceName']?.toString() ?? '',
  'distance': i['patientAddress']?.toString() ?? '',
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
                      'Witaj, Jan!',
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
                          child: _buildSection('Nadchodzące wizyty', upcomingVisits),
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
                          Text('Od: ${item['startDate']}  Do: ${item['endDate']}',
                          style: const TextStyle(
                              fontSize: 15),
                        ),
                          Text('Usługa: ${item['service']}',
                          style: const TextStyle(
                              fontSize: 15),
                        ),
                          Text('Odległość: ${item['distance']}',
                          style: const TextStyle(
                              fontSize: 15),
                        ),
                          const SizedBox(height: 8),
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
                            child: const Text('Wyślij ofertę'),
                          ),
                        ] else ...[
                          Text('Adres: ${item['address']}',
                          style: const TextStyle(
                              fontSize: 15),
                        ),
                          Text('Data: ${item['date']}',
                          style: const TextStyle(
                              fontSize: 15),
                        ),
                          const SizedBox(height: 8),
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
                            child: const Text('Wyślij wiadomość'),
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