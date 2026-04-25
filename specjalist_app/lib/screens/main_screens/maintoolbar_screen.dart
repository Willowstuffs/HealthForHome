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
  List<Widget> get _screens => [
        StartScreen(
          highlightAppointmentId: widget.highlightAppointmentId,
        ),
        const WorkScreen(),
        MapScreen(
          key: ValueKey(widget.highlightAppointmentId),
          inquiries: inquiries,
          highlightId: widget.highlightAppointmentId,
        ),
        const UpcomingScreen(),
        const ProfilScreen(),
      ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.startIndex;
  }


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  

  @override
  Widget build(BuildContext context) {
    // Owinięcie całego Scaffold w PopScope
    return PopScope(
      canPop: false, // Blokuje natywne zamknięcie aplikacji/powrót
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // Logika przycisku wstecz:
        if (_selectedIndex != 0) {
          // Jeśli nie jesteśmy na Home (index 0), wróć do Home
          setState(() {
            _selectedIndex = 0;
          });
        } else {
          // Jeśli jesteśmy już na Home, wyświetlamy informację
          // (Użytkownik musi użyć przycisku systemowego Home/Gesture, by wyjść)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Jesteś na ekranie głównym. Użyj przycisku Home, aby wyjść.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Scaffold(
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
      ),
    );
  }
}