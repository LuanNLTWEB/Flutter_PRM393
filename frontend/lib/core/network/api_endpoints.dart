class ApiEndpoints {
  // Với máy ảo Android emulator dùng 10.0.2.2, máy thật hoặc web/windows dùng localhost hoặc IP LAN
  static const String baseUrl = 'http://localhost:5000/api';
  static const String healthCheck = '$baseUrl/health';
  static const String register = '$baseUrl/auth/register';
  static const String login = '$baseUrl/auth/login';
  static const String userProfile = '$baseUrl/users/profile';
  static const String changePassword = '$baseUrl/users/change-password';
}
