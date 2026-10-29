import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/network/api_endpoints.dart';
import '../models/order_history_model.dart';

class OrderHistoryRemoteDataSource {
  final http.Client client;

  OrderHistoryRemoteDataSource({http.Client? client})
    : client = client ?? http.Client();

  /// Lấy danh sách lịch sử đơn hàng
  Future<Map<String, dynamic>> getMyOrders({
    required String token,
    String? tab,
  }) async {
    try {
      String url = ApiEndpoints.myRepairRequests;
      if (tab != null && tab.isNotEmpty) {
        url += '?tab=$tab';
      }

      final response = await client.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> data = jsonDecode(
        utf8.decode(response.bodyBytes),
      );

      if (response.statusCode == 200 && data['data'] != null) {
        final content = data['data'];
        final List<OrderHistoryModel> orders =
            (content['requests'] as List? ?? [])
                .map((item) => OrderHistoryModel.fromJson(item))
                .toList();

        return {'orders': orders, 'counts': content['counts'] ?? {}};
      } else {
        final message = data['message'] ?? 'Không thể tải lịch sử đơn hàng';
        throw Exception(message);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Lỗi kết nối máy chủ: $e');
    }
  }

  /// Khách đồng ý / từ chối khung giờ thợ đề xuất (UC-LIC-01)
  Future<void> respondAppointment({
    required String token,
    required String requestId,
    required String action, // 'accept' | 'reject'
    String reason = '',
  }) async {
    final response = await client.patch(
      Uri.parse(ApiEndpoints.respondAppointment(requestId)),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'action': action,
        if (reason.isNotEmpty) 'reason': reason,
      }),
    );

    final Map<String, dynamic> data = jsonDecode(
      utf8.decode(response.bodyBytes),
    );

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Phản hồi lịch hẹn thất bại');
    }
  }

  /// Khách báo hủy tại chỗ để đưa thiết bị về xưởng (UC-WRK-07)
  Future<void> cancelOnsite({
    required String token,
    required String requestId,
    required String reason,
  }) async {
    final response = await client.patch(
      Uri.parse(ApiEndpoints.onsiteCancel(requestId)),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'reason': reason}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Báo hủy tại chỗ thất bại');
    }
  }
}
