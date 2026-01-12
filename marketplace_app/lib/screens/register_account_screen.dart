import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController repeatPasswordController =
      TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController emergencyContactController =
      TextEditingController();
  DateTime? dateOfBirth;

  bool isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final apiService = ApiService();

    try {
      await apiService.register(
        email: emailController.text.trim(),
        password: passwordController.text,
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        phoneNumber: phoneController.text.isNotEmpty
            ? phoneController.text.trim()
            : null,
        dateOfBirth: dateOfBirth,
        address: addressController.text.isNotEmpty
            ? addressController.text.trim()
            : null,
        emergencyContact: emergencyContactController.text.isNotEmpty
            ? emergencyContactController.text.trim()
            : null,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Konto zostało utworzone')));

      Navigator.pop(context); // np. do logowania / success screen
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => dateOfBirth = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rejestracja')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(
                controller: firstNameController,
                label: 'Imię',
                validator: (v) => v == null || v.isEmpty ? 'Podaj imię' : null,
              ),
              const SizedBox(height: 12),

              _buildTextField(
                controller: lastNameController,
                label: 'Nazwisko',
                validator: (v) =>
                    v == null || v.isEmpty ? 'Podaj nazwisko' : null,
              ),
              const SizedBox(height: 12),

              _buildTextField(
                controller: phoneController,
                label: 'Telefon (opcjonalnie)',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),

              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Data urodzenia (opcjonalnie)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    dateOfBirth != null
                        ? "${dateOfBirth!.day.toString().padLeft(2, '0')}.${dateOfBirth!.month.toString().padLeft(2, '0')}.${dateOfBirth!.year}"
                        : 'Wybierz datę',
                  ),
                ),
              ),
              const SizedBox(height: 12),

              _buildTextField(
                controller: addressController,
                label: 'Adres (opcjonalnie)',
                maxLines: 2,
              ),
              const SizedBox(height: 12),

              _buildTextField(
                controller: emergencyContactController,
                label: 'Kontakt awaryjny (opcjonalnie)',
                maxLines: 2,
              ),
              const SizedBox(height: 12),

              _buildTextField(
                controller: emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Podaj email';
                  }
                  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                  if (!emailRegex.hasMatch(v)) {
                    return 'Niepoprawny format email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              _buildTextField(
                controller: passwordController,
                label: 'Hasło',
                obscureText: true,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Hasło jest wymagane';
                  }
                  if (v.length < 8) {
                    return 'Hasło musi mieć minimum 8 znaków';
                  }
                  // Backend requirement: Upper, Lower, Digit, Special char
                  final passwordRegex = RegExp(
                    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^\da-zA-Z]).{8,}$',
                  );
                  if (!passwordRegex.hasMatch(v)) {
                    return 'Hasło musi zawierać wielką i małą literę, cyfrę oraz znak specjalny';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              _buildTextField(
                controller: repeatPasswordController,
                label: 'Powtórz hasło',
                obscureText: true,
                validator: (v) =>
                    v == passwordController.text ? null : 'Hasła nie są zgodne',
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _register,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Załóż konto'),
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
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        alignLabelWithHint: maxLines > 1,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
