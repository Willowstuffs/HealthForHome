import 'package:flutter/material.dart';

class Category {
  final String title;
  final IconData icon;

  Category({required this.title, required this.icon});
}

class Data {
  static const Map<String, String> categoryMapping = {
    'Fizjoterapia': 'physiotherapy',
    'Pielęgniarstwo': 'nursing',
    'Rehabilitacja': 'rehabilitation',
  };

  static const Map<String, String> professionMapping = {
    'Fizjoterapeuta': 'physiotherapist',
    'Pielęgniarka': 'nurse',
    'Rehabilitant': 'rehabilitator',
  };

  static const Map<String, String> localizedCategoryMapping = {
    'physiotherapy': 'Fizjoterapia',
    'nursing': 'Pielęgniarstwo',
    'rehabilitation': 'Rehabilitacja',
  };

  static const Map<String, String> localizedProfessionMapping = {
    'physiotherapist': 'Fizjoterapeuta',
    'nurse': 'Pielęgniarka',
    'rehabilitator': 'Rehabilitant',
  };

  static List<Category> getCategories() {
    return [
      Category(title: 'Fizjoterapia', icon: Icons.accessibility_new),
      Category(title: 'Pielęgniarstwo', icon: Icons.medical_services),
    ];
  }

  static String localizedProfessionalTitle(String? key) {
    return localizedProfessionMapping[key] ?? 'Specjalista';
  }

  static String localizedProfession(String? key) {
    return localizedCategoryMapping[key] ?? 'Usługa';
  }
}
