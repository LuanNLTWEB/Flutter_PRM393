import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_endpoints.dart';
import '../../../repair_request/data/models/repair_request_model.dart';
import '../models/quotation_model.dart';

/// Kết quả lấy danh sách báo giá kèm trạng thái phiếu yêu cầu
class QuotationListResult {
  final List<QuotationModel> quotations;
  final String requestStatus;

  const QuotationListResult({
    required this.quotations,
    required this.requestStatus,
  });
}

/// 1 mục trong "Yêu cầu đã báo giá" của Thợ: báo giá + phiếu yêu cầu tương ứng
class MyQuotationItem {
  final QuotationModel quote;
  final RepairRequestModel request;

  const MyQuotationItem({required this.quote, required this.request});
}

class QuotationRemoteDataSource {
  final http.Client client;

  QuotationRemoteDataSource({http.Client? client})
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

  /// Thợ gửi báo giá (UC-QUO-04)
  Future<QuotationModel> sendQuotation({
    required String token,
    required String requestId,
    required double labourCost,
    double partsCost = 0,
    String note = '',
  }) async {
    final response = await client.post(
      Uri.parse(ApiEndpoints.quotations),
      headers: _headers(token),
      body: json.encode({
        'requestId': requestId,
        'labourCost': labourCost,
        'partsCost': partsCost,
        'note': note,
      }),
    );

    final data = _decode(response);
    if (response.statusCode == 201 && data['success'] == true) {
      final quotation = data['data']?['quotation'];
      if (quotation is Map<String, dynamic>) {
        return QuotationModel.fromJson(quotation);
      }
      throw Exception('Không nhận được dữ liệu báo giá');
    }
    throw Exception(data['message'] ?? 'Gửi báo giá thất bại');
  }

  /// Xem danh sách báo giá của 1 yêu cầu (UC-QUO-06)
  Future<QuotationListResult> fetchQuotations({
    required String token,
    required String requestId,
  }) async {
    final uri = Uri.parse(ApiEndpoints.quotations)
        .replace(queryParameters: {'requestId': requestId});

    final response = await client.get(uri, headers: _headers(token));

    final data = _decode(response);
    if (response.statusCode == 200 && data['success'] == true) {
      final rawList = data['data']?['quotations'];
      final quotations = (rawList is List ? rawList : const [])
          .whereType<Map<String, dynamic>>()
          .map(QuotationModel.fromJson)
          .toList();
      return QuotationListResult(
        quotations: quotations,
        requestStatus: data['data']?['requestStatus']?.toString() ?? 'OPEN',
      );
    }
    throw Exception(data['message'] ?? 'Không thể tải danh sách báo giá');
  }

  /// Xem danh sách "Yêu cầu đã báo giá" của chính Thợ (UC-QUO-05)
  Future<List<MyQuotationItem>> fetchMyQuotations({
    required String token,
  }) async {
    final response = await client.get(
      Uri.parse(ApiEndpoints.myQuotations),
      headers: _headers(token),
    );

    final data = _decode(response);
    if (response.statusCode == 200 && data['success'] == true) {
      final rawList = data['data']?['quotations'];
      return (rawList is List ? rawList : const [])
          .whereType<Map<String, dynamic>>()
          .map((item) {
            final rawRequest = item['requestId'];
            return MyQuotationItem(
              quote: QuotationModel.fromJson(item),
              request: rawRequest is Map<String, dynamic>
                  ? RepairRequestModel.fromJson(rawRequest)
                  : RepairRequestModel(
                      id: '',
                      customerId: '',
                      serviceCategoryId: '',
                      title: 'Yêu cầu đã bị xóa',
                      description: '',
                      location: const RepairLocationModel(address: ''),
                      contactPhone: '',
                      createdAt: DateTime(1970),
                      updatedAt: DateTime(1970),
                    ),
            );
          })
          .toList();
    }
    throw Exception(data['message'] ?? 'Không thể tải danh sách đã báo giá');
  }

  /// Thợ chỉnh sửa báo giá (UC-QUO-05)
  Future<QuotationModel> updateQuotation({
    required String token,
    required String id,
    required double labourCost,
    double partsCost = 0,
    String note = '',
  }) async {
    final response = await client.put(
      Uri.parse(ApiEndpoints.quotationDetail(id)),
      headers: _headers(token),
      body: json.encode({
        'labourCost': labourCost,
        'partsCost': partsCost,
        'note': note,
      }),
    );

    final data = _decode(response);
    if (response.statusCode == 200 && data['success'] == true) {
      final quotation = data['data']?['quotation'];
      if (quotation is Map<String, dynamic>) {
        return QuotationModel.fromJson(quotation);
      }
      throw Exception('Không nhận được dữ liệu báo giá');
    }
    throw Exception(data['message'] ?? 'Cập nhật báo giá thất bại');
  }

  /// Thợ thu hồi báo giá (UC-QUO-05)
  Future<void> retractQuotation({
    required String token,
    required String id,
  }) async {
    final response = await client.patch(
      Uri.parse(ApiEndpoints.quotationRetract(id)),
      headers: _headers(token),
    );

    final data = _decode(response);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Thu hồi báo giá thất bại');
    }
  }

  /// Khách chấp nhận báo giá - chốt thợ (UC-QUO-08)
  Future<void> acceptQuotation({
    required String token,
    required String id,
  }) async {
    final response = await client.post(
      Uri.parse(ApiEndpoints.quotationAccept(id)),
      headers: _headers(token),
    );

    final data = _decode(response);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Chấp nhận báo giá thất bại');
    }
  }

  /// Khách từ chối báo giá (UC-QUO-09)
  Future<void> rejectQuotation({
    required String token,
    required String id,
  }) async {
    final response = await client.post(
      Uri.parse(ApiEndpoints.quotationReject(id)),
      headers: _headers(token),
    );

    final data = _decode(response);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Từ chối báo giá thất bại');
    }
  }
}
