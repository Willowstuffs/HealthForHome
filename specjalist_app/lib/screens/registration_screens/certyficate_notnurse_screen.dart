import 'package:flutter/material.dart';
import 'package:specjalist_app/screens/registration_screens/waiting_screen.dart';
import 'package:specjalist_app/theme/widgets/auth_scaffold.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class CertyficateNotnurseScreen extends StatefulWidget {
  const CertyficateNotnurseScreen({super.key});

  @override
  State<CertyficateNotnurseScreen> createState() =>
      _CertyficateNotnurseScreenState();
}

class _CertyficateNotnurseScreenState
    extends State<CertyficateNotnurseScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController identifierController = TextEditingController();

  bool isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final apiService = ApiService();

    try {
      await apiService.certyficatenurse(
        licenseNumber: identifierController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konto zostało utworzone')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WaitingScreen()),
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
    return AuthScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const Text(
              'Weryfikacja uprawnień',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'Aby dokończyć rejestrację, musimy zweryfikować Twoje uprawnienia zawodowe.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 32),
            _buildTextField(
              identifierController,
              'Podaj NIP lub Numer Księgi Rejestrowej',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            const Text(
              "Wpisz 10 cyfr dla NIP lub 12 dla numeru księgi",
              style: TextStyle(fontSize: 12, color: Colors.white54),
            ),
            const SizedBox(height: 32),
            _buildVerifyButton(),
          ],
        ),
      ),
    );
  }
  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: (v) {
        if (v == null || v.isEmpty) {
          return 'Wypełnij pole';
        }
        final cleanValue = v.replaceAll(RegExp(r'[\s-]'), '');

        if (cleanValue.length != 10 && cleanValue.length != 12) {
          return 'Wprowadź poprawny NIP (10 cyfr) lub Nr Księgi (12 cyfr)';
        }

        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.onPrimary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
        ),
      ),
    );
  }
  Widget _buildVerifyButton() {
    return SizedBox(
      width: 250,
      height: 53,
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
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Zweryfikuj',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
 

  @override
  void dispose() {
    identifierController.dispose();
    super.dispose();
  }
}