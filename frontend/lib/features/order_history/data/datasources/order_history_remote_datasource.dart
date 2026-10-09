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

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['data'] != null) {
        final content = data['data'];
        final List<OrderHistoryModel> orders = (content['requests'] as List? ?? [])
            .map((item) => OrderHistoryModel.fromJson(item))
            .toList();

        return {
          'orders': orders,
          'counts': content['counts'] ?? {},
        };
      } else {
        final message = data['message'] ?? 'Không thể tải lịch sử đơn hàng';
        throw Exception(message);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Lỗi kết nối máy chủ: $e');
    }
  }

  /// Tạo đơn hàng hoàn tất mẫu để kiểm thử đánh giá
  Future<OrderHistoryModel> seedDemoCompletedOrder({
    required String token,
  }) async {
    try {
      final response = await client.post(
        Uri.parse(ApiEndpoints.seedDemoRequest),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['data'] != null) {
        return OrderHistoryModel.fromJson(data['data']);
      } else {
        final message = data['message'] ?? 'Không thể tạo đơn hàng mẫu';
        throw Exception(message);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Lỗi kết nối máy chủ: $e');
    }
  }
}
