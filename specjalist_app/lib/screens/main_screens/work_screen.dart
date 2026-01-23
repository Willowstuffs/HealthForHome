import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/specjalist_service.dart';
import '../../services/api_service.dart';
import "../editservices_screen.dart";
class WorkScreen extends StatefulWidget {
  const WorkScreen({super.key});

  @override
  State<WorkScreen> createState() => _WorkScreenState();
}

class _WorkScreenState extends State<WorkScreen> {
  
  bool isLoading = true;
  String? selectedService;
  bool customService = false;

  final TextEditingController customServiceController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  final ApiService _apiService = ApiService();
  List<SpecialistService> services = [];
 List<ServiceType> servicesFromDb = [];
 ServiceType? selectedServiceType;

  @override
  void initState() {
    super.initState();
    _fetchServiceTypes();
    _fetchData();
  }
  Future<void> _fetchServiceTypes() async {
  try {
    final types = await _apiService.getServiceTypes();
    setState(() => servicesFromDb = types);
  } catch (e) {
    debugPrint('Błąd pobierania typów usług: $e');
  }
}
  Future<void> _fetchData() async {
    try {
    final result = await _apiService.getServices();
    setState(() {
      services = result;
      isLoading = false;
    });
  } catch (e) {
    setState(() => isLoading = false);
  }
  }
  
@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.onBackground,
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 40), // margines od góry
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
                          child: _buildSection('Aktualne usługi', services),
                        ),
                        const SizedBox(height: 16),
                        Container(
                        width: 350,
                        padding: const EdgeInsets.all(16),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dodaj usługę',
                              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<ServiceType>(
                              initialValue: selectedServiceType,
                              isExpanded: true,
                              hint: const Text('Wybierz usługę'),
                              items: servicesFromDb.map((type) {
                                return DropdownMenuItem<ServiceType>(
                                  value: type,
                                  child: Text(type.name),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedServiceType = value;
                                  if (value != null) {
                                    durationController.text = value.defaultDuration.toString();
                                    }
                                  });
                                },
                              ),
                           

                            const SizedBox(height: 12),
                            TextField(
                              controller: priceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Cena (zł)',
                                border: OutlineInputBorder(),
                                fillColor: AppColors.onPrimary,
                                filled: true, 
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: durationController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Czas trwania (min)',
                                border: OutlineInputBorder(),
                                fillColor: AppColors.onPrimary,
                                filled: true, 
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: Column(
                                children:[
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.onSurface,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      fixedSize: const Size(125, 29),
                                    ),
                                    onPressed: () async {
                                      if (selectedServiceType == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Wybierz typ usługi')));
                                    return;
                                  }
                                      try {
                                    await _apiService.addService(
                                      serviceTypeId: selectedServiceType!.id,
                                      price: double.parse(priceController.text),
                                      durationMinutes:
                                          int.parse(durationController.text),
                                      description:
                                          customServiceController.text.isEmpty
                                              ? null
                                              : customServiceController.text,
                                    );
                                    // Wyczyść pola
                                    priceController.clear();
                                    durationController.clear();
                                    customServiceController.clear();
                                    selectedServiceType = null;
                                    setState(() => isLoading = true);
                                    await _fetchData();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text('Usługa została dodana')));
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(e.toString())));
                                  }
                                },
                                child: const Text('Dodaj usługę'),
                              ),
                                  const SizedBox(height: 8),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.onSurface,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 0),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        fixedSize: const Size(125, 29),
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const EditServicesScreen(),
                                          ),
                                        );
                                      },
                                      child: const Text('Edytuj'),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
      ),
      
    );
  }

  Widget _buildSection(String title, List<SpecialistService> items) {
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
                          item.name,
                          style: const TextStyle(
                              fontSize: 20),
                        ),
                        const SizedBox(height: 8),
                          Text('Od: ${item.price}  czas trwania: ${item.duration}',
                          style: const TextStyle(
                              fontSize: 15),
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