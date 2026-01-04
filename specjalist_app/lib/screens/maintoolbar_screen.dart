import 'package:flutter/material.dart';
import 'package:specjalist_app/screens/profil_screen.dart';
import 'package:specjalist_app/screens/upcoming_screen.dart';
import '../screens/start_screen.dart';
import '../screens/work_screen.dart';
import '../theme/app_theme.dart';
// import kolejne ekrany gdy będą gotowe

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    StartScreen(), // index 0
    WorkScreen(),  // index 1
    Center(child: Text('Mapy')), // index 2
    UpcomingScreen(),// index 3
    ProfilScreen(), // index 4
  ];
  

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
     
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
    bottomNavigationBar: BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      backgroundColor: AppColors.primary,
      selectedItemColor: AppColors.onSurface,
      unselectedItemColor: Colors.white70,
      items: [
        BottomNavigationBarItem(
          icon: Image.asset(
            'lib/images/ikona1.png',
            width: 24,
            height: 24,
            color: Colors.white70,
          ),
          activeIcon: Image.asset(
            'lib/images/ikona1.png',
            width: 24,
            height: 24,
            color: AppColors.onSurface,
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Image.asset(
            'lib/images/ikona2.png',
            width: 24,
            height: 24,
            color: Colors.white70,
          ),
          activeIcon: Image.asset(
            'lib/images/ikona2.png',
            width: 24,
            height: 24,
            color: AppColors.onSurface,
          ),
          label: 'Usługi',
        ),
        BottomNavigationBarItem(
          icon: Image.asset(
            'lib/images/ikona3.png',
            width: 24,
            height: 24,
            color: Colors.white70,
          ),
          activeIcon: Image.asset(
            'lib/images/ikona3.png',
            width: 24,
            height: 24,
            color: AppColors.onSurface,
          ),
          label: 'Mapy',
        ),
        BottomNavigationBarItem(
          icon: Image.asset(
            'lib/images/ikona4.png',
            width: 24,
            height: 24,
            color: Colors.white70,
          ),
          activeIcon: Image.asset(
            'lib/images/ikona4.png',
            width: 24,
            height: 24,
            color: AppColors.onSurface,
          ),
          label: 'Nadchodzące',
        ),
        BottomNavigationBarItem(
          icon: Image.asset(
            'lib/images/ikona5.png',
            width: 24,
            height: 24,
            color: Colors.white70,
          ),
          activeIcon: Image.asset(
            'lib/images/ikona5.png',
            width: 24,
            height: 24,
            color: AppColors.onSurface,
          ),
          label: 'Profil',
        ),
      ],
    ),
  );
}
}