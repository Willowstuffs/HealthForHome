import 'package:flutter/material.dart';
import 'package:specjalist_app/screens/registration_screens/certfikate_nurse_screen.dart';
import 'package:specjalist_app/screens/registration_screens/certyficate_notnurse_screen.dart';
import 'package:specjalist_app/screens/main_screens/maintoolbar_screen.dart';
import 'package:specjalist_app/screens/registration_screens/register_screen.dart';
import 'package:specjalist_app/screens/registration_screens/waiting_screen.dart';
import 'package:specjalist_app/services/notification_services.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/token_storage.dart';
import '../../services/user_profile.dart';
import '../../theme/widgets/auth_scaffold.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    final apiService = ApiService();

    try {
      //logowanie
      final loginResponse = await apiService.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      //zapisywanie tokena
      await TokenStorage.saveTokens(
        accessToken: loginResponse.accessToken,
        refreshToken: loginResponse.refreshToken,
      );
      await NotificationService().uploadTokenToServer();
      if (!mounted) return;
      //pobieranie danych o użytkownku
      final profile = await apiService.getProfile();
      UserSession.setProfileFromApi(profile,UserSession.token ?? '');
      print("📦📦 w profile zostało zapisane $profile");
      final String specializationRaw =
        (profile['professionalTitle'] ?? '').toString().toLowerCase();

      final String specialization =
          specializationRaw.contains('nurse')
              ? 'nurse'
              : specializationRaw;

      final bool isVerified = profile['isVerified'] == true || profile['IsVerified'] == true;
      
       if (isVerified) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
         return;
       }

       final String? license = await apiService.getLicense();

      final bool hasLicense =
        license != null && license.trim().isNotEmpty;

       if (!hasLicense) {
        if (specialization == 'nurse') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const CertyficateNurseScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const CertyficateNotnurseScreen()),
          );
        }
      } else {
         Navigator.pushReplacement(
           context,
           MaterialPageRoute(builder: (_) => const WaitingScreen()),
        );
       }
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            const SizedBox(height: 40),

            const Text(
              "Zaloguj się",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),
                       
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
            const SizedBox(height: 24),
              SizedBox(
                width: 250,
                height: 53,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary, 
                    foregroundColor: AppColors.livingColor10, 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                      : const Text(
                          'Zaloguj się',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 16), 
              Center(
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RegisterScreen(),
                    ),
                  );
                },
                child: const Text(
                  "Nie masz konta? Zarejestruj się",
                  style: TextStyle(fontSize: 15),
                ),
              ),
            ),

            const SizedBox(height: 40),
            ],
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
        
      validator: (v) => v == null || v.isEmpty ? 'Pole wymagane' : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 16),
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
 
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    
    super.dispose();
  }
}
