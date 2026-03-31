class NearbySpecialist {
  final String id;
  final String firstName;
  final String lastName;
  final String? professionalTitle;
  final String? avatarUrl;
  final double? hourlyRate;
  final double? distanceKm;

  NearbySpecialist({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.professionalTitle,
    this.avatarUrl,
    this.hourlyRate,
    this.distanceKm,
  });

  String get fullName => '$firstName $lastName';

  factory NearbySpecialist.fromJson(Map<String, dynamic> json) {
    return NearbySpecialist(
      id: json['id'],
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      professionalTitle: json['professionalTitle'],
      avatarUrl: json['avatarUrl'],
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    );
  }
}
