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
    );
  }
}
