class InvoiceModel {
  final String requestId;
  final String quotationId;
  final String serviceTitle;
  final String serviceCategoryName;
  final String technicianName;
  final String technicianAvatar;
  final double labourCost;
  final double partsCost;
  final double total;
  final String requestStatus;
  final List<String> completionImages;
  final List<String> partsInvoiceImages;
  final String? paymentMethod;
  final String paymentStatus;
  final DateTime? paidAt;

  const InvoiceModel({
    required this.requestId,
    required this.quotationId,
    required this.serviceTitle,
    required this.serviceCategoryName,
    required this.technicianName,
    required this.technicianAvatar,
    required this.labourCost,
    required this.partsCost,
    required this.total,
    required this.requestStatus,
    required this.completionImages,
    this.partsInvoiceImages = const [],
    required this.paymentMethod,
    required this.paymentStatus,
    this.paidAt,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      requestId: json['requestId']?.toString() ?? '',
      quotationId: json['quotationId']?.toString() ?? '',
      serviceTitle: json['serviceTitle']?.toString() ?? 'Dịch vụ sửa chữa',
      serviceCategoryName:
          json['serviceCategoryName']?.toString() ?? 'Dịch vụ sửa chữa',
      technicianName: json['technicianName']?.toString() ?? 'Thợ sửa chữa',
      technicianAvatar: json['technicianAvatar']?.toString() ?? '',
      labourCost: (json['labourCost'] as num?)?.toDouble() ?? 0,
      partsCost: (json['partsCost'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      requestStatus: json['requestStatus']?.toString() ?? 'ACCEPTED',
      completionImages: json['completionImages'] != null
          ? List<String>.from(json['completionImages'])
          : const [],
      partsInvoiceImages: json['partsInvoiceImages'] != null
          ? List<String>.from(json['partsInvoiceImages'])
          : const [],
      paymentMethod: json['paymentMethod']?.toString(),
      paymentStatus: json['paymentStatus']?.toString() ?? 'UNPAID',
      paidAt: json['paidAt'] != null
          ? DateTime.tryParse(json['paidAt'].toString())
          : null,
    );
  }

  bool get isPaid => paymentStatus == 'PAID';

  String get paymentMethodLabel {
    switch (paymentMethod) {
      case 'CASH':
        return 'Tiền mặt tại chỗ';
      default:
        return 'Chưa xác nhận';
    }
  }
}
