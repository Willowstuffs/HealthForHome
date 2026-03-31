class SpecialistProfileArea {
  final String? city;
  final String? postalCode;
  final int maxDistanceKm;
  final double latitude;
  final double longitude;

  SpecialistProfileArea({
    this.city,
    this.postalCode,
    required this.maxDistanceKm,
    required this.latitude,
    required this.longitude,
  });

  factory SpecialistProfileArea.fromJson(Map<String, dynamic> json) {
    return SpecialistProfileArea(
      city: json['city'],
      postalCode: json['postalCode'],
      maxDistanceKm: json['maxDistanceKm'] ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SpecialistProfileDetails {
  final String id;
  final String firstName;
  final String lastName;
  final String? professionalTitle;
  final String? bio;
  final String? avatarUrl;
  final String? phoneNumber;
  final String? profession;
  final List<SpecialistProfileArea> areas;

  SpecialistProfileDetails({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.professionalTitle,
    this.bio,
    this.avatarUrl,
    this.phoneNumber,
    this.profession,
    required this.areas,
  });

  String get fullName => '$firstName $lastName';

  factory SpecialistProfileDetails.fromJson(Map<String, dynamic> json) {
    return SpecialistProfileDetails(
      id: json['id'],
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      professionalTitle: json['professionalTitle'],
      bio: json['bio'],
      avatarUrl: json['avatarUrl'],
      phoneNumber: json['phoneNumber'],
      profession: json['profession'],
      areas:
          (json['areas'] as List?)
              ?.map((e) => SpecialistProfileArea.fromJson(e))
              .toList() ??
          [],
    );
  }
}
