import 'package:flutter/material.dart';
import 'package:specjalist_app/screens/registration_screens/login_screen.dart';
import 'package:specjalist_app/screens/registration_screens/register_screen.dart';

import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
 @override
  HomeScreenState createState() => HomeScreenState();
}
class HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
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
            colors:  [
              AppColors.primary,
              AppColors.secondary
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLogoSection(),
            const SizedBox(height: 48),
            _buildAuthButtons(),
          ],
        ),
      ),
    );
  }
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
            'Health for Home',
            style: Theme.of(context).textTheme.headlineLarge!.copyWith(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
  Widget _buildAuthButtons() {
  return Column(
    children: [
      SizedBox(
        width: 220,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => LoginScreen()),
            );
          },
          child: const Text('Zaloguj się'),
        ),
      ),

      const SizedBox(height: 16),

      SizedBox(
        width: 220,
        child: OutlinedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RegisterScreen()),
            );
          },
          child: const Text('Zarejestruj się'),
        ),
      ),
    ],
  );
}
@override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}