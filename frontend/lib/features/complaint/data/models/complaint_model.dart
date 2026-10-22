class ComplaintModel {
  final String id;
  final String requestId;
  final String requestTitle;
  final String requestStatus;
  final String reporterName;
  final String reporterRole;
  final String respondentName;
  final String respondentRole;
  final String category;
  final String subject;
  final String description;
  final String staffNote;
  final String status;
  final String? handledByName;
  final DateTime? handledAt;
  final DateTime? createdAt;

  const ComplaintModel({
    required this.id,
    required this.requestId,
    required this.requestTitle,
    required this.requestStatus,
    required this.reporterName,
    required this.reporterRole,
    required this.respondentName,
    required this.respondentRole,
    required this.category,
    required this.subject,
    required this.description,
    required this.staffNote,
    required this.status,
    this.handledByName,
    this.handledAt,
    this.createdAt,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    final request = _asMap(json['requestId']);
    final reporter = _asMap(json['reporterId']);
    final respondent = _asMap(json['respondentId']);
    final handledBy = _asMap(json['handledBy']);

    return ComplaintModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      requestId: (request['_id'] ?? json['requestId'] ?? '').toString(),
      requestTitle: (request['title'] ?? 'Đơn sửa chữa').toString(),
      requestStatus: (request['status'] ?? '').toString(),
      reporterName: (reporter['fullName'] ?? 'Khách hàng').toString(),
      reporterRole: (reporter['role'] ?? '').toString(),
      respondentName: (respondent['fullName'] ?? 'Bên liên quan').toString(),
      respondentRole: (respondent['role'] ?? '').toString(),
      category: (json['category'] ?? 'OTHER').toString().toUpperCase(),
      subject: (json['subject'] ?? 'Khiếu nại dịch vụ').toString(),
      description: (json['description'] ?? '').toString(),
      staffNote: (json['staffNote'] ?? '').toString(),
      status: (json['status'] ?? 'RECEIVED').toString().toUpperCase(),
      handledByName: handledBy['fullName']?.toString(),
      handledAt: _parseDate(json['handledAt']),
      createdAt: _parseDate(json['createdAt']),
    );
  }

  bool get isFinal => status == 'RESOLVED' || status == 'REJECTED';

  String get statusDisplay {
    switch (status) {
      case 'RECEIVED':
        return 'Mới tiếp nhận';
      case 'IN_REVIEW':
        return 'Đang xử lý';
      case 'RESOLVED':
        return 'Đã giải quyết';
      case 'REJECTED':
        return 'Không chấp nhận';
      default:
        return status;
    }
  }

  String get categoryDisplay {
    switch (category) {
      case 'SERVICE_QUALITY':
        return 'Chất lượng dịch vụ';
      case 'PRICING':
        return 'Chi phí / báo giá';
      case 'BEHAVIOR':
        return 'Thái độ phục vụ';
      case 'PAYMENT':
        return 'Thanh toán';
      default:
        return 'Khác';
    }
  }

  static Map<String, dynamic> _asMap(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  static DateTime? _parseDate(dynamic value) =>
      value == null ? null : DateTime.tryParse(value.toString())?.toLocal();
}
