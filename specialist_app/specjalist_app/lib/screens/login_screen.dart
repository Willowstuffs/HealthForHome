import 'package:flutter/material.dart';
import 'package:specjalist_app/screens/maintoolbar_screen.dart';
import '../theme/app_theme.dart';


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
    //TODO: jak wiktor stworzy api :)
    //final apiService = ApiService();

    try {
      // await apiService.login(
      //   email: emailController.text.trim(),
      //   password: passwordController.text,
      // );

       if (!mounted) return;

    
    
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
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
                       
                        _buildTextField(
                          emailController,
                          'Email',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(passwordController, 'Hasło', obscureText: true),
                        const SizedBox(height: 16),
                        
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
                  onPressed: isLoading ? null : _login,
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
                          'Zaloguj się',
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
    emailController.dispose();
    passwordController.dispose();
    
    super.dispose();
  }
}
