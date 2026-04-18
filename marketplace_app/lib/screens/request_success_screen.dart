import 'package:flutter/material.dart';
import 'package:marketplace_app/widgets/screen_status_bar.dart';
import '../../theme/app_theme.dart';

class RequestSuccessScreen extends StatelessWidget {
  const RequestSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ScreenStatusBar(
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                SizedBox(height: 32),

                // LOGO / IKONA
                Image.asset('lib/images/logo.png', width: 120, height: 120),

                SizedBox(height: 64),

                // WIADOMOŚĆ O SUKCESIE
                Text(
                  'Twoja prośba została wysłana',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),

                SizedBox(height: 6),

                Text(
                  'Specjalista będzie się z Tobą kontaktował',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                  ),
                ),

                SizedBox(height: 96),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: const Text('Wróć do strony głównej'),
                  ),
                ),

                SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
