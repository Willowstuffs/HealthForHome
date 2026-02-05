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

  // Navigation properties
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

class CreateAppointmentDto {
  final String specialistId;
  final String? specialistServiceId;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final String? clientAddress;
  final String? clientNotes;

  CreateAppointmentDto({
    required this.specialistId,
    required this.specialistServiceId,
    required this.scheduledStart,
    required this.scheduledEnd,
    this.clientAddress,
    this.clientNotes,
  });

  Map<String, dynamic> toJson() {
    return {
      'specialistId': specialistId,
      'specialistServiceId': specialistServiceId,
      'scheduledStart': scheduledStart.toIso8601String(),
      'scheduledEnd': scheduledEnd.toIso8601String(),
      if (clientAddress != null) 'clientAddress': clientAddress,
      if (clientNotes != null) 'clientNotes': clientNotes,
    };
  }
}
