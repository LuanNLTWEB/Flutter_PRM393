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
}
