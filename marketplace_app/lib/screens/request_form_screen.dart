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

  Future<void> _pickDate({required bool isFrom}) async {

    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days:365)),
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          fromDate = picked;
        } else {
          toDate = picked;
        }
      });
    }
  }

  bool checkFormsValidity() {
    if (_formKey.currentState!.validate()) {
      if (selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Proszę wybrać kategorię')),
        );
        return false;
      }
      if (addressController.text.isEmpty ||
          phoneController.text.isEmpty ||
          emailController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Proszę wypełnić wszystkie wymagane pola')),
        );
        return false;
      }
      if(phoneController.text.contains(RegExp(r'[A-Za-z]'))){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Numer telefonu nie może zawierać liter')),
        );
        return false;
      }
      if (fromDate == null || toDate == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Proszę wybrać daty')));
        return false;
      }
      if (fromDate!.isAfter(toDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data "od" musi być przed datą "do"')),
        );
        return false;
      }
    }
    else {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Formularz zgłoszeniowy"),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.person_outline, color: AppColors.onBackground),
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

              _buildDropdown(
                label: 'Usługi',
                value: null
                ),
              const SizedBox(height: 12),

              _buildTextField(
                controller: addressController,
                label: 'Adres zamieszkania',
              ),
              const SizedBox(height: 12),

              _buildTextField(
                controller: phoneController,
                label: 'Telefon',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),

              _buildTextField(
                controller: emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
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
                children: [
                  Expanded(
                    child: _buildDateField(
                      label: 'od',
                      date: fromDate,
                      onTap: () => _pickDate(isFrom: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateField(
                      label: 'do',
                      date: toDate,
                      onTap: () => _pickDate(isFrom: false),
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
                      // TODO: wyslanie zapytania
                      if(checkFormsValidity()) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RequestSuccessScreen(),
                          ),
                        );  
                      }                      
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
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
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
