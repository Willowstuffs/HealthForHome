import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MainBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const MainBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: onTap,
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
    );
  }
}
