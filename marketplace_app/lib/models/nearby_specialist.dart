class NearbySpecialist {
  final String id;
  final String firstName;
  final String lastName;
  final String? professionalTitle;
  final String? avatarUrl;
  final String serviceArea;
  final double distanceKm;
  final List<String> serviceNames;

  NearbySpecialist({
      required this.id,
      required this.firstName,
      required this.lastName,
      this.professionalTitle,
      this.avatarUrl,
      required this.serviceArea,
      required this.distanceKm,
      required this.serviceNames,
  });

  String get fullName => '$firstName $lastName';

  factory NearbySpecialist.fromJson(Map<String, dynamic> json) {
    return NearbySpecialist(
      id: json['id'],
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      professionalTitle: json['professionalTitle'],
      avatarUrl: json['avatarUrl'],
      serviceArea: json['serviceArea'] ?? '',
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      serviceNames: List<String>.from(json['serviceNames'] ?? []),
    );
  }
}
