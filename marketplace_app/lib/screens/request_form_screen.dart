import 'package:flutter/material.dart';
import 'package:marketplace_app/screens/login_register_screen.dart';
import 'package:marketplace_app/services/api_service.dart';
import 'package:marketplace_app/widgets/screen_status_bar.dart';
import '../../screens/request_success_screen.dart';
import '../../theme/app_theme.dart';
import '../data/data.dart';
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

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  final TextEditingController addressController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  DateTime? selectedDateFrom;
  DateTime? selectedDateTo;

  late List<Category> categories;
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    categories = Data.getCategories();
    selectedCategory = widget.categoryName;
    selectedDateFrom = DateTime.now().add(const Duration(days: 1));
    selectedDateTo = DateTime.now().add(const Duration(days: 1, hours: 2));

    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    if (ApiService().isLoggedIn) {
      try {
        final profile = await ApiService().getClientProfile();
        setState(() {
          nameController.text = '${profile.firstName} ${profile.lastName}'
              .trim();
          phoneController.text = profile.phoneNumber ?? '';
          emailController.text = profile.email;
          if (profile.address != null && addressController.text.isEmpty) {
            addressController.text = profile.address!;
          }
        });
      } catch (e) {
        // Ignore error, just don't prefill
      }
    }
  }

  Future<void> _pickDateRange() async {
    final startDate = await showDatePicker(
      context: context,
      initialDate: selectedDateFrom ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      helpText: 'Wybierz datę rozpoczęcia',
    );
    if (startDate == null || !mounted) return;

    final startTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedDateFrom ?? DateTime.now()),
      helpText: 'Wybierz godzinę rozpoczęcia',
    );
    if (startTime == null || !mounted) return;

    final endDate = await showDatePicker(
      context: context,
      initialDate: selectedDateTo ?? startDate,
      firstDate: startDate,
      lastDate: DateTime.now().add(const Duration(days: 90)),
      helpText: 'Wybierz datę zakończenia',
    );
    if (endDate == null || !mounted) return;

    final endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        selectedDateTo ?? DateTime.now().add(const Duration(hours: 1)),
      ),
      helpText: 'Wybierz godzinę zakończenia',
    );
    if (endTime == null || !mounted) return;

    setState(() {
      selectedDateFrom = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        startTime.hour,
        startTime.minute,
      );
      selectedDateTo = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        endTime.hour,
        endTime.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScreenStatusBar(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Utwórz ogłoszenie"),
          backgroundColor: AppColors.surface,
          elevation: 0,
          actions: [
            if (!ApiService().isLoggedIn)
              IconButton(
                icon: const Icon(
                  Icons.person_outline,
                  color: AppColors.onSurface,
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
                      Text(
                        "Wypełnij formularz, a specjaliści sami zgłoszą się do Ciebie.",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildSectionTitle("Dane kontaktowe"),
                      const SizedBox(height: 8),

                      _buildTextField(
                        controller: nameController,
                        label: 'Imię i nazwisko osoby kontaktowej',
                        validator: (v) {
                          if (!ApiService().isLoggedIn &&
                              (v == null || v.isEmpty)) {
                            return 'Podaj imię i nazwisko';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      _buildTextField(
                        controller: phoneController,
                        label: 'Numer telefonu',
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          if (!ApiService().isLoggedIn &&
                              (v == null || v.isEmpty)) {
                            return 'Podaj numer telefonu';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      _buildTextField(
                        controller: emailController,
                        label: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (!ApiService().isLoggedIn &&
                              (v == null || v.isEmpty)) {
                            return 'Podaj email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      const Divider(),

                      _buildSectionTitle("Szczegóły ogłoszenia"),
                      const SizedBox(height: 12),

                      _buildCategoryDropdown(),
                      const SizedBox(height: 12),

                      Text(
                        "Termin realizacji",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),

                      _buildDateField(
                        label: 'Przedział czasowy',
                        value:
                            selectedDateFrom != null && selectedDateTo != null
                            ? '${selectedDateFrom!.day.toString().padLeft(2, '0')}.${selectedDateFrom!.month.toString().padLeft(2, '0')}.${selectedDateFrom!.year} ${selectedDateFrom!.hour.toString().padLeft(2, '0')}:${selectedDateFrom!.minute.toString().padLeft(2, '0')} - '
                                  '${selectedDateTo!.day.toString().padLeft(2, '0')}.${selectedDateTo!.month.toString().padLeft(2, '0')}.${selectedDateTo!.year} ${selectedDateTo!.hour.toString().padLeft(2, '0')}:${selectedDateTo!.minute.toString().padLeft(2, '0')}'
                            : 'Wybierz daty i czas',
                        onTap: _pickDateRange,
                      ),
                      const SizedBox(height: 12),

                      _buildTextField(
                        controller: addressController,
                        label: 'Adres',
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Podaj adres' : null,
                      ),
                      const SizedBox(height: 12),

                      _buildTextField(
                        controller: notesController,
                        label: 'Opis problemu, wymagania',
                        maxLines: 4,
                        validator: (v) => v == null || v.isEmpty
                            ? 'Opisz swoje potrzeby'
                            : null,
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          child: const Text('Dodaj ogłoszenie'),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.onSurface,
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!ApiService().isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Musisz być zalogowany, aby wysłać zgłoszenie.'),
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginRegisterScreen()),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (selectedCategory == null ||
        selectedDateFrom == null ||
        selectedDateTo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uzupełnij kategorię i daty.')),
      );
      return;
    }

    final categoryKey = Data.categoryMapping[selectedCategory];
    if (categoryKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Błąd: Nie znaleziono kategorii dla wybranej usługi.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dto = CreateServiceRequestDto(
        category: categoryKey,
        description: notesController.text,
        dateFrom: selectedDateFrom!,
        dateTo: selectedDateTo!,
        address: addressController.text,
        contactName: nameController.text,
        phoneNumber: phoneController.text,
        email: emailController.text,
      );

      await ApiService().createServiceRequest(dto);

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
        ).showSnackBar(SnackBar(content: Text('Błąd: $e')));
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
        if (value != null) {
          setState(() {
            selectedCategory = value;
          });
        }
      },
      validator: (value) => value == null ? 'Proszę wybrać kategorię' : null,
      decoration: const InputDecoration(labelText: 'Kategoria', filled: true),
    );
  }

  Widget _buildDateField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, filled: true),
        child: Text(value),
      ),
    );
  }
}
