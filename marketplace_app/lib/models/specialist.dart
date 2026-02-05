class SpecialistService {
  final String id;
  final String serviceName;
  final String category;
  final int durationMinutes;
  final double price;
  final String? description;

  SpecialistService({
    required this.id,
    required this.serviceName,
    required this.category,
    required this.durationMinutes,
    required this.price,
    this.description,
  });

  factory SpecialistService.fromJson(Map<String, dynamic> json) {
    return SpecialistService(
      id: json['id'],
      serviceName: json['serviceName'] ?? '',
      category: json['category'] ?? '',
      durationMinutes: json['durationMinutes'] ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      description: json['description'],
    );
  }
}

class ServiceArea {
  final String city;
  final String? postalCode;
  final int maxDistanceKm;
  final bool isPrimary;

  ServiceArea({
    required this.city,
    this.postalCode,
    required this.maxDistanceKm,
    required this.isPrimary,
  });

  factory ServiceArea.fromJson(Map<String, dynamic> json) {
    return ServiceArea(
      city: json['city'] ?? '',
      postalCode: json['postalCode'],
      maxDistanceKm: json['maxDistanceKm'] ?? 0,
      isPrimary: json['isPrimary'] ?? false,
    );
  }
}

class Specialist {
  final String id;
  final String firstName;
  final String lastName;
  final String? professionalTitle;
  final String? bio;
  final double? hourlyRate;
  final bool isVerified;
  final double averageRating;
  final int totalReviews;
  final List<SpecialistService> services;
  final List<ServiceArea> serviceAreas;
  final double? distance;

  Specialist({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.professionalTitle,
    this.bio,
    this.hourlyRate,
    required this.isVerified,
    required this.averageRating,
    required this.totalReviews,
    required this.services,
    required this.serviceAreas,
    this.distance,
  });

  String get fullName => '$firstName $lastName';

  factory Specialist.fromJson(Map<String, dynamic> json) {
    return Specialist(
      id: json['id'],
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      professionalTitle: json['professionalTitle'],
      bio: json['bio'],
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble(),
      isVerified: json['isVerified'] ?? false,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['totalReviews'] ?? 0,
      services:
          (json['services'] as List?)
              ?.map((e) => SpecialistService.fromJson(e))
              .toList() ??
          [],
      serviceAreas:
          (json['serviceAreas'] as List?)
              ?.map((e) => ServiceArea.fromJson(e))
              .toList() ??
          [],
      distance: (json['distance'] as num?)?.toDouble(),
    );
  }
}
