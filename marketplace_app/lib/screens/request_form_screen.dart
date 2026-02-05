import 'package:flutter/material.dart';
import 'package:marketplace_app/screens/login_register_screen.dart';
import 'package:marketplace_app/services/api_service.dart';
import '../../screens/request_success_screen.dart';
import '../../theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../models/specialist.dart';
import '../../models/appointment.dart';

class RequestFormScreen extends StatefulWidget {
  final String categoryName;

  const RequestFormScreen({super.key, required this.categoryName});

  @override
  State<RequestFormScreen> createState() => _RequestFormScreenState();
}

class _RequestFormScreenState extends State<RequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final TextEditingController addressController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  late List<Category> categories;
  String? selectedCategory;

  List<Specialist> specialists = [];
  Specialist? selectedSpecialist;

  List<SpecialistService> services = [];
  SpecialistService? selectedService;

  @override
  void initState() {
    super.initState();
    categories = MockData.getCategories();
    selectedCategory = widget.categoryName;
    _fetchSpecialists(); // Fetch immediately for the passed category
  }

  Future<void> _fetchSpecialists() async {
    if (selectedCategory == null) return;

    setState(() => _isLoading = true);
    try {
      final results = await ApiService().searchSpecialists(
        category: selectedCategory,
      );
      if (mounted) {
        setState(() {
          specialists = results;
          selectedSpecialist = null;
          services = [];
          selectedService = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd pobierania specjalistów: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && mounted) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
    );

    if (picked != null && mounted) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Formularz rezerwacji"),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          if (!ApiService().isLoggedIn)
            IconButton(
              icon: const Icon(
                Icons.person_outline,
                color: AppColors.onBackground,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginRegisterScreen(),
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCategoryDropdown(),
                    const SizedBox(height: 12),

                    if (specialists.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          "Brak dostępnych specjalistów w tej kategorii.",
                        ),
                      )
                    else
                      _buildSpecialistDropdown(),

                    const SizedBox(height: 12),

                    _buildServiceDropdown(),
                    const SizedBox(height: 12),

                    if (selectedService != null) ...[
                      Text(
                        "Czas trwania: ${selectedService!.durationMinutes} min, Cena: ${selectedService!.price} PLN",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    const Divider(),
                    const SizedBox(height: 12),

                    Text("Termin wizyty", style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: _buildDateField(
                            label: 'Data',
                            value: selectedDate != null
                                ? '${selectedDate!.day}.${selectedDate!.month}.${selectedDate!.year}'
                                : null,
                            onTap: _pickDate,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDateField(
                            label: 'Godzina',
                            value: selectedTime?.format(context),
                            onTap: _pickTime,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: addressController,
                      label: 'Adres wizyty (dla wizyt domowych)',
                      // Optional
                    ),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: notesController,
                      label: 'Uwagi dla specjalisty',
                      maxLines: 4,
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        child: const Text('Zarezerwuj wizytę'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedSpecialist == null ||
        selectedService == null ||
        selectedDate == null ||
        selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Proszę uzupełnić wszystkie pola (Specjalista, Usługa, Termin)',
          ),
        ),
      );
      return;
    }

    if (!ApiService().isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Musisz być zalogowany, aby umówić wizytę.'),
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginRegisterScreen()),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final startDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );

      final endDateTime = startDateTime.add(
        Duration(minutes: selectedService!.durationMinutes),
      );

      final dto = CreateAppointmentDto(
        specialistId: selectedSpecialist!.id,
        specialistServiceId: selectedService!.id,
        scheduledStart: startDateTime,
        scheduledEnd: endDateTime,
        clientAddress: addressController.text.isNotEmpty
            ? addressController.text
            : null,
        clientNotes: notesController.text.isNotEmpty
            ? notesController.text
            : null,
      );

      await ApiService().createAppointment(dto);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RequestSuccessScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Błąd rezerwacji: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(labelText: label, filled: true),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: selectedCategory,
      items: categories
          .map(
            (category) => DropdownMenuItem<String>(
              value: category.title,
              child: Text(category.title),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != selectedCategory) {
          setState(() {
            selectedCategory = value;
            // Reset dependent fields
            specialists = [];
            selectedSpecialist = null;
            services = [];
            selectedService = null;
          });
          _fetchSpecialists();
        }
      },
      validator: (value) => value == null ? 'Proszę wybrać kategorię' : null,
      decoration: const InputDecoration(labelText: 'Kategoria', filled: true),
    );
  }

  Widget _buildSpecialistDropdown() {
    return DropdownButtonFormField<Specialist>(
      initialValue: selectedSpecialist,
      items: specialists
          .map(
            (s) =>
                DropdownMenuItem<Specialist>(value: s, child: Text(s.fullName)),
          )
          .toList(),
      onChanged: (value) {
        setState(() {
          selectedSpecialist = value;
          services = value?.services ?? [];
          selectedService = null;
        });
      },
      validator: (value) => value == null ? 'Proszę wybrać specjalistę' : null,
      decoration: const InputDecoration(labelText: 'Specjalista', filled: true),
    );
  }

  Widget _buildServiceDropdown() {
    return DropdownButtonFormField<SpecialistService>(
      initialValue: selectedService,
      items: services
          .map(
            (s) => DropdownMenuItem<SpecialistService>(
              value: s,
              child: Text(s.serviceName),
            ),
          )
          .toList(),
      onChanged: selectedSpecialist == null
          ? null
          : (value) {
              setState(() {
                selectedService = value;
              });
            },
      validator: (value) => value == null ? 'Proszę wybrać usługę' : null,
      decoration: const InputDecoration(labelText: 'Usługa', filled: true),
      disabledHint: const Text("Najpierw wybierz specjalistę"),
    );
  }

  Widget _buildDateField({
    required String label,
    required String? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, filled: true),
        child: Text(value ?? ''),
      ),
    );
  }
}
