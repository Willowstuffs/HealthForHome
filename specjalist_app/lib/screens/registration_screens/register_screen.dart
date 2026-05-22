import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:specjalist_app/services/notification_services.dart';
import '../registration_screens/verify_code_scren.dart';
import '../../theme/app_theme.dart';
import '../../theme/widgets/auth_scaffold.dart';
import '../../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool acceptedPrivacy = false;
  bool acceptedTerms = false;
  bool acceptedLocation = false;  

  bool isLoading = false;

  Future<void> _register() async {
    final prefs = await SharedPreferences.getInstance();

    final fcmToken = prefs.getString('fcm_token');

    if (fcmToken == null || fcmToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nie udało się pobrać tokena powiadomień'),
        ),
      );
      return;
    }
    await NotificationService().uploadTokenToServer();
    if (!_formKey.currentState!.validate()) return;
    if (passwordController.text != repeatPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hasła nie są identyczne!')),
      );
      return;
    }
    if (!acceptedPrivacy || !acceptedTerms || !acceptedLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Musisz zaakceptować wszystkie zgody'),
        ),
      );
      return;
    }
    setState(() => isLoading = true);
    final apiService = ApiService();

    try {
      await apiService.registerSpecialist(
        email: emailController.text.trim(),
        password: passwordController.text,
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        specialization: mapSpecializationToProfession(
          selectedSpecialization!,
        ),
        fcmToken: fcmToken,
      );
    

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Konto zostało utworzone')));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyCodeScreen(
            email: emailController.text.trim(),
          ),
        ),
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
  Future<void> _openUrl(String url) async {
  final uri = Uri.parse(url);

  if (!await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  )) {
    throw Exception('Nie można otworzyć strony');
  }
}
@override
Widget build(BuildContext context) {
  return AuthScaffold(
    child: Form(
      key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            const SizedBox(height: 40),

            const Text(
              "Utwórz konto",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
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
            _buildTextField(
              passwordController,
              'Hasło',
              obscureText: true
            ),
            const SizedBox(height: 16),
            _buildTextField(
              repeatPasswordController,
              'Powtórz hasło',
              obscureText: true,
            ),
            const SizedBox(height: 16),
            _buildLegalCheckboxes(),
            const SizedBox(height: 24),
            SizedBox(
              width: 250,
              height: 53, // wysokość przycisku
              child: ElevatedButton(
                onPressed: isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary, 
                    foregroundColor: AppColors.livingColor10, 
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
      setState(() => selectedSpecialization = value);
    },
    validator: (v) => v == null ? 'Wybierz specjalizację' : null,
    decoration: InputDecoration(
      labelText: 'Specjalizacja',
      filled: true,
      fillColor: AppColors.onPrimary,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}

  // Pole tekstowe
  Widget _buildTextField(TextEditingController controller, String label,
      {bool obscureText = false, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
       textInputAction: TextInputAction.next,
        style: const TextStyle(fontSize: 16),
      validator: (v) => v == null || v.isEmpty ? 'Pole wymagane' : null,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.onPrimary,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 16,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
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
Widget _buildLegalCheckboxes() {
  return Column(
    children: [

      /// PRIVACY
      _legalCheckbox(
        value: acceptedPrivacy,
        onChanged: (v) => setState(() => acceptedPrivacy = v ?? false),
        text: 'Polityką prywatności',
        url: 'https://admin.makolino.com/legal/privacy',
      ),

      /// TERMS
      _legalCheckbox(
        value: acceptedTerms,
        onChanged: (v) => setState(() => acceptedTerms = v ?? false),
        text: 'Regulaminem specjalisty',
        url: 'https://admin.makolino.com/legal/terms-specialist',
      ),

      /// LOCATION
      _legalCheckbox(
        value: acceptedLocation,
        onChanged: (v) => setState(() => acceptedLocation = v ?? false),
        text: 'Zasadami lokalizacji',
        url: 'https://admin.makolino.com/legal/location',
      ),
    ],
  );
}
Widget _legalCheckbox({
  required bool value,
  required ValueChanged<bool?> onChanged,
  required String text,
  required String url,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Checkbox(
        value: value,
        onChanged: onChanged,
      ),
      Expanded(
        child: GestureDetector(
          onTap: () => _openUrl(url),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black87),
              children: [
                const TextSpan(text: 'Zapoznałem się z '),
                TextSpan(
                  text: text,
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
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
