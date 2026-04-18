import 'package:flutter/material.dart';
import 'package:marketplace_app/screens/login_register_screen.dart';
import 'package:marketplace_app/services/api_service.dart';
import '../../screens/request_success_screen.dart';
import '../../theme/app_theme.dart';
import '../../data/mock_data.dart';
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
    categories = MockData.getCategories();
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
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      initialDateRange: selectedDateFrom != null && selectedDateTo != null
          ? DateTimeRange(start: selectedDateFrom!, end: selectedDateTo!)
          : null,
    );

    if (picked != null && mounted) {
      setState(() {
        selectedDateFrom = picked.start;
        selectedDateTo = picked.end.add(const Duration(hours: 23, minutes: 59));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
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
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),

                    _buildSectionTitle(theme, "Dane kontaktowe"),
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

                    _buildSectionTitle(theme, "Szczegóły zgłoszenia"),
                    const SizedBox(height: 12),

                    _buildCategoryDropdown(),
                    const SizedBox(height: 12),

                    Text(
                      "Termin realizacji",
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),

                    _buildDateField(
                      label: 'Zakres dat',
                      value: selectedDateFrom != null && selectedDateTo != null
                          ? '${selectedDateFrom!.day}.${selectedDateFrom!.month} - ${selectedDateTo!.day}.${selectedDateTo!.month}.${selectedDateTo!.year}'
                          : 'Wybierz daty',
                      onTap: _pickDateRange,
                    ),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: addressController,
                      label: 'Adres (miasto/dzielnica)',
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Podaj adres' : null,
                    ),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: notesController,
                      label: 'Opis problemu / wymagania',
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
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
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

    final categoryKey = MockData.categoryMapping[selectedCategory];
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
