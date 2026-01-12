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
        name: 'Dr. Anna Kowalska',
        profession: 'Fizjoterapeuta',
        rating: 4.8,
        reviews: 127,
        distance: 2.5,
        imageUrl:
            'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=150&h=150&fit=crop&crop=face',
        certificates: ['Certyfikat PTF', 'Dyplom AWF'],
        specialties: ['Bóle kręgosłupa', 'Masaż leczniczy'],
        isAvailable: true,
      ),
      Specialist(
        id: '2',
        name: 'Marek Nowak',
        profession: 'Fizjoterapeuta Sportowy',
        rating: 4.9,
        reviews: 89,
        distance: 3.2,
        imageUrl:
            'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=150&h=150&fit=crop&crop=face',
        certificates: ['Certyfikat ISAK', 'Dyplom AWF'],
        specialties: ['Kontuzje sportowe', 'Rehabilitacja pourazowa'],
        isAvailable: true,
      ),
      Specialist(
        id: '3',
        name: 'Katarzyna Wiśniewska',
        profession: 'Terapeuta Manualny',
        rating: 4.7,
        reviews: 156,
        distance: 1.8,
        imageUrl:
            'https://images.unsplash.com/photo-1673865641073-4479f93a7776?w=150&h=150&fit=crop&crop=face',
        certificates: ['Certyfikat MT', 'Dyplom FITS'],
        specialties: ['Terapia manualna', 'Rozluźnianie mięśni'],
        isAvailable: false,
      ),
    ];
  }

  static List<Category> getCategories() {
    return [
      Category(title: 'Fizjoterapia', icon: Icons.accessibility_new_outlined),
      Category(title: 'Rehabilitacja', icon: Icons.healing_outlined),
      Category(title: 'Masaż', icon: Icons.spa_outlined),
      Category(title: 'Konsultacje', icon: Icons.chat_bubble_outline),
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
        scheduledStart: DateTime.now().add(const Duration(days: 1, hours: 2)),
        scheduledEnd: DateTime.now().add(const Duration(days: 1, hours: 3)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Appointment(
        id: '2',
        clientId: 'client_1',
        specialistId: '2',
        specialistName: 'Marek Nowak',
        serviceName: 'Konsultacja',
        appointmentStatus: 'pending',
        scheduledStart: DateTime.now().add(const Duration(days: 3, hours: 5)),
        scheduledEnd: DateTime.now().add(const Duration(days: 3, hours: 6)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }
}
