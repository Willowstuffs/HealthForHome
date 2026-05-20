import 'package:flutter_test/flutter_test.dart';
import 'package:marketplace_app/models/appointment.dart';

void main() {
  test('ServiceRequest.toAppointment maps fields for UI', () {
    final createdAt = DateTime(2025, 1, 15, 12, 0);
    final dateFrom = DateTime(2025, 2, 20, 9, 0);
    final dateTo = DateTime(2025, 2, 20, 11, 0);

    final request = ServiceRequest(
      id: 'req-1',
      serviceTypeName: 'Fizjoterapia',
      description: 'Konsultacja domowa',
      dateFrom: dateFrom,
      dateTo: dateTo,
      maxPrice: 200,
      address: 'Warszawa, Polska',
      status: 'open',
      createdAt: createdAt,
      contactName: 'Anna',
    );

    final appointment = request.toAppointment();

    expect(appointment.id, 'req-1');
    expect(appointment.appointmentStatus, 'open');
    expect(appointment.scheduledStart, dateFrom);
    expect(appointment.scheduledEnd, dateTo);
    expect(appointment.clientNotes, 'Konsultacja domowa');
    expect(appointment.serviceNames, ['Fizjoterapia']);
    expect(appointment.serviceTypeName, 'Fizjoterapia');
    expect(appointment.createdAt, createdAt);
  });

  test('Appointment.fromJson defaults to pending status', () {
    final start = DateTime(2025, 3, 10, 8, 0);
    final end = DateTime(2025, 3, 10, 9, 0);
    final created = DateTime(2025, 3, 1, 10, 0);

    final appointment = Appointment.fromJson({
      'id': 'appt-1',
      'clientId': 'client-1',
      'specialistId': 'spec-1',
      'scheduledStart': start.toIso8601String(),
      'scheduledEnd': end.toIso8601String(),
      'createdAt': created.toIso8601String(),
      'updatedAt': created.toIso8601String(),
      'isRated': false,
    });

    expect(appointment.appointmentStatus, 'pending');
    expect(appointment.serviceNames, isNull);
    expect(appointment.isRated, isFalse);
  });
}
