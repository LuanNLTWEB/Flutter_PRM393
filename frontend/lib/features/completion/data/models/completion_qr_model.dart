class CompletionQrModel {
  final String requestId;
  final int amount;
  final String payload;
  final DateTime expiresAt;

  const CompletionQrModel({
    required this.requestId,
    required this.amount,
    required this.payload,
    required this.expiresAt,
  });

  factory CompletionQrModel.fromJson(Map<String, dynamic> json) {
    final expiresAt = DateTime.tryParse(json['expiresAt']?.toString() ?? '');
    if (expiresAt == null) {
      throw const FormatException('Thời hạn QR nghiệm thu không hợp lệ');
    }

    return CompletionQrModel(
      requestId: json['requestId']?.toString() ?? '',
      amount: (json['amount'] as num?)?.round() ?? 0,
      payload: json['payload']?.toString() ?? '',
      expiresAt: expiresAt.toLocal(),
    );
  }
}

class CompletionQrPayload {
  final String requestId;
  final int amount;
  final String token;

  const CompletionQrPayload({
    required this.requestId,
    required this.amount,
    required this.token,
  });

  static CompletionQrPayload? tryParse(String rawValue) {
    final uri = Uri.tryParse(rawValue.trim());
    if (uri == null || uri.scheme != 'homefix' || uri.host != 'completion') {
      return null;
    }

    final requestId = uri.queryParameters['requestId']?.trim() ?? '';
    final token = uri.queryParameters['token']?.trim() ?? '';
    final amount = int.tryParse(uri.queryParameters['amount'] ?? '');
    if (requestId.isEmpty || token.isEmpty || amount == null || amount < 0) {
      return null;
    }

    return CompletionQrPayload(
      requestId: requestId,
      amount: amount,
      token: token,
    );
  }
}
