import 'package:flutter/material.dart';
import 'package:specjalist_app/screens/main_bottom.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/specjalist_service.dart';
import '../screens/maintoolbar_screen.dart';

class EditServicesScreen extends StatefulWidget {
  const EditServicesScreen({super.key});

  @override
  State<EditServicesScreen> createState() => _EditServicesScreenState();
}

class _EditServicesScreenState extends State<EditServicesScreen> {
  final ApiService _apiService = ApiService();
  bool isLoading = true;
  List<SpecialistService> services = [];
  final Map<String, TextEditingController> priceControllers = {};
  final Map<String, TextEditingController> durationControllers = {};

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => isLoading = true);
    try {
      final result = await _apiService.getServices();
      for (final s in result) {
        priceControllers[s.id] =
            TextEditingController(text: s.price.toString());
        durationControllers[s.id] =
            TextEditingController(text: s.duration.toString());
      }
      setState(() {
        services = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd pobierania usług: $e')),
      );
    }
  }

  Future<void> _removeService(String id) async {
    setState(() {
      services.removeWhere((s) => s.id == id);
      priceControllers.remove(id);
      durationControllers.remove(id);
    });

    try {
      await _apiService.deleteService(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usługa została usunięta')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd usuwania usługi: $e')),
      );
    }
  }

  Future<void> _saveChanges() async {
  setState(() => isLoading = true);

  try {
    for (final s in services) {
      final updatedPrice = double.tryParse(priceControllers[s.id]!.text) ?? s.price;
      final updatedDuration = int.tryParse(durationControllers[s.id]!.text) ?? s.duration;

      // Teraz przesyłamy komplet danych
      await _apiService.updateService(
        id: s.id,
        price: updatedPrice,
        durationMinutes: updatedDuration,
        description: s.description,
        serviceTypeId: s.serviceTypeId, // POBIERANE Z MODELU
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Zapisano zmiany')),
    );

    await _loadServices(); // Odświeżenie listy
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Błąd zapisywania zmian: $e')),
    );
  } finally {
    setState(() => isLoading = false);
  }
}

  @override
  void dispose() {
    for (final controller in priceControllers.values) {
      controller.dispose();
    }
    for (final controller in durationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.onBackground,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.only(top: 80),
              child: Column(
                children: [
                  ...services.map((service) {
                    return Container(
                      width: 350,
                      margin: const EdgeInsets.all(30),
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
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // NAZWA
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  service.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.black),
                                  onPressed: () => _removeService(service.id),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // CENA
                            TextField(
                              controller: priceControllers[service.id],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Cena (zł)',
                                border: OutlineInputBorder(),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // CZAS
                            TextField(
                              controller: durationControllers[service.id],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Czas trwania (min)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: 174,
                    height: 37,
                    child: ElevatedButton(
                      onPressed: _saveChanges,
                      child: const Text('Zapisz zmiany'),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: MainBottomBar(
        currentIndex: 1, // Usługi
        onTap: (index) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => MainScreen(startIndex: index),
            ),
            (route) => false,
          );
        },
      ),
    );
  }
}
