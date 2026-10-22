class InvoiceModel {
  final String id;
  final String invoiceNumber;
  final String requestTitle;
  final String serviceCategoryName;
  final String technicianName;
  final String technicianPhone;
  final String address;
  final double labourCost;
  final double partsCost;
  final double total;
  final String quotationNote;
  final DateTime? completedAt;
  final DateTime? issuedAt;

  const InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.requestTitle,
    required this.serviceCategoryName,
    required this.technicianName,
    required this.technicianPhone,
    required this.address,
    required this.labourCost,
    required this.partsCost,
    required this.total,
    required this.quotationNote,
    this.completedAt,
    this.issuedAt,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    final costs = json['costs'] is Map
        ? Map<String, dynamic>.from(json['costs'] as Map)
        : <String, dynamic>{};

    return InvoiceModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      invoiceNumber: (json['invoiceNumber'] ?? '').toString(),
      requestTitle: (json['requestTitle'] ?? 'Dịch vụ sửa chữa').toString(),
      serviceCategoryName: (json['serviceCategoryName'] ?? 'Dịch vụ sửa chữa')
          .toString(),
      technicianName: (json['technicianName'] ?? 'Chưa cập nhật').toString(),
      technicianPhone: (json['technicianPhone'] ?? '').toString(),
      address: (json['address'] ?? 'Chưa cập nhật địa chỉ').toString(),
      labourCost: (costs['labourCost'] as num?)?.toDouble() ?? 0,
      partsCost: (costs['partsCost'] as num?)?.toDouble() ?? 0,
      total: (costs['total'] as num?)?.toDouble() ?? 0,
      quotationNote: (json['quotationNote'] ?? '').toString(),
      completedAt: _parseDate(json['completedAt']),
      issuedAt: _parseDate(json['issuedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'invoiceNumber': invoiceNumber,
    'requestTitle': requestTitle,
    'serviceCategoryName': serviceCategoryName,
    'technicianName': technicianName,
    'technicianPhone': technicianPhone,
    'address': address,
    'costs': {'labourCost': labourCost, 'partsCost': partsCost, 'total': total},
    'quotationNote': quotationNote,
    'completedAt': completedAt?.toUtc().toIso8601String(),
    'issuedAt': issuedAt?.toUtc().toIso8601String(),
  };

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }
}
