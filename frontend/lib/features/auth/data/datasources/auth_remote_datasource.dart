import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_endpoints.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';

class AuthRemoteDataSource {
  final http.Client client;

  AuthRemoteDataSource({http.Client? client})
      : client = client ?? http.Client();

  Future<Map<String, dynamic>> register(RegisterRequest request) async {
    try {
      final response = await client.post(
        Uri.parse(ApiEndpoints.register),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      final Map<String, dynamic> data =
          jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 201) {
        return data;
      } else {
        final message = data['message'] ?? 'Đăng ký không thành công';
        throw Exception(message);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Không thể kết nối đến máy chủ: $e');
    }
  }

  Future<Map<String, dynamic>> login(LoginRequest request) async {
    try {
      final response = await client.post(
        Uri.parse(ApiEndpoints.login),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      final Map<String, dynamic> data =
          jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        return data;
      } else {
        final message = data['message'] ?? 'Đăng nhập không thành công';
        throw Exception(message);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Không thể kết nối đến máy chủ: $e');
    }
  }

  /// Yêu cầu gửi mã OTP đặt lại mật khẩu về email
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await client.post(
        Uri.parse(ApiEndpoints.forgotPassword),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email.trim().toLowerCase()}),
      );

      final Map<String, dynamic> data =
          jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      } else {
        final message = data['message'] ?? 'Gửi mã OTP thất bại';
        throw Exception(message);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Không thể kết nối đến máy chủ: $e');
    }
  }

  /// Xác thực mã OTP 6 số và nhận Reset Token tạm thời
  Future<String> verifyOtp(String email, String otp) async {
    try {
      final response = await client.post(
        Uri.parse(ApiEndpoints.verifyOtp),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'otp': otp.trim(),
        }),
      );

      final Map<String, dynamic> data =
          jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 && data['success'] == true) {
        final token = data['data']?['resetToken'] as String?;
        if (token == null || token.isEmpty) {
          throw Exception('Không nhận được mã xác thực từ máy chủ');
        }
        return token;
      } else {
        final message = data['message'] ?? 'Xác thực OTP thất bại';
        throw Exception(message);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Không thể kết nối đến máy chủ: $e');
    }
  }

  /// Đặt mật khẩu mới bằng Reset Token
  Future<Map<String, dynamic>> resetPassword({
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await client.post(
        Uri.parse(ApiEndpoints.resetPassword),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'resetToken': resetToken,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        }),
      );

      final Map<String, dynamic> data =
          jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      } else {
        final message = data['message'] ?? 'Đặt lại mật khẩu thất bại';
        throw Exception(message);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Không thể kết nối đến máy chủ: $e');
    }
  }
}
