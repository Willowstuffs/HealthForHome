import 'package:flutter/material.dart';
import '../registration_screens/verify_code_scren.dart';
import '../../theme/app_theme.dart';
import '../../theme/widgets/auth_scaffold.dart';
import '../../services/api_service.dart';


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
  bool acceptedTerms = false;

  bool isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (passwordController.text != repeatPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hasła nie są identyczne!')),
      );
      return;
    }
    if (!acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Musisz zaakceptować regulamin')),
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
      specialization: mapSpecializationToProfession(selectedSpecialization!),
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
  void _showTermsDialog() {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Regulamin',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          /// SCROLL
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_termsText),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => acceptedTerms = true);
              },
              child: const Text('Akceptuję'),
            ),
          ),
        ],
      ),
    ),
  );
}
@override
Widget build(BuildContext context) {
  return AuthScaffold(
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
            _buildTermsCheckbox(),
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
       textInputAction: TextInputAction.next,
        
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
Widget _buildTermsCheckbox() {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Checkbox(
        value: acceptedTerms,
        onChanged: (value) {
          setState(() {
            acceptedTerms = value ?? false;
          });
        },
      ),
      Expanded(
        child: GestureDetector(
          onTap: _showTermsDialog,
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black87),
              children: [
                const TextSpan(text: 'Zapoznałem się z '),
                TextSpan(
                  text: 'Regulaminem',
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(text: ' i akceptuję jego treść.'),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
static const String _termsText = '''
REGULAMIN PLATFORMY MEDYCZNEJ

§1 Postanowienia ogólne
1. Platforma umożliwia kontakt pomiędzy specjalistami medycznymi a pacjentami.
2. Rejestrując konto, użytkownik potwierdza prawdziwość podanych danych.
3. Platforma nie świadczy usług medycznych – umożliwia jedynie ich organizację.

§2 Konto specjalisty
1. Konto mogą zakładać wyłącznie osoby posiadające wymagane kwalifikacje zawodowe.
2. Specjalista odpowiada za legalność wykonywanych usług.
3. Specjalista zobowiązuje się do aktualizacji danych profilu.

§3 Realizacja wizyt
1. Wizyty realizowane są bezpośrednio pomiędzy specjalistą a pacjentem.
2. Platforma nie ponosi odpowiedzialności za przebieg wizyty.
3. Specjalista odpowiada za jakość oraz bezpieczeństwo usług.

§4 Płatności
1. Wynagrodzenie ustalane jest indywidualnie pomiędzy stronami.
2. Platforma może pobierać prowizję zgodnie z cennikiem.

§5 Dane osobowe
1. Dane przetwarzane są zgodnie z RODO.
2. Dane udostępniane są wyłącznie w celu realizacji wizyty.
3. Użytkownik ma prawo dostępu, poprawiania oraz usunięcia danych.

§6 Bezpieczeństwo
1. Zabronione jest udostępnianie konta osobom trzecim.
2. Platforma może zablokować konto w przypadku naruszenia regulaminu.

§7 Odpowiedzialność
1. Platforma pełni rolę pośrednika technologicznego.
2. Odpowiedzialność za świadczenie usług medycznych ponosi specjalista.

§8 Postanowienia końcowe
1. Regulamin może być aktualizowany.
2. Korzystanie z aplikacji oznacza akceptację aktualnej wersji regulaminu.
''';
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
