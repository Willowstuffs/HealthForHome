import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/specjalist_service.dart';

class OfferFormScreen extends StatefulWidget {
  final String appointmentId;
  final String patientName;
  final String startDate;
  final String endDate;
  final String description;

  const OfferFormScreen({
    super.key,
    required this.appointmentId,
    required this.patientName,
    required this.startDate,
    required this.endDate,
    required this.description,
  });

  @override
  State<OfferFormScreen> createState() => _OfferFormScreenState();
}

class _OfferFormScreenState extends State<OfferFormScreen> {
  final ApiService _apiService = ApiService();

  List<SpecialistService> services = [];
  List<SpecialistService> selectedServices = [];
  SpecialistService? selectedServiceTYMCZASOWE;

  SpecialistService? selectedService;

  final TextEditingController finalPriceController = TextEditingController();
  double totalPrice = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchService();
  }

  Future<void> _fetchService() async {
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
  Future<void> _confirmOffer() async {
    if (selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wybierz usługę')),
      );
      return;
    }

    final price = double.tryParse(finalPriceController.text);
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Podaj poprawną wycenę')),
      );
      return;
    }

    try {
      selectedServiceTYMCZASOWE = selectedServices.first;
      await _apiService.confirmAppointment(
        widget.appointmentId,
        selectedServiceTYMCZASOWE!.id,
        price,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,

      appBar: AppBar(
        title: const Text("Nowa oferta"),
        centerTitle: true,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchService,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      children: [
                        _buildDetailsCard(),
                        const SizedBox(height: 20),
                        _buildServiceMultiSelect(),
                        const SizedBox(height: 20),
                        _buildPriceField(),
                        const SizedBox(height: 28),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _confirmOffer,
                            child: const Text("Potwierdź ofertę"),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

 Widget _buildDetailsCard() {
  return Container(
    width: double.infinity,
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
        Text(
          widget.patientName,
          style: Theme.of(context).textTheme.titleLarge,
        ),

        const SizedBox(height: 12),

        _buildInfoText("Od: ${widget.startDate}"),
        _buildInfoText("Do: ${widget.endDate}"),
        const SizedBox(height: 12),

        if (widget.description.isNotEmpty) ...[
          const Divider(),
          const SizedBox(height: 8),

          Text(
            "Opis wizyty",
            style: Theme.of(context).textTheme.titleMedium,
          ),

          const SizedBox(height: 6),

          Text(
            widget.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ],
    ),
  );
}

  Widget _buildServiceMultiSelect() {
  return Container(
    width: double.infinity,
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
          "Wybierz usługi",
          style: Theme.of(context).textTheme.titleMedium,
        ),

        const SizedBox(height: 16),

        ...services.map((service) {
          final isSelected = selectedServices.contains(service);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: CheckboxListTile(
              title: Text(
                service.name,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                "${service.price.toStringAsFixed(2)} zł • ${service.duration} min",
                style: Theme.of(context).textTheme.bodySmall,
              ),
              value: isSelected,
              activeColor: AppColors.primary,
              controlAffinity: ListTileControlAffinity.leading,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    selectedServices.add(service);
                    totalPrice += service.price;
                  } else {
                    selectedServices.remove(service);
                    totalPrice -= service.price;
                  }

                  finalPriceController.text =
                      totalPrice.toStringAsFixed(2);
                });
              },
            ),
          );
        }),
      ],
    ),
  );
}

  Widget _buildPriceField() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "Wycena końcowa (zł)",
        style: Theme.of(context).textTheme.bodyMedium,
      ),

      const SizedBox(height: 8),

      TextField(
        controller: finalPriceController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(),
      ),
    ],
  );
}

  Widget _buildInfoText(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium,
    ),
  );
}


  @override
  void dispose() {
    finalPriceController.dispose();
    super.dispose();
  }
}