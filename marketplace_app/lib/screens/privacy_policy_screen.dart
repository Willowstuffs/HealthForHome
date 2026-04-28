import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/screen_status_bar.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenStatusBar(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.onSurface),
          title: Text(
            'Polityka prywatności',
            style: TextStyle(color: AppColors.onSurface),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Polityka prywatności',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'Work in progress... Tutaj będzie znajdować się szczegółowa polityka prywatności aplikacji Health for Home.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              // TODO: Add full Privacy Policy content
            ],
          ),
        ),
      ),
    );
  }
}
