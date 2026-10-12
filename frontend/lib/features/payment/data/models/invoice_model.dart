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
  final String? paymentMethod;
  final String paymentStatus;

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
    required this.paymentMethod,
    required this.paymentStatus,
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
      paymentMethod: json['paymentMethod']?.toString(),
      paymentStatus: json['paymentStatus']?.toString() ?? 'UNPAID',
    );
  }

  String get paymentMethodLabel {
    switch (paymentMethod) {
      case 'CASH':
        return 'Tiền mặt';
      case 'BANK_TRANSFER':
        return 'Chuyển khoản QR';
      default:
        return 'Chưa chọn';
    }
  }
}
