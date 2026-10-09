import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../auth/data/models/user_model.dart';

class TechnicianRemoteDataSource {
  final http.Client client;

  TechnicianRemoteDataSource({http.Client? client})
      : client = client ?? http.Client();

  MediaType _getMediaType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      case 'heic':
      case 'heif':
        return MediaType('image', 'heic');
      case 'jpg':
      case 'jpeg':
      default:
        return MediaType('image', 'jpeg');
    }
  }

  String _sanitizeImageName(String name, String fallbackName) {
    if (name.isEmpty) return fallbackName;
    if (!name.contains('.')) return '$name.jpg';
    return name;
  }

  /// Đăng ký tài khoản thợ kèm upload CCCD và chứng chỉ qua multipart
  Future<Map<String, dynamic>> registerTechnician({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
    required DateTime dateOfBirth,
    required String gender,
    required List<String> skills,
    required int experienceYears,
    required String bio,
    required XFile idCardFront,
    required XFile idCardBack,
    List<XFile> certificates = const [],
  }) async {
    final uri = Uri.parse(ApiEndpoints.registerTechnician);
    final request = http.MultipartRequest('POST', uri);

    // Text fields
    request.fields['fullName'] = fullName.trim();
    request.fields['email'] = email.trim().toLowerCase();
    request.fields['phoneNumber'] = phoneNumber.trim();
    request.fields['password'] = password;
    request.fields['confirmPassword'] = confirmPassword;
    request.fields['dateOfBirth'] = dateOfBirth.toIso8601String();
    request.fields['gender'] = gender;
    request.fields['skills'] = skills.join(',');
    request.fields['experienceYears'] = experienceYears.toString();
    request.fields['bio'] = bio.trim();

    // CCCD mặt trước
    final frontBytes = await idCardFront.readAsBytes();
    final frontName = _sanitizeImageName(idCardFront.name, 'id_front.jpg');
    request.files.add(
      http.MultipartFile.fromBytes(
        'idCardFront',
        frontBytes,
        filename: frontName,
        contentType: _getMediaType(frontName),
      ),
    );

    // CCCD mặt sau
    final backBytes = await idCardBack.readAsBytes();
    final backName = _sanitizeImageName(idCardBack.name, 'id_back.jpg');
    request.files.add(
      http.MultipartFile.fromBytes(
        'idCardBack',
        backBytes,
        filename: backName,
        contentType: _getMediaType(backName),
      ),
    );

    // Chứng chỉ nghề
    for (int i = 0; i < certificates.length; i++) {
      final cert = certificates[i];
      final certBytes = await cert.readAsBytes();
      final certName = _sanitizeImageName(cert.name, 'cert_$i.jpg');
      request.files.add(
        http.MultipartFile.fromBytes(
          'certificates',
          certBytes,
          filename: certName,
          contentType: _getMediaType(certName),
        ),
      );
    }


    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = json.decode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 201 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Đăng ký thợ thất bại');
    }
  }

  /// Lấy danh sách thợ công khai đã được duyệt
  Future<List<UserModel>> getPublicTechnicians({
    String? skill,
    String? search,
  }) async {
    final queryParams = <String, String>{};
    if (skill != null && skill.isNotEmpty) queryParams['skill'] = skill;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final uri = Uri.parse(ApiEndpoints.publicTechnicians)
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    final response = await client.get(uri);
    final data = json.decode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200 && data['success'] == true) {
      final List rawList = data['data']['technicians'] ?? [];
      return rawList.map((item) => UserModel.fromJson(item)).toList();
    } else {
      throw Exception(data['message'] ?? 'Không thể tải danh sách thợ');
    }
  }

  /// Lấy chi tiết hồ sơ công khai của thợ
  Future<UserModel> getPublicTechnicianDetail(String id) async {
    final uri = Uri.parse(ApiEndpoints.publicTechnicianDetail(id));
    final response = await client.get(uri);
    final data = json.decode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200 && data['success'] == true) {
      return UserModel.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Không thể tải chi tiết hồ sơ thợ');
    }
  }

  /// Thợ tự bật/tắt nhận việc
  Future<bool> toggleAvailability(String token, {bool? isAvailable}) async {
    final uri = Uri.parse(ApiEndpoints.technicianAvailability);
    final response = await client.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(isAvailable != null ? {'isAvailable': isAvailable} : {}),
    );

    final data = json.decode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200 && data['success'] == true) {
      return data['data']['isAvailable'] == true;
    } else {
      throw Exception(data['message'] ?? 'Không thể thay đổi trạng thái nhận việc');
    }
  }

  /// Lấy danh sách thợ KYC cho Admin & Staff
  Future<List<UserModel>> getKYCTechnicians(
    String token, {
    String status = 'pending',
  }) async {
    final uri = Uri.parse('${ApiEndpoints.adminKYCTechnicians}?status=$status');
    final response = await client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final data = json.decode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200 && data['success'] == true) {
      final List rawList = data['data']['technicians'] ?? [];
      return rawList.map((item) => UserModel.fromJson(item)).toList();
    } else {
      throw Exception(data['message'] ?? 'Không thể tải danh sách duyệt KYC');
    }
  }

  /// Phê duyệt hồ sơ Thợ
  Future<void> approveTechnician(String token, String id) async {
    final uri = Uri.parse(ApiEndpoints.adminApproveTechnician(id));
    final response = await client.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final data = json.decode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Không thể phê duyệt hồ sơ thợ');
    }
  }

  /// Từ chối hồ sơ Thợ kèm lý do
  Future<void> rejectTechnician(
    String token,
    String id,
    String reason,
  ) async {
    final uri = Uri.parse(ApiEndpoints.adminRejectTechnician(id));
    final response = await client.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'reason': reason}),
    );

    final data = json.decode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Không thể từ chối hồ sơ thợ');
    }
  }
}
