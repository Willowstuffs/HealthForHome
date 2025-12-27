class ClientUpdateDto {
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final String? address;
  final String? emergencyContact;

  ClientUpdateDto({
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.dateOfBirth,
    this.address,
    this.emergencyContact,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth?.toIso8601String().split(
        'T',
      )[0], // Sending DateOnly as yyyy-MM-dd
      'address': address,
      'emergencyContact': emergencyContact,
    };
  }
}
