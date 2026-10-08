import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_endpoints.dart';
import '../models/review_model.dart';

class ReviewRemoteDataSource {
  final http.Client client;

  ReviewRemoteDataSource({http.Client? client})
      : client = client ?? http.Client();

  /// Lấy danh sách tag đánh giá gợi ý từ server
  Future<List<String>> getReviewTags() async {
    try {
      final response = await client.get(
        Uri.parse(ApiEndpoints.reviewTags),
        headers: {'Accept': 'application/json'},
      );

      final Map<String, dynamic> data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['data'] != null) {
        return List<String>.from((data['data'] as List).map((e) => e.toString()));
      }
      return [
        'Đúng giờ',
        'Tay nghề cao',
        'Nhiệt tình & Lịch sự',
        'Giá cả hợp lý',
        'Làm việc cẩn thận',
        'Dọn dẹp sạch sẽ',
      ];
    } catch (_) {
      return [
        'Đúng giờ',
        'Tay nghề cao',
        'Nhiệt tình & Lịch sự',
        'Giá cả hợp lý',
        'Làm việc cẩn thận',
        'Dọn dẹp sạch sẽ',
      ];
    }
  }

  /// Lấy danh sách thợ kỹ thuật
  Future<List<Map<String, dynamic>>> getTechnicians() async {
    try {
      final response = await client.get(
        Uri.parse(ApiEndpoints.technicians),
        headers: {'Accept': 'application/json'},
      );

      final Map<String, dynamic> data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Gửi đánh giá cho thợ (UC-RAT-01)
  Future<ReviewModel> createReview({
    required String token,
    required String technicianId,
    required double rating,
    required List<String> tags,
    required String comment,
    String? bookingId,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'technicianId': technicianId,
        'rating': rating,
        'tags': tags,
        'comment': comment,
      };
      if (bookingId != null) {
        requestBody['bookingId'] = bookingId;
      }

      final response = await client.post(
        Uri.parse(ApiEndpoints.createReview),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['data'] != null) {
        return ReviewModel.fromJson(data['data']);
      } else {
        final message = data['message'] ?? 'Không thể gửi đánh giá';
        throw Exception(message);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Lỗi kết nối máy chủ: $e');
    }
  }

  /// Lấy danh sách đánh giá & thống kê của thợ kỹ thuật
  Future<Map<String, dynamic>> getTechnicianReviews({
    required String technicianId,
    int page = 1,
    int? star,
  }) async {
    try {
      String url = '${ApiEndpoints.technicianReviews(technicianId)}?page=$page';
      if (star != null && star > 0) {
        url += '&star=$star';
      }

      final response = await client.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['data'] != null) {
        final content = data['data'];
        final summary = ReviewSummaryModel.fromJson(content['summary'] ?? {});
        final List<ReviewModel> reviews = (content['reviews'] as List? ?? [])
            .map((item) => ReviewModel.fromJson(item))
            .toList();

        return {
          'summary': summary,
          'reviews': reviews,
          'pagination': content['pagination'],
        };
      } else {
        final message = data['message'] ?? 'Không thể tải danh sách đánh giá';
        throw Exception(message);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Lỗi kết nối máy chủ: $e');
    }
  }
}
