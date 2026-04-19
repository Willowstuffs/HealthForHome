import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  String patientName = '';
  String startDate = '';
  String endDate = '';
  String description = '';
  DateTime? proposedDateTime;
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
    patientName = widget.patientName;
    startDate = widget.startDate;
    endDate = widget.endDate;
    description = widget.description;
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.wait([_fetchService(), _loadAppointment()]);

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _loadAppointment() async {
    try {
      final inquiries = await _apiService.getInquiries();

      final appointment = inquiries.firstWhere(
        (e) => e['appointmentId'] == widget.appointmentId,
        orElse: () => {},
      );

      if (appointment.isEmpty) {
        print("Nie znaleziono wizyty ${widget.appointmentId}");
        return;
      }
      DateTime? start = appointment['scheduledStart'] != null
          ? DateTime.tryParse(appointment['scheduledStart'])
          : (appointment['ScheduledStart'] != null
                ? DateTime.tryParse(appointment['ScheduledStart'])
                : null);

      DateTime? end = appointment['scheduledEnd'] != null
          ? DateTime.tryParse(appointment['scheduledEnd'])
          : (appointment['ScheduledEnd'] != null
                ? DateTime.tryParse(appointment['ScheduledEnd'])
                : null);
      final displayFormatter = DateFormat('dd-MM-yyyy HH:mm');
      setState(() {
        patientName =
            appointment['patientName'] ?? appointment['PatientName'] ?? '';

        startDate = start != null ? displayFormatter.format(start) : '';
        endDate = end != null ? displayFormatter.format(end) : '';

        description =
            appointment['description'] ?? appointment['Description'] ?? '';
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> _pickDateTime() async {
    if (startDate.isEmpty || endDate.isEmpty) return;

    final start = DateFormat('dd-MM-yyyy HH:mm').parse(startDate);
    final end = DateFormat('dd-MM-yyyy HH:mm').parse(endDate);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: start,
      firstDate: start,
      lastDate: end,
    );

    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null) return;

    final result = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    /// dodatkowa walidacja
    if (result.isBefore(start) || result.isAfter(end)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Termin musi mieścić się w ramach ogłoszenia"),
        ),
      );
      return;
    }

    setState(() {
      proposedDateTime = result;
    });
  }

  Future<void> _fetchService() async {
    try {
      final result = await _apiService.getServices();

      setState(() {
        services = result;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _confirmOffer() async {
    if (selectedServices.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Wybierz usługę')));
      return;
    }
    if (proposedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wybierz termin realizacji')),
      );
      return;
    }
    final price = double.tryParse(finalPriceController.text);
    if (price == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Podaj poprawną wycenę')));
      return;
    }

    try {
      final serviceIds = selectedServices.map((e) => e.id).toList();

      await _apiService.confirmAppointment(
        widget.appointmentId,
        serviceIds,
        proposedDateTime!,
        price,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,

      appBar: AppBar(title: const Text("Nowa oferta"), centerTitle: true),

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
                        _buildDateSelector(),
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

  Widget _buildDateSelector() {
    final formatter = DateFormat('dd MMM yyyy • HH:mm');

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
            "Proponowany termin",
            style: Theme.of(context).textTheme.titleMedium,
          ),

          const SizedBox(height: 16),

          InkWell(
            onTap: _pickDateTime,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_outlined),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      proposedDateTime == null
                          ? "Wybierz datę i godzinę"
                          : formatter.format(proposedDateTime!),
                    ),
                  ),

                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ],
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
          Text(patientName, style: Theme.of(context).textTheme.titleLarge),

          const SizedBox(height: 12),

          _buildInfoText("Od: $startDate"),
          _buildInfoText("Do: $endDate"),
          const SizedBox(height: 12),

          if (description.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 8),

            Text("Opis wizyty", style: Theme.of(context).textTheme.titleMedium),

            const SizedBox(height: 6),

            Text(description, style: Theme.of(context).textTheme.bodyMedium),
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
                title: Text(service.name, overflow: TextOverflow.ellipsis),
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

                    finalPriceController.text = totalPrice.toStringAsFixed(2);
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
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }

  @override
  void dispose() {
    finalPriceController.dispose();
    super.dispose();
  }
}
