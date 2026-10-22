import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/network/api_endpoints.dart';
import '../models/invoice_model.dart';

class InvoiceRemoteDataSource {
  final http.Client client;

  InvoiceRemoteDataSource({http.Client? client})
    : client = client ?? http.Client();

  Future<List<InvoiceModel>> getMyInvoices({required String token}) async {
    final response = await client.get(
      Uri.parse(ApiEndpoints.myInvoices),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Không thể tải hóa đơn');
    }

    final content = data['data'] as Map<String, dynamic>? ?? {};
    final invoices = content['invoices'] as List? ?? [];
    return invoices
        .map(
          (item) =>
              InvoiceModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }
}
