import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class UpcomingScreen extends StatefulWidget {
  const UpcomingScreen({super.key});

  @override
  State<UpcomingScreen> createState() => _UpcomingScreenState();
}

class _UpcomingScreenState extends State<UpcomingScreen> {

  bool isLoading = true;

  // przykładowe dane z API
  final upcoming = [
    {
      'name': 'Zbyszek',
      'startDate': '18.09.2020',
      'endDate': '20.09.2020',
      'service': 'Zmiana opatrunku',
      'costs': '20',
      'adress': 'Koniuchy 1, Toruń',
    },
    {
      'name': 'Anna',
      'startDate': '21.09.2020',
      'endDate': '23.09.2020',
      'service': 'Pobranie krwi',
      'costs': '20',
      'adress': 'Koniuchy 1, Toruń',
    },
  ];

  final archive = [
    {
      'name': 'Leon',
      'service': 'Zmiana opatrunku',
      'date': '10.11.2020',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    // symulacja pobrania danych
    await Future.delayed(const Duration(seconds: 1));
    setState(() => isLoading = false);
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
                          child: _buildSection('Nadchodzące', upcoming, isUpcoming: true),
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

  Widget _buildSection(String title, List<Map<String, String>> items,
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
                          Text('Od: ${item['startDate']}  Do: ${item['endDate']}',
                          style: const TextStyle(
                              fontSize: 15),
                        ),
                          Text('Usługa: ${item['service']}',
                          style: const TextStyle(
                              fontSize: 15),
                        ),
                          Text('Koszt: ${item['costs']}',
                          style: const TextStyle(
                              fontSize: 15),
                        ),
                          Text('adres: ${item['adress']}',
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
                          Text('Usługa: ${item['service']}',
                          style: const TextStyle(
                              fontSize: 15),
                        ),
                          Text('Data: ${item['date']}',
                          style: const TextStyle(
                              fontSize: 15 ),
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