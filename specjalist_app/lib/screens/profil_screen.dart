import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {

  bool isLoading = true;

  // przykładowe dane z API
  final info = [
    {
      'name': 'Jan',
      'surname': 'Nowak',
      'email': 'JNowak@email.com',
      'distance': '50'
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
                  const SizedBox(height: 40),
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
                          child: _buildSection(info),
                        ),
                        
                      ],
                    )
                  ],
                ),
              ),
      ),
      
    );
  }

  Widget _buildSection( List<Map<String, String>> items,) {
  return ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 400), // maksymalna szerokość
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
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
                        
                          Text(
                          item['surname'] ?? '',
                          style: const TextStyle(
                              fontSize: 20),
                        ),
                          Text(
                          item['email'] ?? '',
                          style: const TextStyle(
                              fontSize: 20),
                        ),
                          Text('Odległość pracy od miejsca zamieszkania: \n ${item['distance']} km',
                          style: const TextStyle(
                              fontSize: 20,  ),
                              textAlign: TextAlign.center,
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
                            child: const Text('Edytuj'),
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
                            child: const Text('Zmień hasło'),
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
                            child: const Text('Wyloguj się'),
                          ),
                       
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