import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/specjalist_service.dart';

class OfferFormScreen extends StatefulWidget {
  final String appointmentId;
  final String patientName;
  final String startDate;
  final String endDate;
  final String serviceName;

  const OfferFormScreen({
    super.key,
    required this.appointmentId,
    required this.patientName,
    required this.startDate,
    required this.endDate,
    required this.serviceName,
  });

  @override
  State<OfferFormScreen> createState() => _OfferFormScreenState();
}

class _OfferFormScreenState extends State<OfferFormScreen> {
  final ApiService _apiService = ApiService();

  List<SpecialistService> services = [];
  List<SpecialistService> selectedServices = [];
  SpecialistService? selectedService;

  final TextEditingController finalPriceController =
      TextEditingController();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Nowa oferta"),
        backgroundColor: AppColors.secondary,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Center(
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    _buildDetailsCard(),
                    const SizedBox(height: 20),
                    _buildServiceMultiSelect(),
                    const SizedBox(height: 20),
                    _buildPriceField(),
                    const SizedBox(height: 30),
                    _buildConfirmButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      width: 350,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.secondary, AppColors.onBackground],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(widget.patientName,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("Dane"),
          Text("Od: ${widget.startDate}"),
          Text("Do: ${widget.endDate}"),
          Text("Opis: ${widget.serviceName}"),
        ],
      ),
    );
  }

  Widget _buildServiceMultiSelect() {
  return Container(
    width: 350,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [AppColors.secondary, AppColors.onBackground],
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Wybierz usługi",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        ...services.map((service) {
          final isSelected = selectedServices.contains(service);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.onPrimary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: CheckboxListTile(
              title: Text(
                service.name,
                overflow: TextOverflow.ellipsis,
              ),
              value: isSelected,
              activeColor: AppColors.onSurface,
              controlAffinity: ListTileControlAffinity.leading,
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
        })
      ],
    ),
  );
}

  Widget _buildPriceField() {
    return Container(
      width: 350,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.secondary, AppColors.onBackground],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: finalPriceController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Wycena końcowa (zł)',
          border: OutlineInputBorder(),
          filled: true,
          fillColor: AppColors.onPrimary,
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.onSurface,
        foregroundColor: Colors.white,
        fixedSize: const Size(200, 40),
      ),
      onPressed: () async {
        if (selectedService == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Wybierz usługę')),
          );
          return;
        }

        if (finalPriceController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Podaj wycenę')),
          );
          return;
        }

        try {
          await _apiService.confirmAppointment(widget.appointmentId);

          Navigator.pop(context);

        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      },
      child: const Text("Potwierdź ofertę"),
    );
  }

  @override
  void dispose() {
    finalPriceController.dispose();
    super.dispose();
  }
}