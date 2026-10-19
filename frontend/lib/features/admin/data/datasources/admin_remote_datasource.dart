import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_endpoints.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../repair_request/data/models/service_category_model.dart';

class AdminRemoteDataSource {
  final http.Client client;

  AdminRemoteDataSource({http.Client? client})
      : client = client ?? http.Client();

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// Lấy danh sách tài khoản kèm bộ lọc tìm kiếm, vai trò, trạng thái
  Future<List<UserModel>> getUsers({
    required String token,
    String? search,
    String? role,
    bool? isActive,
  }) async {
    try {
      final queryParameters = <String, String>{};
      if (search != null && search.trim().isNotEmpty) {
        queryParameters['search'] = search.trim();
      }
      if (role != null && role.isNotEmpty) {
        queryParameters['role'] = role;
      }
      if (isActive != null) {
        queryParameters['isActive'] = isActive.toString();
      }

      final uri = Uri.parse(ApiEndpoints.adminUsers).replace(
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
      );

      final response = await client.get(
        uri,
        headers: _headers(token),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final List<dynamic> usersList = data['data']['users'] ?? [];
        return usersList
            .map((item) => UserModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(data['message'] ?? 'Không thể tải danh sách tài khoản');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Không thể kết nối đến máy chủ: $e');
    }
  }

  /// Tạo tài khoản Staff (Nhân viên)
  Future<UserModel> createStaff({
    required String token,
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
    required DateTime dateOfBirth,
    required String gender,
  }) async {
    try {
      final response = await client.post(
        Uri.parse(ApiEndpoints.adminCreateStaff),
        headers: _headers(token),
        body: jsonEncode({
          'fullName': fullName.trim(),
          'email': email.trim().toLowerCase(),
          'phoneNumber': phoneNumber.trim(),
          'password': password,
          'confirmPassword': confirmPassword,
          'dateOfBirth': dateOfBirth.toIso8601String(),
          'gender': gender,
        }),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return UserModel.fromJson(data['data']);
      } else {
        throw Exception(
            data['message'] ?? 'Không thể tạo tài khoản nhân viên');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Không thể kết nối đến máy chủ: $e');
    }
  }

  /// Cập nhật vai trò & quyền hạn (Role)
  Future<UserModel> updateUserRole({
    required String token,
    required String userId,
    required String role,
  }) async {
    try {
      final response = await client.put(
        Uri.parse(ApiEndpoints.adminUserRole(userId)),
        headers: _headers(token),
        body: jsonEncode({'role': role}),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return UserModel.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Không thể cập nhật vai trò');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Không thể kết nối đến máy chủ: $e');
    }
  }

  /// Khóa hoặc mở khóa tài khoản
  Future<UserModel> toggleUserStatus({
    required String token,
    required String userId,
    bool? isActive,
  }) async {
    try {
      final Map<String, dynamic> body = {};
      if (isActive != null) {
        body['isActive'] = isActive;
      }

      final response = await client.put(
        Uri.parse(ApiEndpoints.adminUserStatus(userId)),
        headers: _headers(token),
        body: jsonEncode(body),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return UserModel.fromJson(data['data']);
      } else {
        throw Exception(
            data['message'] ?? 'Không thể thay đổi trạng thái tài khoản');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Không thể kết nối đến máy chủ: $e');
    }
  }

  // ==========================================================
  // QUẢN LÝ DANH MỤC DỊCH VỤ & GIÁ SÀN (UC-STF-02)
  // ==========================================================

  /// Lấy toàn bộ danh mục dịch vụ kèm số liệu thống kê (UC-STF-02)
  Future<Map<String, dynamic>> getCategoriesForManage({
    required String token,
  }) async {
    try {
      final response = await client.get(
        Uri.parse(ApiEndpoints.adminServiceCategories),
        headers: _headers(token),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final List<dynamic> list = data['data']['categories'] ?? [];
        final categories = list
            .map((item) =>
                ServiceCategoryModel.fromJson(item as Map<String, dynamic>))
            .toList();
        return {
          'categories': categories,
          'total': data['data']['total'] ?? categories.length,
          'activeCount': data['data']['activeCount'] ?? 0,
          'inactiveCount': data['data']['inactiveCount'] ?? 0,
        };
      } else {
        throw Exception(
            data['message'] ?? 'Không thể tải danh sách danh mục dịch vụ');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Không thể kết nối đến máy chủ: $e');
    }
  }

  /// Tạo danh mục dịch vụ & giá sàn mới (UC-STF-02)
  Future<ServiceCategoryModel> createCategory({
    required String token,
    required String name,
    required String description,
    required String icon,
    required String color,
    required double basePrice,
    List<String> commonIssues = const [],
    bool isActive = true,
    int sortOrder = 0,
  }) async {
    try {
      final response = await client.post(
        Uri.parse(ApiEndpoints.serviceCategories),
        headers: _headers(token),
        body: jsonEncode({
          'name': name.trim(),
          'description': description.trim(),
          'icon': icon,
          'color': color,
          'basePrice': basePrice,
          'commonIssues': commonIssues,
          'isActive': isActive,
          'sortOrder': sortOrder,
        }),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return ServiceCategoryModel.fromJson(data['data']['category']);
      } else {
        throw Exception(data['message'] ?? 'Không thể tạo danh mục dịch vụ');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Không thể kết nối đến máy chủ: $e');
    }
  }

  /// Cập nhật thông tin, icon và giá sàn danh mục dịch vụ (UC-STF-02)
  Future<ServiceCategoryModel> updateCategory({
    required String token,
    required String id,
    String? name,
    String? description,
    String? icon,
    String? color,
    double? basePrice,
    List<String>? commonIssues,
    bool? isActive,
    int? sortOrder,
  }) async {
    try {
      final Map<String, dynamic> body = {};
      if (name != null) body['name'] = name.trim();
      if (description != null) body['description'] = description.trim();
      if (icon != null) body['icon'] = icon;
      if (color != null) body['color'] = color;
      if (basePrice != null) body['basePrice'] = basePrice;
      if (commonIssues != null) body['commonIssues'] = commonIssues;
      if (isActive != null) body['isActive'] = isActive;
      if (sortOrder != null) body['sortOrder'] = sortOrder;

      final response = await client.put(
        Uri.parse(ApiEndpoints.adminUpdateServiceCategory(id)),
        headers: _headers(token),
        body: jsonEncode(body),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return ServiceCategoryModel.fromJson(data['data']['category']);
      } else {
        throw Exception(
            data['message'] ?? 'Không thể cập nhật danh mục dịch vụ');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Không thể kết nối đến máy chủ: $e');
    }
  }

  /// Đổi trạng thái kích hoạt danh mục dịch vụ (Ẩn/Hiện)
  Future<ServiceCategoryModel> toggleCategoryStatus({
    required String token,
    required String id,
  }) async {
    try {
      final response = await client.put(
        Uri.parse(ApiEndpoints.adminToggleServiceCategory(id)),
        headers: _headers(token),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return ServiceCategoryModel.fromJson(data['data']['category']);
      } else {
        throw Exception(data['message'] ?? 'Không thể đổi trạng thái danh mục');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Không thể kết nối đến máy chủ: $e');
    }
  }

  /// Xóa danh mục dịch vụ
  Future<Map<String, dynamic>> deleteCategory({
    required String token,
    required String id,
  }) async {
    try {
      final response = await client.delete(
        Uri.parse(ApiEndpoints.adminDeleteServiceCategory(id)),
        headers: _headers(token),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'message': data['message'] ?? 'Đã xóa danh mục thành công',
          'softDeleted': data['data']?['softDeleted'] ?? false,
        };
      } else {
        throw Exception(data['message'] ?? 'Không thể xóa danh mục');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Không thể kết nối đến máy chủ: $e');
    }
  }
}
