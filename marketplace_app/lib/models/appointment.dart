class Appointment {
  final String id;
  final String clientId;
  final String specialistId;
  final String? specialistServiceId;
  final String appointmentStatus;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final double? totalPrice;
  final String? clientAddress;
  final String? clientNotes;
  final String? specialistNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? cancelledAt;

  final String? specialistName;
  final String? clientName;
  final String? serviceName;

  Appointment({
    required this.id,
    required this.clientId,
    required this.specialistId,
    this.specialistServiceId,
    required this.appointmentStatus,
    required this.scheduledStart,
    required this.scheduledEnd,
    this.totalPrice,
    this.clientAddress,
    this.clientNotes,
    this.specialistNotes,
    required this.createdAt,
    required this.updatedAt,
    this.cancelledAt,
    this.specialistName,
    this.clientName,
    this.serviceName,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      clientId: json['clientId'],
      specialistId: json['specialistId'],
      specialistServiceId: json['specialistServiceId'],
      appointmentStatus: json['appointmentStatus'] ?? 'pending',
      scheduledStart: DateTime.parse(json['scheduledStart']),
      scheduledEnd: DateTime.parse(json['scheduledEnd']),
      totalPrice: (json['totalPrice'] as num?)?.toDouble(),
      clientAddress: json['clientAddress'],
      clientNotes: json['clientNotes'],
      specialistNotes: json['specialistNotes'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'])
          : null,
      specialistName: json['specialistName'],
      clientName: json['clientName'],
      serviceName: json['serviceName'],
    );
  }
}

class ServiceRequest {
  final String id;
  final String serviceTypeName;
  final String description;
  final DateTime dateFrom;
  final DateTime dateTo;
  final double? maxPrice;
  final String address;
  final String status;
  final DateTime createdAt;
  final String? contactName;

  ServiceRequest({
    required this.id,
    required this.serviceTypeName,
    required this.description,
    required this.dateFrom,
    required this.dateTo,
    this.maxPrice,
    required this.address,
    required this.status,
    required this.createdAt,
    this.contactName,
  });

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    return ServiceRequest(
      id: json['id'],
      serviceTypeName: json['serviceTypeName'] ?? '',
      description: json['description'] ?? '',
      dateFrom: DateTime.parse(json['dateFrom']),
      dateTo: DateTime.parse(json['dateTo']),
      maxPrice: (json['maxPrice'] as num?)?.toDouble(),
      address: json['address'] ?? '',
      status: json['status'] ?? 'active',
      createdAt: DateTime.parse(json['createdAt']),
      contactName: json['contactName'],
    );
  }
}

class CreateServiceRequestDto {
  final String category;
  final String description;
  final DateTime dateFrom;
  final DateTime dateTo;
  final String address;
  final double? maxPrice;
  final String? contactName;
  final String? phoneNumber;
  final String? email;

  CreateServiceRequestDto({
    required this.category,
    required this.description,
    required this.dateFrom,
    required this.dateTo,
    required this.address,
    this.maxPrice,
    this.contactName,
    this.phoneNumber,
    this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'description': description,
      'dateFrom': dateFrom.toIso8601String(),
      'dateTo': dateTo.toIso8601String(),
      'address': address,
      if (maxPrice != null) 'maxPrice': maxPrice,
      if (contactName != null) 'contactName': contactName,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (email != null) 'email': email,
    };
  }
}

class AppointmentOffer {
  final String specialistId;
  final String firstName;
  final String lastName;
  final double proposedPrice;
  final String? bio;

  AppointmentOffer({
    required this.specialistId,
    required this.firstName,
    required this.lastName,
    required this.proposedPrice,
    this.bio,
  });

  factory AppointmentOffer.fromJson(Map<String, dynamic> json) {
    return AppointmentOffer(
      specialistId: json['specialistId'],
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      proposedPrice: (json['proposedPrice'] as num?)?.toDouble() ?? 0.0,
      bio: json['bio'],
    );
  }
}
