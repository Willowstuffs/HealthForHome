import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketplace_app/models/nearby_specialist.dart';
import 'package:marketplace_app/screens/search_specialists_screen.dart';
import 'package:marketplace_app/theme/app_theme.dart';

void main() {
  testWidgets('SearchSpecialistsScreen shows results after address search', (
    tester,
  ) async {
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

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: SearchSpecialistsScreen(
          addressSearch: addressSearch,
          autocompleteSearch: autocompleteSearch,
        ),
      ),
    );

    await tester.pump();

    await tester.enterText(find.byType(TextField), 'Warsz');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Warszawa'));
    await tester.pumpAndSettle();

    expect(find.text('Jan Kowalski'), findsOneWidget);
    expect(
      find.text('Brak wyników lub nie wyszukano specjalistów.'),
      findsNothing,
    );
  });
}
