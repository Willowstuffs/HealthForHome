import 'package:flutter/material.dart';
import 'package:specjalist_app/screens/main_screens/maintoolbar_screen.dart';
import 'package:specjalist_app/services/user_profile.dart';
import '../../theme/app_theme.dart';
import '../services/api_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class EditProfilScreen extends StatefulWidget {
  const EditProfilScreen({super.key});

  @override
  State<EditProfilScreen> createState() => _EditProfilScreenState();
}

class _EditProfilScreenState extends State<EditProfilScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController areaController = TextEditingController();
  final TextEditingController postalCodeController = TextEditingController();
  File? _selectedImage;
  bool isLoading = true;
@override
 void initState() {
    super.initState();
    _loadProfile();
  }
    Future<void> _loadProfile() async {
    setState(() => isLoading = true);
    try {
      final api = ApiService();
      final profileData = await api.getProfile();
      UserSession.setProfileFromApi(profileData);

      // Wypełnianie kontrolerów
      firstNameController.text = UserSession.profile?.firstName ?? '';
      lastNameController.text = UserSession.profile?.lastName ?? '';
      emailController.text = UserSession.profile?.email ?? '';
      phoneController.text = UserSession.profile?.phone ?? '';
      cityController.text =
          UserSession.profile?.serviceAreas?.first.city ?? '';
      postalCodeController.text = UserSession.profile?.postalCode ?? '';
      areaController.text =
          UserSession.profile?.serviceAreas?.first.maxDistanceKm.toString() ?? '';
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd pobierania profilu: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }
  Future<void> _saveProfile() async {
    final cityValue = cityController.text.trim();
    final postalValue = postalCodeController.text.trim();
    final distanceValue = int.tryParse(areaController.text.trim()) ?? 0;

    if (cityValue.isEmpty || distanceValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Wprowadź poprawne dane: miasto, kod pocztowy i zasięg pracy')),
      );
      return;
    }

    try {
      setState(() => isLoading = true);
      final api = ApiService();
      print("Zapisuję profil...");
      // Aktualizacja profilu (dane i avatar)
      await api.updateProfile(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        email: emailController.text.trim(),
        phoneNumber: phoneController.text.trim(),
        avatar: _selectedImage, // przesyłamy wybrane zdjęcie
      );
      print("Profil zapisany!");
      // Aktualizacja obszaru
      await api.updateArea({
        "city": cityValue,
        "postalCode": postalValue,
        "maxDistanceKm": distanceValue,
      });

      // Pobranie zaktualizowanego profilu i zapis do UserSession
      final updatedProfile = await api.getProfile();
      UserSession.setProfileFromApi(updatedProfile);

      setState(() {}); // odśwież UI


      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil został zaktualizowany!')),
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


@override
Widget build(BuildContext context) {
  return Scaffold(
  backgroundColor: AppColors.onBackground,
  body: isLoading
      ? const Center(child: CircularProgressIndicator())
      : SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 50),
          child: Center(
            child: Container(
              width: 350, // ograniczenie szerokości
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background,
                    AppColors.onBackground,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _buildSection(),
            ),
          ),
        ),
);

      
    
  }
Widget _buildSection() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildAvatarSection(),
          _buildEditableCard('Imię', firstNameController),
          _buildEditableCard('Nazwisko', lastNameController),
          _buildEditableCard('Email', emailController),
          _buildEditableCard('Telefon', phoneController),
          _buildEditableCard('Miasto', cityController),
          _buildEditableCard('Zasięg pracy (km)', areaController,
              keyboardType: TextInputType.number),
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
 Widget _buildAvatarSection() {
  ImageProvider? avatarImage;
  
  const String baseUrl = "https://192.168.100.24:7026";

  if (_selectedImage != null) {
    avatarImage = FileImage(_selectedImage!);
  } else if (UserSession.profile?.avatarUrl != null) {
    final String url = UserSession.profile!.avatarUrl!;
    
    final String fullUrl = url.startsWith('http') ? url : '$baseUrl$url';
    avatarImage = NetworkImage(fullUrl);
  }

  return Column(
    children: [
      CircleAvatar(
        radius: 50,
        backgroundColor: Colors.grey[300],
        backgroundImage: avatarImage,
        // Jeśli nie ma ani wybranego zdjęcia, ani zapisanego na serwerze, pokaż ikonę
        child: avatarImage == null 
            ? const Icon(Icons.person, size: 50, color: Colors.white) 
            : null,
      ),
      const SizedBox(height: 8),
      TextButton.icon(
        onPressed: _pickImage,
        icon: const Icon(Icons.photo_library),
        label: const Text('Zmień zdjęcie'),
        style: TextButton.styleFrom(foregroundColor: Colors.white),
      ),
    ],
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
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    cityController.dispose();
    areaController.dispose();
    postalCodeController.dispose();
    super.dispose();
  }
}