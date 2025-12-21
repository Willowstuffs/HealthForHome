import 'package:flutter/material.dart';

import '../models/specialist.dart';

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
}
