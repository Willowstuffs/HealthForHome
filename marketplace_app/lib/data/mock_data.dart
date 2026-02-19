import 'package:flutter/material.dart';

import '../models/specialist.dart';
import '../models/appointment.dart';

class Category {
  final String title;
  final IconData icon;

  Category({required this.title, required this.icon});
}

class MockData {
  static List<Specialist> getSpecialists() {
    return [
      Specialist(
        id: '1',
        firstName: 'Anna',
        lastName: 'Kowalska',
        professionalTitle: 'Fizjoterapeuta',
        averageRating: 4.8,
        totalReviews: 127,
        distance: 2.5,
        isVerified: true,
        services: [
          SpecialistService(
            id: 's1',
            serviceName: 'Masaż leczniczy',
            category: 'physiotherapy',
            durationMinutes: 60,
            price: 150.0,
          ),
        ],
        serviceAreas: [],
        bio: 'Specjalistka od bólów kręgosłupa',
      ),
      Specialist(
        id: '2',
        firstName: 'Marek',
        lastName: 'Nowak',
        professionalTitle: 'Fizjoterapeuta Sportowy',
        averageRating: 4.9,
        totalReviews: 89,
        distance: 3.2,
        isVerified: true,
        services: [
          SpecialistService(
            id: 's2',
            serviceName: 'Konsultacja',
            category: 'physiotherapy',
            durationMinutes: 30,
            price: 100.0,
          ),
        ],
        serviceAreas: [],
        bio: 'Specjalista od kontuzji sportowych',
      ),
      Specialist(
        id: '3',
        firstName: 'Katarzyna',
        lastName: 'Wiśniewska',
        professionalTitle: 'Terapeuta Manualny',
        averageRating: 4.7,
        totalReviews: 156,
        distance: 1.8,
        isVerified: true,
        services: [
          SpecialistService(
            id: 's3',
            serviceName: 'Terapia manualna',
            category: 'physiotherapy',
            durationMinutes: 45,
            price: 180.0,
          ),
        ],
        serviceAreas: [],
        bio: 'Terapia manualna i rozluźnianie',
      ),
    ];
  }

  static const Map<String, String> categoryMapping = {
    'Fizjoterapia': 'physiotherapy',
    'Pielęgniarstwo': 'nursing',
    'Rehabilitacja': 'rehabilitation',
  };

  static List<Category> getCategories() {
    return [
      Category(title: 'Fizjoterapia', icon: Icons.accessibility_new),
      Category(title: 'Pielęgniarstwo', icon: Icons.medical_services),
      Category(title: 'Rehabilitacja', icon: Icons.fitness_center),
    ];
  }

  static List<Appointment> getAppointments() {
    return [
      Appointment(
        id: '1',
        clientId: 'client_1',
        specialistId: '1',
        specialistName: 'Dr. Anna Kowalska',
        serviceName: 'Masaż leczniczy',
        appointmentStatus: 'confirmed',
        scheduledStart: DateTime.now().add(const Duration(days: 1)),
        scheduledEnd: DateTime.now().add(const Duration(days: 1, hours: 1)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        clientAddress: 'Warszawa, Złota 44',
        totalPrice: 150.0,
      ),
      Appointment(
        id: '2',
        clientId: 'client_1',
        specialistId: '2',
        specialistName: 'Marek Nowak',
        serviceName: 'Konsultacja',
        appointmentStatus: 'pending',
        scheduledStart: DateTime.now().add(const Duration(days: 3)),
        scheduledEnd: DateTime.now().add(const Duration(days: 3, minutes: 30)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        clientAddress: 'Warszawa, Złota 44',
        totalPrice: 100.0,
      ),
    ];
  }
}
