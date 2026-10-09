import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_endpoints.dart';
import '../../../repair_request/data/models/repair_request_model.dart';

/// Kết quả feed yêu cầu quanh đây (UC-QUO-01)
class NearbyRequestResult {
  final List<RepairRequestModel> requests;
  final int total;
  final int page;
  final int totalPages;
  final bool hasLocation;

  const NearbyRequestResult({
    required this.requests,
    required this.total,
    required this.page,
    required this.totalPages,
    required this.hasLocation,
  });
}

/// Đọc phiếu yêu cầu dành cho Thợ: feed quanh đây & chi tiết (UC-QUO-01 / UC-QUO-03)
class NearbyRequestRemoteDataSource {
  final http.Client client;

  NearbyRequestRemoteDataSource({http.Client? client})
      : client = client ?? http.Client();

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  Map<String, dynamic> _decode(http.Response response) {
    final data = json.decode(utf8.decode(response.bodyBytes));
    if (data is Map<String, dynamic>) return data;
    throw Exception('Phản hồi không hợp lệ từ máy chủ');
  }

  /// Danh sách yêu cầu đang mở (lọc theo danh mục, khẩn cấp, tọa độ)
  Future<NearbyRequestResult> fetchNearbyRequests({
    required String token,
    String? categorySlug,
    String? urgency,
    double? latitude,
    double? longitude,
    double? radiusKm,
    int page = 1,
    int limit = 20,
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (categorySlug != null && categorySlug.isNotEmpty)
        'categorySlug': categorySlug,
      if (urgency != null && urgency.isNotEmpty) 'urgency': urgency,
      if (latitude != null) 'lat': latitude.toString(),
      if (longitude != null) 'lng': longitude.toString(),
      if (radiusKm != null) 'radiusKm': radiusKm.toString(),
    };

    final uri = Uri.parse(ApiEndpoints.nearbyRequests).replace(
      queryParameters: query.isEmpty ? null : query,
    );

    final response = await client.get(uri, headers: _headers(token));

    final data = _decode(response);
    if (response.statusCode == 200 && data['success'] == true) {
      final rawList = data['data']?['requests'];
      final requests = (rawList is List ? rawList : const [])
          .whereType<Map<String, dynamic>>()
          .map(RepairRequestModel.fromJson)
          .toList();
      return NearbyRequestResult(
        requests: requests,
        total: (data['data']?['total'] as num?)?.toInt() ?? requests.length,
        page: (data['data']?['page'] as num?)?.toInt() ?? page,
        totalPages: (data['data']?['totalPages'] as num?)?.toInt() ?? 1,
        hasLocation: data['data']?['hasLocation'] == true,
      );
    }
    throw Exception(data['message'] ?? 'Không thể tải danh sách yêu cầu');
  }

  /// Chi tiết 1 phiếu yêu cầu (UC-QUO-03)
  Future<RepairRequestModel> fetchRequestDetail({
    required String token,
    required String id,
  }) async {
    final response = await client.get(
      Uri.parse(ApiEndpoints.requestDetail(id)),
      headers: _headers(token),
    );

    final data = _decode(response);
    if (response.statusCode == 200 && data['success'] == true) {
      final detail = data['data']?['repairRequest'];
      if (detail is Map<String, dynamic>) {
        return RepairRequestModel.fromJson(detail);
      }
      throw Exception('Không nhận được dữ liệu phiếu yêu cầu');
    }
    throw Exception(data['message'] ?? 'Không thể tải chi tiết yêu cầu');
  }
}
