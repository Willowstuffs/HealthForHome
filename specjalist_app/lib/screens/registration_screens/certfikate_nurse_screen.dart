import 'package:flutter/material.dart';
import 'package:specjalist_app/screens/registration_screens/waiting_screen.dart';
import 'package:specjalist_app/theme/widgets/auth_scaffold.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';


class CertyficateNurseScreen extends StatefulWidget {
  const CertyficateNurseScreen({super.key});

  @override
  State<CertyficateNurseScreen> createState() => _CertyficateNurseScreenState();
}

class _CertyficateNurseScreenState extends State<CertyficateNurseScreen> {
  final _formKey = GlobalKey<FormState>();
  
  
  final TextEditingController pwzController = TextEditingController();

  bool isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    final apiService = ApiService();

    try {
      await apiService.certyficatenurse(
        licenseNumber: pwzController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Konto zostało utworzone')));

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
              'Weryfikacja PWZ',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Aby dokończyć rejestrację, musimy zweryfikować Twoje uprawnienia zawodowe. Podaj numer Prawa Wykonywania Zawodu.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildTextField(
              pwzController,
              'Numer PWZ',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            _buildVerifyButton(),
            const SizedBox(height: 16),
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
      textInputAction: TextInputAction.done, // Zamyka klawiaturę po wpisaniu
      validator: (v) {
        if (v == null || v.isEmpty) {
          return 'Pole wymagane';
        }
        if (v.length < 5) {
          return 'Numer PWZ jest za krótki';
        }
        return null;
      },
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
    pwzController.dispose();
    super.dispose();
  }
}