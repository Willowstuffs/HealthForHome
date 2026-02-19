import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

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

      Navigator.pop(context);
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios_rounded, color: AppColors.onSurface),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Utwórz konto',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: AppColors.onBackground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Dołącz do naszej społeczności',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                _buildTextField(
                  controller: firstNameController,
                  label: 'Imię',
                  validator: (v) => v == null || v.isEmpty ? 'Podaj imię' : null,
                ),
                const SizedBox(height: 20),

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
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _register,
                  child: isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Załóż konto'),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: RichText(
                    text: TextSpan(
                      text: 'Masz już konto? ',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      children: [
                        TextSpan(
                          text: 'Zaloguj się',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    )
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: TextStyle(fontSize: 16, color: AppColors.onSurface),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.accent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.accent, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            hintStyle: TextStyle(color: AppColors.textSecondary),
            alignLabelWithHint: maxLines > 1,
          ),
        ),
      ],
    );
  }
}
