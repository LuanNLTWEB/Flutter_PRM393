import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../repair_request/data/models/repair_request_model.dart';
import '../models/completion_qr_model.dart';

class CompletionRemoteDataSource {
  final http.Client client;

  CompletionRemoteDataSource({http.Client? client})
    : client = client ?? http.Client();

  Future<RepairRequestModel> uploadImages({
    required String token,
    required String requestId,
    required List<XFile> images,
  }) async {
    if (images.isEmpty) {
      throw Exception('Vui lòng chọn ít nhất một ảnh sau khi sửa');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiEndpoints.completionImages(requestId)),
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
      final fileName = image.name.contains('.')
          ? image.name
          : '${image.name}.jpg';

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
    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200 && data['success'] == true) {
      final rawRequest = data['data']?['repairRequest'];
      if (rawRequest is Map<String, dynamic>) {
        return RepairRequestModel.fromJson(rawRequest);
      }
      throw Exception('Không nhận được dữ liệu đơn hàng sau khi upload ảnh');
    }

    throw Exception(data['message'] ?? 'Upload ảnh sau khi sửa thất bại');
  }

  Future<CompletionQrModel> generateCompletionQr({
    required String token,
    required String requestId,
  }) async {
    final response = await client.post(
      Uri.parse(ApiEndpoints.completionQr(requestId)),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200 && data['success'] == true) {
      final rawQr = data['data']?['confirmationQr'];
      if (rawQr is Map<String, dynamic>) {
        return CompletionQrModel.fromJson(rawQr);
      }
      throw Exception('Không nhận được dữ liệu QR nghiệm thu');
    }

    throw Exception(data['message'] ?? 'Không thể tạo QR nghiệm thu');
  }

  Future<void> confirmCompletion({
    required String token,
    required String requestId,
    required String qrToken,
    required int amount,
  }) async {
    final response = await client.post(
      Uri.parse(ApiEndpoints.confirmCompletion(requestId)),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'token': qrToken, 'amount': amount}),
    );
    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200 && data['success'] == true) return;

    throw Exception(data['message'] ?? 'Không thể xác nhận nghiệm thu');
  }
}
