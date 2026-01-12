class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final String role;

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.role,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
  return LoginResponse(
    accessToken: json['accessToken']?.toString() ?? '',
    refreshToken: json['refreshToken']?.toString() ?? '',
    role: json['role']?.toString() ?? '',
  );
}
}