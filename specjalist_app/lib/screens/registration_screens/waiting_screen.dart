import 'package:flutter/material.dart';
import 'package:specjalist_app/services/api_service.dart';
import '../../theme/app_theme.dart';
import '../main_screens/maintoolbar_screen.dart';
import 'dart:async';



class WaitingScreen extends StatefulWidget {
  const WaitingScreen({super.key});

   @override
  State<WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen> {
Timer? _timer;
  String _status = "oczekujący";

  @override
  void initState() {
    super.initState();
    _startCheckingStatus();
  }

  void _startCheckingStatus() {
    _checkVerification(); // od razu
    _timer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkVerification(),
    );
  }

  Future<void> _checkVerification() async {
    try {
      final apiService = ApiService();

      final profile = await apiService.getProfile();

      if (!mounted) return;

      final bool isVerified =
          profile['isVerified'] == true ||
          profile['IsVerified'] == true;

      setState(() {
        _status = isVerified ? "zaakceptowany" : "oczekujący";
      });

      /// ✅ JEŚLI ZATWIERDZONY → WPUSZCZAMY
      if (isVerified) {
        _timer?.cancel();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
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
              
              const SizedBox(height: 16), // margines od dołu ekranu
            ],
          ),
        ),
      ),
    ),
  );
}


// Lista rozwijana ze specjalizacjami
 
  Widget _buildLogoSection(){
    return Column(
      children: [
        Image.asset(
          'lib/images/aaa.png',
          width: 150,
          height: 150,
          ),
          const SizedBox(height: 16),
         Text(
            'Oczekiwanie na potwierdzenie \n'
            'Jeśli twoje konto zostanie zaakceptowane to \n zostaniesz przepuszczony do aplikacji \n '
            'aktualny stan: $_status',
          

            style: Theme.of(context).textTheme.headlineLarge!.copyWith(
              fontSize: 30,
              color: AppColors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
   @override
  void dispose() {
    _timer?.cancel(); // 🔥 bardzo ważne
    super.dispose();
  }
}
