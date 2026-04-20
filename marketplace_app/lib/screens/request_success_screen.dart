import 'package:flutter/material.dart';
import 'package:marketplace_app/widgets/screen_status_bar.dart';
import '../../theme/app_theme.dart';

class RequestSuccessScreen extends StatelessWidget {
  const RequestSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenStatusBar(
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // LOGO / IKONA
                Image.asset('lib/images/logo.png', width: 120, height: 120),

                SizedBox(height: 64),

                // WIADOMOŚĆ O SUKCESIE
                Text(
                  'Twoja prośba została wysłana',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),

                SizedBox(height: 6),

                Text(
                  'Specjalista będzie się z Tobą kontaktował',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: AppColors.onSurface,
                  ),
                ),

                SizedBox(height: 64),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: const Text('Wróć do strony głównej'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
