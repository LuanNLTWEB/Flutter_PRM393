import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_endpoints.dart';
import '../models/notification_model.dart';

class NotificationRemoteDataSource {
  final http.Client client;

  NotificationRemoteDataSource({http.Client? client})
      : client = client ?? http.Client();

  /// Lấy danh sách thông báo kèm phân trang và lọc
  Future<Map<String, dynamic>> getNotifications(
    String token, {
    int page = 1,
    int limit = 20,
    bool? isRead,
    String? type,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (isRead != null) {
      queryParams['isRead'] = isRead.toString();
    }
    if (type != null && type.isNotEmpty) {
      queryParams['type'] = type;
    }

    final uri = Uri.parse(ApiEndpoints.notifications)
        .replace(queryParameters: queryParams);

    final response = await client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = json.decode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200 && data['success'] == true) {
      final List rawList = data['data']['notifications'] ?? [];
      final notifications =
          rawList.map((item) => NotificationModel.fromJson(item)).toList();

      return {
        'notifications': notifications,
        'total': (data['data']['total'] as num?)?.toInt() ?? 0,
        'unreadCount': (data['data']['unreadCount'] as num?)?.toInt() ?? 0,
        'page': (data['data']['page'] as num?)?.toInt() ?? 1,
        'totalPages': (data['data']['totalPages'] as num?)?.toInt() ?? 1,
      };
    } else {
      throw Exception(data['message'] ?? 'Không thể tải danh sách thông báo');
    }
  }

  /// Lấy số lượng thông báo chưa đọc
  Future<int> getUnreadCount(String token) async {
    final uri = Uri.parse(ApiEndpoints.unreadNotificationCount);
    final response = await client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = json.decode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200 && data['success'] == true) {
      return (data['data']['unreadCount'] as num?)?.toInt() ?? 0;
    } else {
      throw Exception(
          data['message'] ?? 'Không thể tải số lượng thông báo chưa đọc');
    }
  }

  /// Đánh dấu 1 thông báo là đã đọc
  Future<NotificationModel> markAsRead(String token, String id) async {
    final uri = Uri.parse(ApiEndpoints.markNotificationAsRead(id));
    final response = await client.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = json.decode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200 && data['success'] == true) {
      return NotificationModel.fromJson(data['data']['notification']);
    } else {
      throw Exception(
          data['message'] ?? 'Không thể đánh dấu thông báo là đã đọc');
    }
  }

  /// Đánh dấu tất cả thông báo là đã đọc
  Future<int> markAllAsRead(String token) async {
    final uri = Uri.parse(ApiEndpoints.markAllNotificationsAsRead);
    final response = await client.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = json.decode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200 && data['success'] == true) {
      return (data['data']['modifiedCount'] as num?)?.toInt() ?? 0;
    } else {
      throw Exception(
          data['message'] ?? 'Không thể đánh dấu tất cả thông báo đã đọc');
    }
  }

  /// Xóa 1 thông báo
  Future<bool> deleteNotification(String token, String id) async {
    final uri = Uri.parse(ApiEndpoints.deleteNotification(id));
    final response = await client.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = json.decode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200 && data['success'] == true) {
      return true;
    } else {
      throw Exception(data['message'] ?? 'Không thể xóa thông báo');
    }
  }

  /// Xóa toàn bộ thông báo
  Future<bool> clearAllNotifications(String token) async {
    final uri = Uri.parse(ApiEndpoints.clearAllNotifications);
    final response = await client.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = json.decode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200 && data['success'] == true) {
      return true;
    } else {
      throw Exception(data['message'] ?? 'Không thể xóa tất cả thông báo');
    }
  }
}
