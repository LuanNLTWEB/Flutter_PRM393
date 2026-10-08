import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../auth/data/models/user_model.dart';


class UserRemoteDataSource {
  final http.Client client;

  UserRemoteDataSource({http.Client? client})
      : client = client ?? http.Client();

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<UserModel> getProfile(String token) async {
    try {
      final response = await client.get(
        Uri.parse(ApiEndpoints.userProfile),
        headers: _headers(token),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return UserModel.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Không thể tải thông tin cá nhân');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Không thể kết nối đến máy chủ: $e');
    }
  }

  Future<UserModel> updateProfile({
    required String token,
    String? fullName,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? gender,
  }) async {
    try {
      final Map<String, dynamic> body = {};
      if (fullName != null) body['fullName'] = fullName;
      if (phoneNumber != null) body['phoneNumber'] = phoneNumber;
      if (dateOfBirth != null) {
        body['dateOfBirth'] = dateOfBirth.toIso8601String();
      }
      if (gender != null) body['gender'] = gender;

      final response = await client.put(
        Uri.parse(ApiEndpoints.userProfile),
        headers: _headers(token),
        body: jsonEncode(body),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return UserModel.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Cập nhật thông tin thất bại');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Không thể kết nối đến máy chủ: $e');
    }
  }

  Future<void> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await client.put(
        Uri.parse(ApiEndpoints.changePassword),
        headers: _headers(token),
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return;
      } else {
        throw Exception(data['message'] ?? 'Đổi mật khẩu thất bại');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Không thể kết nối đến máy chủ: $e');
    }
  }

  /// Cập nhật ảnh đại diện lên Cloudinary thông qua Backend
  Future<String> updateAvatar({
    required String token,
    required XFile imageFile,
  }) async {
    try {
      final uri = Uri.parse(ApiEndpoints.userAvatar);
      final request = http.MultipartRequest('PUT', uri);
      request.headers['Authorization'] = 'Bearer $token';

      final bytes = await imageFile.readAsBytes();
      final ext = imageFile.name.split('.').last.toLowerCase();
      final mediaType = ext == 'png'
          ? MediaType('image', 'png')
          : ext == 'webp'
              ? MediaType('image', 'webp')
              : MediaType('image', 'jpeg');
      final fileName = imageFile.name.contains('.')
          ? imageFile.name
          : '${imageFile.name}.jpg';

      request.files.add(
        http.MultipartFile.fromBytes(
          'avatar',
          bytes,
          filename: fileName,
          contentType: mediaType,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final Map<String, dynamic> data =
          jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 && data['success'] == true) {
        return data['data']['avatar'] ?? '';
      } else {
        throw Exception(data['message'] ?? 'Cập nhật ảnh đại diện thất bại');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Không thể kết nối đến máy chủ: $e');
    }
  }
}

