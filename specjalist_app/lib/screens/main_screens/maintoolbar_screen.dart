import 'package:flutter/material.dart';
import 'package:specjalist_app/screens/main_screens/profil_screen.dart';
import 'package:specjalist_app/screens/main_screens/upcoming_screen.dart';
import 'package:specjalist_app/screens/main_screens/start_screen.dart';
import 'package:specjalist_app/screens/main_screens/work_screen.dart';
import 'package:specjalist_app/screens/main_screens/map_screen.dart';
import '../../theme/app_theme.dart';

class MainScreen extends StatefulWidget {
  final int startIndex;
  final String? highlightAppointmentId;
  final MapMode mapPrecision;

  const MainScreen({
    super.key,
    this.startIndex = 0,
    this.highlightAppointmentId,
    this.mapPrecision = MapMode.toolbar,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;

  String? _highlightAppointmentId;

  /// 🔥 temporary upcoming marker
  Map<String, dynamic>? _upcomingOverride;

  @override
  void initState() {
    super.initState();

    _selectedIndex = widget.startIndex;
    _highlightAppointmentId = widget.highlightAppointmentId;
  }

  /// ===============================
  /// NAVIGATION
  /// ===============================
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;

      /// 🔥 reset map when leaving map tab
      if (index != 2) {
        _upcomingOverride = null;
      }
    });
  }

  /// ===============================
  /// UPCOMING → MAP
  /// ===============================
  void _openUpcomingOnMap(Map<String, dynamic> appointment) {
    setState(() {
      _selectedIndex = 2;
      _highlightAppointmentId = appointment['id'];
      _upcomingOverride = appointment;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            /// HOME
            StartScreen(
              highlightAppointmentId: _highlightAppointmentId,
            ),

            /// WORK
            const WorkScreen(),

            /// MAP
            MapScreen(
              inquiries: const [],
              highlightId: _highlightAppointmentId,
              mode: _upcomingOverride != null
                  ? MapMode.upcoming
                  : widget.mapPrecision,

              /// 🔥 magic line
              overrideInquiries: _upcomingOverride != null
                  ? [_upcomingOverride!]
                  : null,
            ),

            /// UPCOMING
            UpcomingScreen(
              onOpenMap: (appointment) {
                _openUpcomingOnMap(appointment);
              },
            ),

            /// PROFILE
            const ProfilScreen(),
          ],
        ),

        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: AppColors.primary,
          selectedItemColor: AppColors.outline,
          unselectedItemColor: Colors.white70,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.work),
              label: 'Usługi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map),
              label: 'Mapy',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'Nadchodzące',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}