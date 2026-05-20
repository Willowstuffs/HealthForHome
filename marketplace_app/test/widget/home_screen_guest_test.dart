import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketplace_app/screens/home_screen.dart';
import 'package:marketplace_app/theme/app_theme.dart';

void main() {
  testWidgets('HomeScreen shows guest sections when logged out', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const HomeScreen(),
      ),
    );

    await tester.pump();

    expect(find.text('Twoje zdrowie w domu'), findsOneWidget);
    expect(find.text('Wybierz kategorię'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);
  });
}
