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

  // ══ START UC-QUO-01 + UC-QUO-02: Xem & lọc sự cố quanh đây ═════════════
  /// Danh sách sự cố quanh đây cho Thợ (UC-QUO-01)
  /// + lọc theo chuyên môn / khẩn cấp / khoảng cách (UC-QUO-02)
  /// → GET /api/requests/nearby
  /// Backend mặc định trả cả OPEN + QUOTED nên nhiều thợ cùng báo giá được.
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
  // ══ END UC-QUO-01 + UC-QUO-02 ════════════════════════════════════════

  // ══ START UC-QUO-03: Xem chi tiết sự cố ══════════════════════════════
  /// Chi tiết 1 phiếu yêu cầu → GET /api/requests/:id
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
  // ══ END UC-QUO-03 ════════════════════════════════════════════════════

  // ── UC-LIC-01: Lịch hẹn & Tiền ả (không thuộc epic Báo giá) ───────────

  /// Thợ xác nhận giờ hẹn (UC-LIC-01)
  Future<void> confirmAppointment({
    required String token,
    required String requestId,
  }) async {
    final response = await client.patch(
      Uri.parse(ApiEndpoints.confirmAppointment(requestId)),
      headers: _headers(token),
    );

    final data = _decode(response);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Xác nhận lịch hẹn thất bại');
    }
  }

  /// Thợ đề xuất khung giờ mới (UC-LIC-01)
  Future<void> proposeAppointment({
    required String token,
    required String requestId,
    required DateTime proposedTime,
    String note = '',
  }) async {
    final response = await client.patch(
      Uri.parse(ApiEndpoints.proposeAppointment(requestId)),
      headers: _headers(token),
      body: json.encode({
        // toUtc() để gửi kèm offset, tránh server hiểu nhầm là UTC
        'proposedTime': proposedTime.toUtc().toIso8601String(),
        if (note.isNotEmpty) 'note': note,
      }),
    );

    final data = _decode(response);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Đề xuất khung giờ mới thất bại');
    }
  }

  /// Thợ bấm "Đang trên đường đến nhà khách" (UC-DI-01)
  Future<void> markOnTheWay({
    required String token,
    required String requestId,
  }) async {
    final response = await client.patch(
      Uri.parse(ApiEndpoints.onTheWay(requestId)),
      headers: _headers(token),
    );

    final data = _decode(response);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Cập nhật trạng thái di chuyển thất bại');
    }
  }

  /// Thợ bấm "Đã có mặt tại hiện trường" (UC-ARR-01)
  Future<void> markArrived({
    required String token,
    required String requestId,
  }) async {
    final response = await client.patch(
      Uri.parse(ApiEndpoints.arrived(requestId)),
      headers: _headers(token),
    );

    final data = _decode(response);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Cập nhật trạng thái đã có mặt thất bại');
    }
  }

  /// Thợ bấm "Bắt đầu sửa chữa" (UC-WRK-02)
  Future<void> markWorking({
    required String token,
    required String requestId,
  }) async {
    final response = await client.patch(
      Uri.parse(ApiEndpoints.working(requestId)),
      headers: _headers(token),
    );

    final data = _decode(response);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Cập nhật trạng thái bắt đầu sửa chữa thất bại');
    }
  }

  /// Thợ khai báo chi phí phát sinh — nhiều mục/lần (UC-WRK-05)
  Future<List<Map<String, dynamic>>> declareAdditionalCost({
    required String token,
    required String requestId,
    required List<Map<String, dynamic>> items,
    String note = '',
  }) async {
    final response = await client.post(
      Uri.parse(ApiEndpoints.declareCost(requestId)),
      headers: _headers(token),
      body: jsonEncode({'items': items, 'note': note}),
    );

    final data = _decode(response);
    if (response.statusCode != 201 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Khai báo chi phí phát sinh thất bại');
    }
    final rawList = data['data']?['costs'];
    return (rawList is List ? rawList : const [])
        .whereType<Map<String, dynamic>>()
        .toList();
  }
}
