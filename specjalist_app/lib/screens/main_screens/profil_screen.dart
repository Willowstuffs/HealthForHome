import 'package:flutter/material.dart';
import 'package:specjalist_app/screens/edit_profile_info.dart';
import 'package:specjalist_app/screens/home_screen.dart';
import 'package:specjalist_app/services/user_profile.dart';
import '../../theme/app_theme.dart';

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
  return Container(
    color: AppColors.background,
    child: Center(
      child: isLoading
          ? const CircularProgressIndicator()
          : SingleChildScrollView(
            padding: const EdgeInsets.only(top: 50),
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
                                AppColors.secondary,
                                AppColors.onBackground,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12), 
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
  final firstName = UserSession.firstName ?? '';
  final lastName = UserSession.lastName ?? '';
  final email = UserSession.email ?? '';
  final areas = UserSession.profile?.serviceAreas;
  final avatarPath = UserSession.profile?.avatarUrl;

  // Korzystamy z portu HTTPS, bo mamy HttpOverrides w main.dart
  const String baseUrl = "https://192.168.100.24:7026"; 
  
  final String? fullAvatarUrl = (avatarPath != null && avatarPath.isNotEmpty)
      ? (avatarPath.startsWith('http') ? avatarPath : '$baseUrl$avatarPath')
      : null;
   return ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 400),
    child: Column(
      children: [
        const SizedBox(height: 16),
         Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: CircleAvatar(
              radius: 50,
              backgroundImage: fullAvatarUrl != null 
                ? NetworkImage(fullAvatarUrl) 
                : null,
            child: fullAvatarUrl == null 
                ? const Icon(Icons.person, size: 50, color: Colors.white) 
                : null,
            ),
          ),

        _buildInfoCard(
          title: 'Imię',
          content: firstName,
        ),

        _buildInfoCard(
          title: 'Nazwisko',
          content: lastName,
        ),

        _buildInfoCard(
          title: 'Email',
          content: email,
        ),

        _buildInfoCard(
          title: 'Zasięg pracy',
          content: (areas == null || areas.isEmpty)
              ? 'Nie ustawiono zasięgu pracy'
              : areas.map((a) => '${a.city} – ${a.maxDistanceKm} km').join('\n'),
        ),


        const SizedBox(height: 16),

        
        const SizedBox(height: 16),
        _buildButton('Edytuj', () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditProfilScreen()),
          );
        }),
        _buildButton('Zmień hasło', () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfilScreen()),
          );
        }),
        _buildButton('Wyloguj się', () {
          UserSession.clear();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }),
      ],
    ),
  );
}


Widget _buildInfoCard({required String title, required String content}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
     child: SizedBox(
      width: 350,
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
              Text(
                  title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                content,
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
       ),
    ),
  );
}
Widget _buildButton(String text, VoidCallback onPressed) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.onSurface,
        foregroundColor: Colors.white,
        fixedSize: const Size(125, 40),
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