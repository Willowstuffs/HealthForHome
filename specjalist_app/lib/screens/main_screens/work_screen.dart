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
    backgroundColor: AppColors.surface,
    body: SafeArea(
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildSectionTitle(
                        'Twoje usługi', Icons.medical_services_outlined),
                    const SizedBox(height: 16),
                    _buildServicesList(),

                    const SizedBox(height: 32),

                    _buildSectionTitle(
                        'Dodaj usługę', Icons.add_circle_outline),
                    const SizedBox(height: 16),
                    _buildAddServiceCard(),
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
      color: AppColors.surfaceContainerHighest,
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
          child: Text(
            'Twoje usługi',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.work_outline, color: Colors.white),
        )
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
        child: Icon(icon, size: 20, color: AppColors.primary),
      ),
      const SizedBox(width: 12),
      Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      )
    ],
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
          Icon(Icons.inbox_outlined,
              size: 48,
              color: AppColors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'Nie masz jeszcze usług',
            style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500),
          ),
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
      final item = services[index];

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cena od ${item.price} zł • ${item.duration} min',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      );
    },
  );
}
Widget _buildAddServiceCard() {
  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainer,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.outlineVariant),
    ),
    child: Column(
      children: [

        DropdownButtonFormField<ServiceType>(
          isExpanded: true,
          initialValue: selectedServiceType,
          hint: const Text('Wybierz usługę'),
          items: servicesFromDb.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(
                type.name,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedServiceType = value;
              if (value != null) {
                durationController.text =
                    value.defaultDuration.toString();
              }
            });
          },
        ),

        const SizedBox(height: 16),

        TextField(
          controller: priceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Cena (zł)',
          ),
        ),

        const SizedBox(height: 16),

        TextField(
          controller: durationController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Czas trwania (min)',
          ),
        ),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _addService,
            child: const Text('Dodaj usługę'),
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const EditServicesScreen()),
              );
            },
            child: const Text('Edytuj usługi'),
          ),
        )
      ],
    ),
  );
}
Future<void> _addService() async {
  if (selectedServiceType == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Wybierz typ usługi')),
    );
    return;
  }

  try {
    await _apiService.addService(
      serviceTypeId: selectedServiceType!.id,
      price: double.parse(priceController.text),
      durationMinutes: int.parse(durationController.text),
    );

    priceController.clear();
    durationController.clear();
    selectedServiceType = null;

    setState(() => isLoading = true);

    await _fetchData();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Usługa została dodana')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(e.toString())));
  }
}
  @override
  void dispose() {
    super.dispose();
  }
}