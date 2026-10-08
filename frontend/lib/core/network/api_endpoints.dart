class ApiEndpoints {
  // Với máy ảo Android emulator dùng 10.0.2.2, máy thật hoặc web/windows dùng localhost hoặc IP LAN
  static const String baseUrl = 'http://localhost:5000/api';
  static const String healthCheck = '$baseUrl/health';
  static const String register = '$baseUrl/auth/register';
  static const String login = '$baseUrl/auth/login';
  static const String userProfile = '$baseUrl/users/profile';
  static const String changePassword = '$baseUrl/users/change-password';

  // Admin Endpoints
  static const String adminUsers = '$baseUrl/admin/users';
  static const String adminCreateStaff = '$baseUrl/admin/users/staff';
  static String adminUserRole(String id) => '$baseUrl/admin/users/$id/role';
  static String adminUserStatus(String id) => '$baseUrl/admin/users/$id/status';

  // Review Endpoints (UC-RAT-01 & UC-RAT-02)
  static const String reviewTags = '$baseUrl/reviews/tags';
  static const String technicians = '$baseUrl/reviews/technicians';
  static const String createReview = '$baseUrl/reviews';
  static const String myReviews = '$baseUrl/reviews/my-reviews';
  static String technicianReviews(String technicianId) => '$baseUrl/reviews/technician/$technicianId';
  static String replyReview(String reviewId) => '$baseUrl/reviews/$reviewId/reply';
}
