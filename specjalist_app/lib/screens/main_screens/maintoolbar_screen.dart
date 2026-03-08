import 'package:flutter/material.dart';
import 'package:specjalist_app/screens/main_screens/profil_screen.dart';
import 'package:specjalist_app/screens/main_screens/upcoming_screen.dart';
import 'start_screen.dart';
import 'work_screen.dart';
import 'package:specjalist_app/screens/main_screens/map_screen.dart';
import '../../theme/app_theme.dart';
// import kolejne ekrany gdy będą gotowe

class MainScreen extends StatefulWidget {
  final int startIndex;
  final String? highlightAppointmentId;

  const MainScreen({
    super.key,
    this.startIndex = 0,
    this.highlightAppointmentId,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}
class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;
  List<Map<String, dynamic>> inquiries = [];

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.startIndex;

    _screens = [
      StartScreen(
        highlightAppointmentId: widget.highlightAppointmentId,
      ),
      const WorkScreen(),
      MapScreen(inquiries: inquiries),
      const UpcomingScreen(),
      const ProfilScreen(),
    ];
  }


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
        selectedItemColor: AppColors.outline,
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
              color: AppColors.outline,
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
              color: AppColors.outline,
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
              color: AppColors.outline,
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
              color: AppColors.outline,
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
              color: AppColors.outline,
            ),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}