import 'package:flutter/material.dart';
import 'package:specjalist_app/screens/main_screens/maintoolbar_screen.dart';
import 'package:specjalist_app/services/user_profile.dart';
import '../../theme/app_theme.dart';
import '../services/api_service.dart';

class EditProfilScreen extends StatefulWidget {
  const EditProfilScreen({super.key});

  @override
  State<EditProfilScreen> createState() => _EditProfilScreenState();
}

class _EditProfilScreenState extends State<EditProfilScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final  TextEditingController phone = TextEditingController();
  final TextEditingController city = TextEditingController();
  final TextEditingController area = TextEditingController();
  final TextEditingController postalCode = TextEditingController();
  bool isLoading = true;
@override
void initState() {
  super.initState();
  _fetchData();
}
Future<void> _saveProfile() async {
 final cityValue = city.text.trim();
  final postalValue = postalCode.text.trim();
  final distanceValue = int.tryParse(area.text.trim()) ?? 0;

  if (cityValue.isEmpty || postalValue.isEmpty || distanceValue <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text(
              'Wprowadź poprawne dane: miasto, kod pocztowy i zasięg pracy')),
    );
    return;
  }

  final payload = {
    "city": cityValue,
    "postalCode": postalValue,
    "maxDistanceKm": distanceValue,
  };

  try {
    setState(() => isLoading = true);
    final api = ApiService();
    await api.updateArea(payload);
    final updatedServiceArea = ServiceArea(
      city: cityValue,
      maxDistanceKm: distanceValue,
    );

    // Jeśli UserSession.profile istnieje, tworzymy kopię z nowymi danymi
    if (UserSession.profile != null) {
      UserSession.profile = UserProfile(
        id: UserSession.profile!.id,
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        email: emailController.text.trim(),
        phone: phone.text.trim(),
        postalCode: postalValue,
        serviceAreas: [updatedServiceArea],
        specializations: UserSession.profile!.specializations,
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Zasięg został zaktualizowany!')),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Błąd: $e')),
    );
  } finally {
    setState(() => isLoading = false);
  }
}


Future<void> _fetchData() async {
  setState(() {
    isLoading = false; // konieczne, żeby przestało się kręcić
  });
}
 
@override
Widget build(BuildContext context) {
  return Container(
    color: AppColors.onBackground,
    child: Center(
      child: isLoading
          ? const CircularProgressIndicator()
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                    Column(
                      children: [
                        Container(
                          width: 350,
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.background,
                                AppColors.onBackground,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12), // opcjonalnie zaokrąglone rogi
                          ),
                          child: _buildSection(),
                        ),
                        
                      ],
                    )
                  ],
                ),
              ),
      ),
      
    );
  }
Widget _buildSection() {
  final areas = UserSession.profile?.serviceAreas;
  final post = UserSession.profile?.postalCode;

  // Jeśli specjalista nie ma jeszcze zdefiniowanego obszaru, inicjalizujemy
  if (areas == null || areas.isEmpty) {
    city.text = '';
    area.text = '';
    postalCode.text = '';
  } else {
    final a = areas.first;
    city.text = a.city;
    area.text = a.maxDistanceKm.toString();
    postalCode.text = post ?? '';
  }

  // Kontrolery dla pozostałych pól
  firstNameController.text = UserSession.firstName ?? '';
  lastNameController.text = UserSession.lastName ?? '';
  emailController.text = UserSession.email ?? '';
  phone.text = UserSession.phone ?? ''; // jeśli masz pole phone w profilu, wypełnij
  // np. phone.text = UserSession.profile?.phone ?? '';

  return ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 400),
    child: Column(
      children: [
        const SizedBox(height: 16),

        _buildEditableCard('Imię', firstNameController),
        _buildEditableCard('Nazwisko', lastNameController),
        _buildEditableCard('Email', emailController),
        _buildEditableCard('Telefon', phone),
        _buildEditableCard('Miasto', city),
        _buildEditableCard('Kod pocztowy', postalCode),
        _buildEditableCard('Zasięg pracy (km)', area, keyboardType: TextInputType.number),

        const SizedBox(height: 16),
        _buildButton('Zapisz'),
      ],
    ),
  );
}

// Pomocniczy widget do edytowalnych pól
Widget _buildEditableCard(String title, TextEditingController controller, {TextInputType? keyboardType}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Card(
      color: AppColors.onPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
              ),
              
            ),
          ],
        ),
      ),
    ),
  );
}
Widget _buildButton(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: ElevatedButton(
      onPressed: _saveProfile,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.onSurface,
        foregroundColor: Colors.white,
        fixedSize: const Size(125, 29),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(text),
    ),
  );
}
  @override
  void dispose() {
    super.dispose();
  }
}