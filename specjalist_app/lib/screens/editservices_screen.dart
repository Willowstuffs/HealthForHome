import 'package:flutter/material.dart';
import 'package:specjalist_app/screens/main_bottom.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/specjalist_service.dart';
import 'main_screens/maintoolbar_screen.dart';

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
    backgroundColor: AppColors.surface,
    appBar: AppBar(
      title: const Text("Twoje usługi"),
      centerTitle: true,
    ),
    body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadServices,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    children: [
                      _buildServicesList(),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveChanges,
                          child: const Text("Zapisz zmiany"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    bottomNavigationBar: MainBottomBar(
      currentIndex: 1,
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
Widget _buildServicesList() {
  if (services.isEmpty) {
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
          Icon(
            Icons.medical_services_outlined,
            size: 48,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text("Brak usług"),
        ],
      ),
    );
  }

  return ListView.separated(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: services.length,
    separatorBuilder: (_, __) => const SizedBox(height: 16),
    itemBuilder: (context, index) {
      final service = services[index];
      return _buildServiceCard(service);
    },
  );
}
Widget _buildServiceCard(SpecialistService service) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainer,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.outlineVariant),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                service.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: AppColors.error,
              onPressed: () => _removeService(service.id),
            )
          ],
        ),

        const SizedBox(height: 16),

        _buildField(
          label: "Cena (zł)",
          controller: priceControllers[service.id]!,
        ),

        const SizedBox(height: 12),

        _buildField(
          label: "Czas trwania (min)",
          controller: durationControllers[service.id]!,
          keyboardType: TextInputType.number,
        ),
      ],
    ),
  );
}
Widget _buildField({
  required String label,
  required TextEditingController controller,
  TextInputType? keyboardType,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: const InputDecoration(),
      ),
    ],
  );
}
}
