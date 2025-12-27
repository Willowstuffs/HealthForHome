class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final DateTime accessTokenExpires;
  final DateTime refreshTokenExpires;
  final UserInfoDto user;

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpires,
    required this.refreshTokenExpires,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      accessTokenExpires: DateTime.parse(json['accessTokenExpires']),
      refreshTokenExpires: DateTime.parse(json['refreshTokenExpires']),
      user: UserInfoDto.fromJson(json['user']),
    );
  }
}

class UserInfoDto {
  final String id;
  final String email;
  final String userType;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? avatarUrl;

  UserInfoDto({
    required this.id,
    required this.email,
    required this.userType,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.avatarUrl,
  });

  factory UserInfoDto.fromJson(Map<String, dynamic> json) {
    return UserInfoDto(
      id: json['id'],
      email: json['email'] ?? '',
      userType: json['userType'] ?? '',
      firstName: json['firstName'],
      lastName: json['lastName'],
      phoneNumber: json['phoneNumber'],
      avatarUrl: json['avatarUrl'],
    );
  }
}
