import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_endpoints.dart';
import '../models/invoice_model.dart';

class PaymentRemoteDataSource {
  final http.Client client;

  PaymentRemoteDataSource({http.Client? client})
      : client = client ?? http.Client();

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Map<String, dynamic> _decode(http.Response response) {
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is Map<String, dynamic>) return data;
    throw Exception('Phản hồi không hợp lệ từ máy chủ');
  }

  Future<InvoiceModel> getInvoice({
    required String token,
    required String requestId,
  }) async {
    final response = await client.get(
      Uri.parse(ApiEndpoints.invoice(requestId)),
      headers: _headers(token),
    );
    final data = _decode(response);

    if (response.statusCode == 200 && data['success'] == true) {
      final invoice = data['data']?['invoice'];
      if (invoice is Map<String, dynamic>) return InvoiceModel.fromJson(invoice);
    }
    throw Exception(data['message'] ?? 'Không thể tải hóa đơn');
  }

  Future<InvoiceModel> selectPaymentMethod({
    required String token,
    required String requestId,
    required String paymentMethod,
  }) async {
    final response = await client.put(
      Uri.parse(ApiEndpoints.paymentMethod(requestId)),
      headers: _headers(token),
      body: jsonEncode({'paymentMethod': paymentMethod}),
    );
    final data = _decode(response);

    if (response.statusCode == 200 && data['success'] == true) {
      final invoice = data['data']?['invoice'];
      if (invoice is Map<String, dynamic>) return InvoiceModel.fromJson(invoice);
    }
    throw Exception(data['message'] ?? 'Không thể lưu phương thức thanh toán');
  }

  Future<InvoiceModel> uploadPartsInvoiceImages({
    required String token,
    required String requestId,
    required List<XFile> images,
  }) async {
    if (images.isEmpty) {
      throw Exception('Vui lòng chọn ít nhất một ảnh hóa đơn linh kiện');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiEndpoints.partsInvoices(requestId)),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    for (final image in images) {
      final bytes = await image.readAsBytes();
      final extension = image.name.split('.').last.toLowerCase();
      final mediaType = extension == 'png'
          ? MediaType('image', 'png')
          : extension == 'webp'
              ? MediaType('image', 'webp')
              : MediaType('image', 'jpeg');
      final fileName =
          image.name.contains('.') ? image.name : '${image.name}.jpg';

      request.files.add(
        http.MultipartFile.fromBytes(
          'images',
          bytes,
          filename: fileName,
          contentType: mediaType,
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = _decode(response);

    if (response.statusCode == 200 && data['success'] == true) {
      final invoice = data['data']?['invoice'];
      if (invoice is Map<String, dynamic>) return InvoiceModel.fromJson(invoice);
    }
    throw Exception(data['message'] ?? 'Không thể tải ảnh hóa đơn linh kiện');
  }

  Future<InvoiceModel> confirmPaymentReceived({
    required String token,
    required String requestId,
  }) async {
    final response = await client.patch(
      Uri.parse(ApiEndpoints.confirmPayment(requestId)),
      headers: _headers(token),
    );
    final data = _decode(response);

    if (response.statusCode == 200 && data['success'] == true) {
      final invoice = data['data']?['invoice'];
      if (invoice is Map<String, dynamic>) return InvoiceModel.fromJson(invoice);
    }
    throw Exception(data['message'] ?? 'Không thể xác nhận thanh toán');
  }
}
