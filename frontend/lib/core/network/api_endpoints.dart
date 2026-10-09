class ApiEndpoints {
  // Với máy ảo Android emulator dùng 10.0.2.2, máy thật hoặc web/windows dùng localhost hoặc IP LAN
  static const String baseUrl = 'http://localhost:5000/api';
  static const String healthCheck = '$baseUrl/health';
  // Auth & Profile Endpoints
  static const String register = '$baseUrl/auth/register';
  static const String registerTechnician = '$baseUrl/auth/register-technician';
  static const String login = '$baseUrl/auth/login';
  static const String userProfile = '$baseUrl/users/profile';
  static const String userAvatar = '$baseUrl/users/avatar';
  static const String changePassword = '$baseUrl/users/change-password';

  // Technician Public & Self Endpoints
  static const String publicTechnicians = '$baseUrl/technicians';
  static String publicTechnicianDetail(String id) => '$baseUrl/technicians/$id';
  static const String technicianAvailability = '$baseUrl/technicians/status/availability';

  // Admin & Staff KYC Endpoints
  static const String adminUsers = '$baseUrl/admin/users';
  static const String adminCreateStaff = '$baseUrl/admin/users/staff';
  static String adminUserRole(String id) => '$baseUrl/admin/users/$id/role';
  static String adminUserStatus(String id) => '$baseUrl/admin/users/$id/status';
  static const String adminKYCTechnicians = '$baseUrl/admin/technicians/kyc';
  static String adminApproveTechnician(String id) => '$baseUrl/admin/technicians/$id/approve';
  static String adminRejectTechnician(String id) => '$baseUrl/admin/technicians/$id/reject';

  // Service Categories Endpoints (Dev 2 - UC-REQ-01)
  static const String serviceCategories = '$baseUrl/categories';
  static String serviceCategoryDetail(String identifier) => '$baseUrl/categories/$identifier';
}

