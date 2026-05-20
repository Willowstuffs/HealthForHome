import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:marketplace_app/models/appointment.dart';
import 'package:marketplace_app/models/nearby_specialist.dart';
import 'package:marketplace_app/screens/calendar_screen.dart';
import 'package:marketplace_app/screens/search_specialists_screen.dart';
import 'package:marketplace_app/theme/app_theme.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('pl_PL', null);
  });

  testWidgets('Search and calendar flow in test shell', (tester) async {
    final specialists = [
      NearbySpecialist(
        id: 'spec-1',
        firstName: 'Jan',
        lastName: 'Kowalski',
        professionalTitle: 'Fizjoterapeuta',
        avatarUrl: null,
        serviceArea: 'Warszawa',
        distanceKm: 2.4,
        serviceNames: ['Fizjoterapia', 'Rehabilitacja'],
      ),
    ];

    Future<List<NearbySpecialist>> addressSearch(String address) async {
      return specialists;
    }

    Future<List<String>> autocompleteSearch(String query) async {
      return ['Warszawa'];
    }

    final now = DateTime.now();
    final appointment = Appointment(
      id: 'appt-1',
      clientId: 'client-1',
      specialistId: 'spec-1',
      appointmentStatus: 'confirmed',
      scheduledStart: DateTime(now.year, now.month, now.day, 10, 0),
      scheduledEnd: DateTime(now.year, now.month, now.day, 11, 0),
      createdAt: now,
      updatedAt: now,
      isRated: false,
      specialistName: 'Jan Kowalski',
      serviceNames: ['Fizjoterapia'],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: _TestShell(
          searchScreen: SearchSpecialistsScreen(
            addressSearch: addressSearch,
            autocompleteSearch: autocompleteSearch,
          ),
          calendarScreen: CalendarScreen(
            appointmentsLoader: () async => [appointment],
          ),
        ),
      ),
    );

    await tester.pump();

    await tester.enterText(find.byType(TextField), 'Warsz');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Warszawa'));
    await tester.pumpAndSettle();

    expect(find.text('Jan Kowalski'), findsOneWidget);

    await tester.tap(find.text('Kalendarz'));
    await tester.pumpAndSettle();

    expect(find.text('Ogłoszenia w wybranym dniu'), findsOneWidget);
    expect(find.text('Jan Kowalski'), findsOneWidget);
  });
}

class _TestShell extends StatefulWidget {
  final Widget searchScreen;
  final Widget calendarScreen;

  const _TestShell({
    required this.searchScreen,
    required this.calendarScreen,
  });

  @override
  State<_TestShell> createState() => _TestShellState();
}

class _TestShellState extends State<_TestShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final body = _currentIndex == 0
        ? widget.searchScreen
        : widget.calendarScreen;

    return Scaffold(
      body: SafeArea(child: body),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search_rounded),
            label: 'Szukaj',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_rounded),
            label: 'Kalendarz',
          ),
        ],
      ),
    );
  }
}
