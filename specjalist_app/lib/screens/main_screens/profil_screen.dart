import 'package:flutter/material.dart';
import 'package:specjalist_app/screens/edit_profile_info.dart';
import 'package:specjalist_app/screens/home_screen.dart';
import 'package:specjalist_app/services/user_profile.dart';
import '../../theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {

  bool isLoading = true;
@override
void initState() {
  super.initState();
  _fetchData();
}

Future<void> _fetchData() async {
  setState(() {
    isLoading = false; 
  });
}
 
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: AppColors.surface,
    body: SafeArea(
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),

                  const SizedBox(height: 32),

                  _buildSectionTitle(
                    'Informacje o profilu',
                    Icons.person_outline,
                  ),

                  const SizedBox(height: 16),

                  _buildProfileCard(),
                ],
              ),
            ),
    ),
  );
}
Widget _buildHeader() {
  final firstName = UserSession.firstName ?? '';

  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.surfaceContainerHighest,
          AppColors.surfaceContainerHighest.withValues(alpha: 0.7),
        ],
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            firstName.isNotEmpty ? firstName : 'Twój profil',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.person, color: Colors.white),
        )
      ],
    ),
  );
}
Widget _buildSectionTitle(String title, IconData icon) {
  return Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      const SizedBox(width: 12),
      Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    ],
  );
}
Widget _buildProfileCard() {
  final firstName = UserSession.firstName ?? '';
  final lastName = UserSession.lastName ?? '';
  final email = UserSession.email ?? '';
  final areas = UserSession.profile?.serviceAreas;
  final avatarPath = UserSession.profile?.avatarUrl;

  const baseUrl = "https://192.168.100.24:7026";

  final String? fullAvatarUrl =
      (avatarPath != null && avatarPath.isNotEmpty)
          ? (avatarPath.startsWith('http')
              ? avatarPath
              : '$baseUrl$avatarPath')
          : null;

  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainer,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.outlineVariant),
    ),
    child: Column(
      children: [

        CircleAvatar(
          radius: 48,
          backgroundImage:
              fullAvatarUrl != null ? NetworkImage(fullAvatarUrl) : null,
          child: fullAvatarUrl == null
              ? const Icon(Icons.person, size: 48)
              : null,
        ),

        const SizedBox(height: 24),

        _buildInfoRow('Imię', firstName),
        _buildInfoRow('Nazwisko', lastName),
        _buildInfoRow('Email', email),

        _buildInfoRow(
          'Zasięg pracy',
          (areas == null || areas.isEmpty)
              ? 'Nie ustawiono'
              : areas
                  .map((a) => '${a.city} – ${a.maxDistanceKm} km')
                  .join('\n'),
        ),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EditProfilScreen(),
                ),
              );
            },
            child: const Text('Edytuj profil'),
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {},
            child: const Text('Zmień hasło'),
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _logout,
            child: const Text('Wyloguj się'),
          ),
        ),
      ],
    ),
  );
}
Future<void> _logout() async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.clear();

  UserSession.clear();

  //await NotificationService().deleteTokenFromServer();

  if (!mounted) return;

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const HomeScreen()),
    (route) => false,
  );
}
Widget _buildInfoRow(String title, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    ),
  );
}
  @override
  void dispose() {
    super.dispose();
  }
}