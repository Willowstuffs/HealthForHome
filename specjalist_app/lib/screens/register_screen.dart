import 'package:flutter/material.dart';
import 'package:specjalist_app/screens/login_screen.dart';
import '../theme/app_theme.dart';

import '../services/api_service.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String? selectedSpecialization;
  final List<String> specializations = [
    'Pielęgniarz',
    'Rehabilitant'
  ];
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController repeatPasswordController = TextEditingController();

  bool isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    final apiService = ApiService();

    try {
      await apiService.registerSpecialist(
      email: emailController.text.trim(),
      password: passwordController.text,
      firstName: firstNameController.text.trim(),
      lastName: lastNameController.text.trim(),
      specialization: mapSpecializationToProfession(selectedSpecialization!),
    );
    

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Konto zostało utworzone')));

      Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => LoginScreen()),
            );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.onBackground,
            AppColors.primary,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 40), // przesunięcie w dół
              _buildLogoSection(),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildDropdownField(),
                        const SizedBox(height: 16),
                        _buildTextField(firstNameController, 'Imię'),
                        const SizedBox(height: 16),
                        _buildTextField(lastNameController, 'Nazwisko'),
                        const SizedBox(height: 16),
                        _buildTextField(
                          emailController,
                          'Email',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(passwordController, 'Hasło', obscureText: true),
                        const SizedBox(height: 16),
                        _buildTextField(
                          repeatPasswordController,
                          'Powtórz hasło',
                          obscureText: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 250,
                height: 53, // wysokość przycisku
                child: ElevatedButton(
                  onPressed: isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.onSurface, 
                    foregroundColor: AppColors.surface, 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white, // biały wskaźnik
                          ),
                        )
                      : const Text(
                          'Załóż konto',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 16), // margines od dołu ekranu
            ],
          ),
        ),
      ),
    ),
  );
}


// Lista rozwijana ze specjalizacjami
  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      initialValue: selectedSpecialization,
      items: specializations
          .map((s) => DropdownMenuItem(
                value: s,
                child: Text(s),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          selectedSpecialization = value;
        });
      },
      decoration: InputDecoration(
        labelText: 'Specjalizacja',
        filled: true,
        fillColor: AppColors.onPrimary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (v) => v == null ? 'Wybierz specjalizację' : null,
    );
  }

  // Pole tekstowe
  Widget _buildTextField(TextEditingController controller, String label,
      {bool obscureText = false, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: (v) => v == null || v.isEmpty ? 'Pole wymagane' : null,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.onPrimary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
  Widget _buildLogoSection(){
    return Column(
      children: [
        Image.asset(
          'lib/images/kot.jpg',
          width: 150,
          height: 150,
          ),
          const SizedBox(height: 16),
         
      ],
    );
  }
  String mapSpecializationToProfession(String specialization) {
  switch (specialization) {
    case 'Pielęgniarz':
      return 'nurse';
    case 'Rehabilitant':
      return 'physiotherapist';
    default:
      throw Exception('Nieobsługiwana specjalizacja: $specialization');
  }
}
  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    repeatPasswordController.dispose();
    super.dispose();
  }
}
