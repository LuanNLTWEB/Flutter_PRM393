import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_endpoints.dart';
import '../models/service_category_model.dart';
import '../models/repair_request_model.dart';

class RepairRequestRemoteDataSource {
  final http.Client client;

  RepairRequestRemoteDataSource({http.Client? client})
      : client = client ?? http.Client();

  Map<String, String> _headers([String? token]) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  // Lấy danh sách danh mục dịch vụ
  Future<List<ServiceCategoryModel>> getCategories() async {
    try {
      final response = await client.get(
        Uri.parse(ApiEndpoints.serviceCategories),
        headers: _headers(),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final List<dynamic> list = data['data']?['categories'] ?? [];
        return list
            .map((item) => ServiceCategoryModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
          data['message'] ?? 'Không thể tải danh sách danh mục dịch vụ',
        );
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Không thể kết nối đến máy chủ: $e');
    }
  }

  // Lấy chi tiết một danh mục dịch vụ
  Future<ServiceCategoryModel> getCategoryDetail(String identifier) async {
    try {
      final response = await client.get(
        Uri.parse(ApiEndpoints.serviceCategoryDetail(identifier)),
        headers: _headers(),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final categoryData = data['data']?['category'];
        if (categoryData != null) {
          return ServiceCategoryModel.fromJson(categoryData as Map<String, dynamic>);
        }
        throw Exception('Dữ liệu danh mục không tồn tại');
      } else {
        throw Exception(
          data['message'] ?? 'Không thể tải chi tiết danh mục dịch vụ',
        );
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Không thể kết nối đến máy chủ: $e');
    }
  }

  // Tạo yêu cầu sửa chữa mới (kèm khung giờ hẹn thợ đến nhà)
  Future<RepairRequestModel> createRepairRequest({
    required String token,
    required String serviceCategoryId,
    required String title,
    required String description,
    String urgency = 'medium',
    DateTime? preferredTime,
  }) async {
    try {
      final body = jsonEncode({
        'serviceCategoryId': serviceCategoryId,
        'title': title,
        'description': description,
        'urgency': urgency,
        if (preferredTime != null) 'preferredTime': preferredTime.toIso8601String(),
      });

      final response = await client.post(
        Uri.parse(ApiEndpoints.requests),
        headers: _headers(token),
        body: body,
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        final requestData = data['data']?['repairRequest'];
        if (requestData != null) {
          return RepairRequestModel.fromJson(requestData as Map<String, dynamic>);
        }
        throw Exception('Dữ liệu yêu cầu không hợp lệ');
      } else {
        throw Exception(
          data['message'] ?? 'Không thể tạo yêu cầu sửa chữa',
        );
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Không thể kết nối đến máy chủ: $e');
    }
  }
}
