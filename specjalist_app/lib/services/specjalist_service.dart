class SpecialistService { 
  final String id;
  final String name;
  final double price;
  final int duration;
  final String? description;
  final String serviceTypeId;
    SpecialistService({
      required this.id,
      required this.name,
      required this.price,
      required this.duration,
      required this.serviceTypeId,
    this.description,
    });
    
   factory SpecialistService.fromJson(Map<String, dynamic> json) {
    return SpecialistService(
      id: json['id'] ?? '',
      name: json['serviceName'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      duration: json['durationMinutes'] ?? 30,
      // Kluczowe: upewnij się, że backend zwraca tu 'serviceTypeId'
      serviceTypeId: json['serviceTypeId'] ?? '', 
      description: json['description'],
    );
  }
  }



class ServiceType {
  final String id; // GUID z bazy danych
  final String name;
  final String category;
  final int defaultDuration;
  final String? description;

  ServiceType({
    required this.id,
    required this.name,
    required this.category,
    required this.defaultDuration,
    this.description,
  });

  factory ServiceType.fromJson(Map<String, dynamic> json) {
  return ServiceType(
    id: json['id'],
    name: json['name'] ?? '',
    category: json['category'] ?? '',
    defaultDuration: json['defaultDuration'] ?? 30, 
    description: json['description'],
  );
}

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'defaultDuration': defaultDuration,
        'description': description,
      };
}