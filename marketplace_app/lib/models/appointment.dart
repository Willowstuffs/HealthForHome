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

  // Navigation properties (optional)
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
}
