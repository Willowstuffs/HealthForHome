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

  static List<Category> getCategories() {
    return [
      Category(title: 'Fizjoterapia', icon: Icons.accessibility_new),
      Category(title: 'Pielęgniarstwo', icon: Icons.medical_services),
      Category(title: 'Rehabilitacja', icon: Icons.fitness_center),
    ];
  }
}
