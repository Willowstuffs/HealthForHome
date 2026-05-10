import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/specjalist_service.dart';
import '../../services/api_service.dart';
import "../editservices_screen.dart";
import '../../services/specialization_mapper.dart';
import '../../services/user_profile.dart';

class WorkScreen extends StatefulWidget {
  const WorkScreen({super.key});

  @override
  State<WorkScreen> createState() => _WorkScreenState();
}

class _WorkScreenState extends State<WorkScreen> {

  bool isLoading = true;

  final TextEditingController customServiceController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController durationController = TextEditingController();

  final ApiService _apiService = ApiService();

  List<SpecialistService> services = [];
  List<ServiceType> servicesFromDb = [];

  ServiceType? selectedServiceType;

  /// ⭐ czy wybrano "Inne"
  bool get isCustomSelected =>
      selectedServiceType?.id == "-1";

  @override
  void initState() {
    super.initState();
    _fetchServiceTypes();
    _fetchData();
  }

  /// ===============================
  /// FETCH SERVICE TYPES
  /// ===============================
  Future<void> _fetchServiceTypes() async {
    try {
      final types = await _apiService.getServiceTypes();

      setState(() {
        servicesFromDb = [
          ...types,
          ServiceType(
            id: "-1",
            name: "Inne",
            defaultDuration: 30, 
            category: '',
          ),
        ];
      });
    } catch (e) {
      debugPrint('Błąd pobierania typów usług: $e');
    }
  }

  /// ===============================
  /// FETCH USER SERVICES
  /// ===============================
  Future<void> _fetchData() async {
    try {
      final result = await _apiService.getServices();

      setState(() {
        services = result;
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  /// ===============================
  /// UI
  /// ===============================
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
                          'Twoje usługi',
                          Icons.medical_services_outlined),

                      const SizedBox(height: 16),
                      _buildServicesList(),

                      const SizedBox(height: 32),

                      _buildSectionTitle(
                          'Dodaj usługę',
                          Icons.add_circle_outline),

                      const SizedBox(height: 16),
                      _buildAddServiceCard(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  /// ===============================
  /// HEADER
  /// ===============================
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Twoje usługi',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
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
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        )
      ],
    );
  }

  /// ===============================
  /// SERVICES LIST
  /// ===============================
  Widget _buildServicesList() {
    if (services.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: Text("Nie masz jeszcze usług"),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: services.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, index) {
        final item = services[index];

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Cena od ${item.price} zł • ${item.duration} min',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        );
      },
    );
  }

  /// ===============================
  /// ADD SERVICE CARD
  /// ===============================
  Widget _buildAddServiceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [

          /// DROPDOWN
          DropdownButtonFormField<ServiceType>(
            value: selectedServiceType,
            hint: const Text('Wybierz usługę'),
            isExpanded: true,
            items: servicesFromDb.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type.name),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedServiceType = value;

                if (!isCustomSelected && value != null) {
                  durationController.text =
                      value.defaultDuration.toString();
                } else {
                  durationController.clear();
                }
              });
            },
          ),

          /// CUSTOM FIELD
          if (isCustomSelected) ...[
            const SizedBox(height: 16),
            TextField(
              controller: customServiceController,
              decoration: const InputDecoration(
                labelText: 'Nazwa usługi',
              ),
            ),
          ],

          const SizedBox(height: 16),

          TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Cena (zł)'),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: durationController,
            keyboardType: TextInputType.number,
            decoration:
                const InputDecoration(labelText: 'Czas trwania (min)'),
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
          ),
        ],
      ),
    );
  }

  /// ===============================
  /// ADD SERVICE
  /// ===============================
  Future<void> _addService() async {

    if (selectedServiceType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wybierz usługę')),
      );
      return;
    }

    if (isCustomSelected &&
        customServiceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Podaj nazwę usługi')),
      );
      return;
    }

    try {
      final category = SpecializationMapper.mapToCategory(
        UserSession.specializations,
      );

      await _apiService.addService(
        serviceTypeId:
            isCustomSelected ? null : selectedServiceType!.id,
        customName:
            isCustomSelected ? customServiceController.text : null,
        category: category,
        price: double.parse(priceController.text),
        durationMinutes: int.parse(durationController.text),
      );

      priceController.clear();
      durationController.clear();
      customServiceController.clear();

      setState(() {
        selectedServiceType = null;
        isLoading = true;
      });

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
    customServiceController.dispose();
    priceController.dispose();
    durationController.dispose();
    super.dispose();
  }
}