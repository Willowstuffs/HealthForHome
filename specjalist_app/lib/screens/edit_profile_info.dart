import 'package:flutter/material.dart';
import 'package:specjalist_app/screens/main_screens/maintoolbar_screen.dart';
import 'package:specjalist_app/services/user_profile.dart';
import '../../theme/app_theme.dart';
import '../services/api_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/app_refresh_service.dart';

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
      UserSession.setProfileFromApi(profileData, UserSession.token ?? '');

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
      UserSession.setProfileFromApi(updatedProfile,UserSession.token ?? '');
      AppRefreshService().refresh();
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
    backgroundColor: AppColors.surface,
    appBar: AppBar(
      title: const Text("Edytuj profil"),
      centerTitle: true,
    ),
    body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    _buildAvatarSection(),
                    const SizedBox(height: 24),

                    _buildEditableCard("Imię", firstNameController),
                    _buildEditableCard("Nazwisko", lastNameController),
                    _buildEditableCard("Email", emailController),
                    _buildEditableCard("Telefon", phoneController),
                    _buildEditableCard("Miasto", cityController),
                    _buildEditableCard(
                      "Zasięg pracy (km)",
                      areaController,
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        child: const Text("Zapisz zmiany"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
  );
}
  Widget _buildEditableCard(
  String title,
  TextEditingController controller, {
  TextInputType? keyboardType,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: const InputDecoration(),
        ),
      ],
    ),
  );
}

Widget _buildAvatarSection() {
  ImageProvider? avatarImage;
  const String baseUrl = "https://192.168.100.24:7026";

  if (_selectedImage != null) {
    avatarImage = FileImage(_selectedImage!);
  } else if (UserSession.profile?.avatarUrl != null) {
    final url = UserSession.profile!.avatarUrl!;
    final fullUrl = url.startsWith('http') ? url : '$baseUrl$url';
    avatarImage = NetworkImage(fullUrl);
  }

  return Column(
    children: [
      Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 48,
          backgroundColor: AppColors.surfaceContainerHighest,
          backgroundImage: avatarImage,
          child: avatarImage == null
              ? Icon(
                  Icons.person,
                  size: 40,
                  color: AppColors.textSecondary,
                )
              : null,
        ),
      ),
      const SizedBox(height: 12),
      TextButton.icon(
        onPressed: _pickImage,
        icon: const Icon(Icons.photo_library_outlined),
        label: const Text("Zmień zdjęcie"),
      ),
    ],
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