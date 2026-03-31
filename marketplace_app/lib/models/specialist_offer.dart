class SpecialistOffer {
  final String serviceId;
  final String name;
  final String category;
  final int durationMinutes;
  final double price;
  final String? description;

  SpecialistOffer({
    required this.serviceId,
    required this.name,
    required this.category,
    required this.durationMinutes,
    required this.price,
    this.description,
  });

  factory SpecialistOffer.fromJson(Map<String, dynamic> json) {
    return SpecialistOffer(
      serviceId: json['serviceId'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      durationMinutes: json['durationMinutes'] ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      description: json['description'],
    );
  }
}
