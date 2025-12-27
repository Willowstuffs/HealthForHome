import 'package:flutter/material.dart';
import 'package:marketplace_app/screens/login_register_screen.dart';
import '../../screens/request_success_screen.dart';
import '../../theme/app_theme.dart';
import '../../data/mock_data.dart';

class RequestFormScreen extends StatefulWidget {
  final String categoryName;

  const RequestFormScreen({super.key, required this.categoryName});

  @override
  State<RequestFormScreen> createState() => _RequestFormScreenState();
}

class _RequestFormScreenState extends State<RequestFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  DateTime? fromDate;
  DateTime? toDate;

  late List<Category> categories;
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    categories = MockData.getCategories();
    selectedCategory = widget.categoryName;
  }

  Future<void> _pickDate({
    required bool isFrom,
    required StateSetter stateSetter,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      stateSetter(() {
        if (isFrom) {
          fromDate = picked;
        } else {
          toDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Formularz zgłoszeniowy"),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.person_outline,
              color: AppColors.onBackground,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => LoginRegisterScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildCategoryDropdown(),
              const SizedBox(height: 12),

              _buildDropdown(label: 'Usługi', value: null),
              const SizedBox(height: 12),

              _buildTextField(
                controller: addressController,
                label: 'Adres zamieszkania',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Proszę wypełnić wszystkie wymagane pola';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              _buildTextField(
                controller: phoneController,
                label: 'Telefon',
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Proszę wypełnić wszystkie wymagane pola';
                  }
                  if (value.contains(RegExp(r'[A-Za-z]'))) {
                    return 'Numer telefonu nie może zawierać liter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              _buildTextField(
                controller: emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Proszę wypełnić wszystkie wymagane pola';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              _buildTextField(
                controller: nameController,
                label: 'Imię (opcjonalne)',
              ),
              const SizedBox(height: 20),

              Align(
                alignment: Alignment.centerLeft,
                child: Text('Wybierz datę:', style: theme.textTheme.titleSmall),
              ),
              const SizedBox(height: 8),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: FormField<DateTime>(
                      validator: (value) {
                        if (fromDate == null) {
                          return 'Proszę wybrać datę';
                        }
                        if (toDate != null && fromDate!.isAfter(toDate!)) {
                          return 'Data "od" musi być przed datą "do"';
                        }
                        return null;
                      },
                      builder: (FormFieldState<DateTime> state) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDateField(
                              label: 'od',
                              date: fromDate,
                              onTap: () async {
                                await _pickDate(
                                  isFrom: true,
                                  stateSetter: setState,
                                );
                                state.didChange(fromDate);
                                _formKey.currentState?.validate();
                              },
                            ),
                            if (state.hasError)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 5,
                                  left: 12,
                                ),
                                child: Text(
                                  state.errorText!,
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FormField<DateTime>(
                      validator: (value) {
                        if (toDate == null) {
                          return 'Proszę wybrać datę';
                        }
                        return null;
                      },
                      builder: (FormFieldState<DateTime> state) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDateField(
                              label: 'do',
                              date: toDate,
                              onTap: () async {
                                await _pickDate(
                                  isFrom: false,
                                  stateSetter: setState,
                                );
                                state.didChange(toDate);
                                _formKey.currentState?.validate();
                              },
                            ),
                            if (state.hasError)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 5,
                                  left: 12,
                                ),
                                child: Text(
                                  state.errorText!,
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: notesController,
                label: 'Uwagi',
                maxLines: 4,
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RequestSuccessScreen(),
                        ),
                      );
                    }
                  },
                  child: const Text('Wyślij zapytanie'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
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
        setState(() {
          selectedCategory = value;
        });
      },
      validator: (value) => value == null ? 'Proszę wybrać kategorię' : null,
      decoration: InputDecoration(
        labelText: 'Kategoria',
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildDropdown({required String label, String? value}) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: value != null
          ? [DropdownMenuItem(value: value, child: Text(value))]
          : [],
      onChanged: (_) {},
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          date != null ? '${date.day}.${date.month}.${date.year}' : '',
        ),
      ),
    );
  }
}
