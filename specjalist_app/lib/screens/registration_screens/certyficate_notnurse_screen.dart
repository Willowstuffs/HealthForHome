import 'package:flutter/material.dart';
import 'package:specjalist_app/screens/registration_screens/waiting_screen.dart';
import '../../theme/app_theme.dart';


class CertyficateNotnurseScreen extends StatefulWidget {
  const CertyficateNotnurseScreen({super.key});

  @override
  State<CertyficateNotnurseScreen> createState() => _CertyficateNotnurseScreenState();
}

class _CertyficateNotnurseScreenState extends State<CertyficateNotnurseScreen> {
  final _formKey = GlobalKey<FormState>();
  
  
  final TextEditingController nipController = TextEditingController();
  final TextEditingController registrationbooknumberController = TextEditingController();
  final TextEditingController provinceController = TextEditingController();
  final TextEditingController townController = TextEditingController();
  final TextEditingController streetController = TextEditingController();

  bool isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    //TODO: jak wiktor stworzy api :)
    //final apiService = ApiService();

    try {
      // await apiService.register(
      //   email: emailController.text.trim(),
      //   password: passwordController.text,
      //   firstName: firstNameController.text.trim(),
      //   lastName: lastNameController.text.trim(),
      // );

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
  return Scaffold(
    body: Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.surface,
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
                        const SizedBox(height: 16),
                        _buildTextField(nipController, 'by dokończyć rejsetracje podaj \n NIP'),
                        const SizedBox(height: 16),
                        _buildTextField(registrationbooknumberController, 'Numer Księgi Rejestrowej'),
                        const SizedBox(height: 16),
                        _buildTextField(provinceController,'Województwo'),
                        const SizedBox(height: 16),
                        _buildTextField(townController, 'Miasto'),
                        const SizedBox(height: 16),
                        _buildTextField(streetController,'Ulica'),
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
                          'Zweryfikuj',
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
  @override
  void dispose() {
    nipController.dispose();
    registrationbooknumberController.dispose();
    provinceController.dispose();
    townController.dispose();
    streetController.dispose();
    super.dispose();
  }
}
