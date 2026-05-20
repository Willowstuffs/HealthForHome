import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:marketplace_app/models/appointment.dart';
import 'package:marketplace_app/screens/calendar_screen.dart';
import 'package:marketplace_app/theme/app_theme.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('pl_PL', null);
  });

  testWidgets('CalendarScreen shows appointments for the selected day', (
    tester,
  ) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, 10, 0);
    final end = DateTime(now.year, now.month, now.day, 11, 0);

    final appointment = Appointment(
      id: 'appt-1',
      clientId: 'client-1',
      specialistId: 'spec-1',
      appointmentStatus: 'confirmed',
      scheduledStart: start,
      scheduledEnd: end,
      createdAt: now,
      updatedAt: now,
      isRated: false,
      specialistName: 'Jan Kowalski',
      serviceNames: ['Fizjoterapia'],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: CalendarScreen(
          appointmentsLoader: () async => [appointment],
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Kalendarz'), findsOneWidget);
    expect(find.text('Ogłoszenia w wybranym dniu'), findsOneWidget);
    expect(find.text('Jan Kowalski'), findsOneWidget);
    expect(find.text('Fizjoterapia'), findsOneWidget);
  });
}
