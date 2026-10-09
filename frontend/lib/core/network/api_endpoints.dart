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

  // Danh mục dịch vụ
  static const String serviceCategories = '$baseUrl/categories';
  static String serviceCategoryDetail(String identifier) => '$baseUrl/categories/$identifier';
  static String searchServiceCategories(String keyword) => '$baseUrl/categories/search?keyword=$keyword';

  // Yêu cầu sửa chữa
  static const String requests = '$baseUrl/requests';
  static const String myRequests = '$baseUrl/requests/my-requests';
  static String requestDetail(String id) => '$baseUrl/requests/$id';
  static String cancelRequest(String id) => '$baseUrl/requests/$id/cancel';

  static const String repairRequests = requests;
  static const String myRepairRequests = myRequests;
  static String repairRequestDetail(String id) => requestDetail(id);
  static String cancelRepairRequest(String id) => cancelRequest(id);

  // Báo giá & Khớp lệnh (UC-QUO)
  static const String quotations = '$baseUrl/quotations';
  static const String myQuotations = '$baseUrl/quotations/my-quotes';
  static String quotationDetail(String id) => '$baseUrl/quotations/$id';
  static String quotationAccept(String id) => '$baseUrl/quotations/$id/accept';
  static String quotationReject(String id) => '$baseUrl/quotations/$id/reject';
  static String quotationRetract(String id) =>
      '$baseUrl/quotations/$id/retract';
  static const String nearbyRequests = '$baseUrl/requests/nearby';
}

