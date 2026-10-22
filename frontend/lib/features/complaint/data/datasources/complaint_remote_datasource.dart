import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/network/api_endpoints.dart';
import '../models/complaint_model.dart';

class ComplaintRemoteDataSource {
  final http.Client client;

  ComplaintRemoteDataSource({http.Client? client})
    : client = client ?? http.Client();

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<Map<String, dynamic>> getComplaints({
    required String token,
    String status = 'ALL',
  }) async {
    final uri = Uri.parse(ApiEndpoints.manageComplaints)
        .replace(queryParameters: status == 'ALL' ? null : {'status': status});
    final response = await client.get(uri, headers: _headers(token));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Không thể tải danh sách khiếu nại');
    }

    final content = data['data'] as Map<String, dynamic>? ?? {};
    final complaints = (content['complaints'] as List? ?? [])
        .map(
          (item) =>
              ComplaintModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
    return {
      'complaints': complaints,
      'counts': Map<String, dynamic>.from(content['counts'] as Map? ?? {}),
    };
  }

  Future<ComplaintModel> handleComplaint({
    required String token,
    required String complaintId,
    required String status,
    required String staffNote,
  }) async {
    final response = await client.patch(
      Uri.parse(ApiEndpoints.handleComplaint(complaintId)),
      headers: _headers(token),
      body: jsonEncode({'status': status, 'staffNote': staffNote.trim()}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Không thể cập nhật khiếu nại');
    }

    final content = data['data'] as Map<String, dynamic>? ?? {};
    return ComplaintModel.fromJson(
      Map<String, dynamic>.from(content['complaint'] as Map),
    );
  }
}
