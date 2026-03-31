import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../main_screens/maintoolbar_screen.dart';



class WaitingScreen extends StatefulWidget {
  const WaitingScreen({super.key});

   @override
  State<WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen> {

  @override
  void initState() {
    super.initState();
    _waitForVerification();
  }

  Future<void> _waitForVerification() async {
    try {
    // TODO: w przyszłości:
      // while (true) {
      //   final status = await apiService.getVerificationStatus();
      //   if (status == 'approved') break;
      //   await Future.delayed(const Duration(seconds: 5));
      // }

      // ⏳ symulacja oczekiwania na ACCEPT
      await Future.delayed(const Duration(seconds: 10));

   if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
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
            'aktualny stan: oczekujący',
          

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
    
    super.dispose();
  }
}
