import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_endpoints.dart';
import '../../../auth/data/models/user_model.dart';

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
}
