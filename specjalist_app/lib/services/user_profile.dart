class UserSession {
  static Map<String, dynamic>? rawProfile;
  static UserProfile? profile;
  static String? token;
  // GETTERY POD UI
  static String? get firstName => profile?.firstName;
  static String? get lastName => profile?.lastName;
  static String? get email => profile?.email;
  static String? get phone => profile?.phone;
  static List<ServiceArea>? get serviceAreas => profile?.serviceAreas;
  static List<String> get specializations => profile?.specializations ?? [];

  // ZAPIS PO LOGOWANIU
  static void setProfileFromApi(Map<String, dynamic> json, String jwtToken) {
    rawProfile = json;
    profile = UserProfile.fromApi(json);
    token = jwtToken;
  }

  // WYCZYŚĆ (logout)
  static void clear() {
    rawProfile = null;
    profile = null;
    token = null;
  }
}
class UserProfile {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? postalCode;
  final String? avatarUrl; 
  final List<ServiceArea>? serviceAreas;
  final List<String> specializations; 

  UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.postalCode,
    this.avatarUrl, 
    this.serviceAreas,
    required this.specializations,
  });

  factory UserProfile.fromApi(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'].toString(),
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phoneNumber']?.toString() ?? '',
      
      postalCode: json['postalCode']?.toString() ?? '',
      avatarUrl:  json['avatarUrl'],
       serviceAreas: json['serviceAreas'] != null
          ? (json['serviceAreas'] as List<dynamic>)
              .map((e) => ServiceArea.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : null,

      
      specializations: _mapSpecializations(json),
    );
  }

  static List<String> _mapSpecializations(Map<String, dynamic> json) {
    
    if (json['specializations'] is List) {
      return (json['specializations'] as List)
          .map((e) => e.toString())
          .toList();
    }

    
    if (json['professionalTitle'] != null) {
      return [json['professionalTitle'].toString()];
    }

    return [];
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'postalCode': postalCode,
        'serviceAreas': serviceAreas?.map((e) => e.toJson()).toList(),
        'specializations': specializations,
        'avatarUrl':avatarUrl,
      };
}
class ServiceArea {
  final String city;
  final int maxDistanceKm;

  ServiceArea({
    required this.city,
    required this.maxDistanceKm,
  });

  factory ServiceArea.fromJson(Map<String, dynamic> json) {
    return ServiceArea(
      city: json['city'] ?? '',
      maxDistanceKm: json['maxDistanceKm'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'city': city,
        'maxDistanceKm': maxDistanceKm,
      };
}