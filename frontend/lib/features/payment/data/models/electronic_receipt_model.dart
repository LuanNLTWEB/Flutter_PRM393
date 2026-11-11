/// Author: Lam Hoang Phuc (CE191132)
/// Use Case: #UC-PAY-05
/// Description: Model dữ liệu biên nhận thanh toán kiêm phiếu bảo hành dịch vụ điện tử

class ElectronicReceiptModel {
  final String receiptCode;
  final String warrantyCode;
  final DateTime issuedAt;
  final String requestId;
  final String serviceTitle;
  final String serviceCategoryName;
  final ReceiptCustomerInfo customer;
  final ReceiptTechnicianInfo technician;
  final ReceiptFinancialInfo financial;
  final ReceiptWarrantyInfo warranty;
  final List<String> completionImages;
  final List<String> partsInvoiceImages;

  const ElectronicReceiptModel({
    required this.receiptCode,
    required this.warrantyCode,
    required this.issuedAt,
    required this.requestId,
    required this.serviceTitle,
    required this.serviceCategoryName,
    required this.customer,
    required this.technician,
    required this.financial,
    required this.warranty,
    required this.completionImages,
    required this.partsInvoiceImages,
  });

  factory ElectronicReceiptModel.fromJson(Map<String, dynamic> json) {
    return ElectronicReceiptModel(
      receiptCode: json['receiptCode']?.toString() ?? '',
      warrantyCode: json['warrantyCode']?.toString() ?? '',
      issuedAt: DateTime.tryParse(json['issuedAt']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      requestId: json['requestId']?.toString() ?? '',
      serviceTitle: json['serviceTitle']?.toString() ?? '',
      serviceCategoryName: json['serviceCategoryName']?.toString() ?? 'Dịch vụ sửa chữa',
      customer: ReceiptCustomerInfo.fromJson(
        json['customer'] as Map<String, dynamic>? ?? {},
      ),
      technician: ReceiptTechnicianInfo.fromJson(
        json['technician'] as Map<String, dynamic>? ?? {},
      ),
      financial: ReceiptFinancialInfo.fromJson(
        json['financial'] as Map<String, dynamic>? ?? {},
      ),
      warranty: ReceiptWarrantyInfo.fromJson(
        json['warranty'] as Map<String, dynamic>? ?? {},
      ),
      completionImages: (json['completionImages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      partsInvoiceImages: (json['partsInvoiceImages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

class ReceiptCustomerInfo {
  final String fullName;
  final String phoneNumber;
  final String email;
  final String address;

  const ReceiptCustomerInfo({
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.address,
  });

  factory ReceiptCustomerInfo.fromJson(Map<String, dynamic> json) {
    return ReceiptCustomerInfo(
      fullName: json['fullName']?.toString() ?? 'Khách hàng',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
    );
  }
}

class ReceiptTechnicianInfo {
  final String fullName;
  final String phoneNumber;
  final String avatar;

  const ReceiptTechnicianInfo({
    required this.fullName,
    required this.phoneNumber,
    required this.avatar,
  });

  factory ReceiptTechnicianInfo.fromJson(Map<String, dynamic> json) {
    return ReceiptTechnicianInfo(
      fullName: json['fullName']?.toString() ?? 'Thợ sửa chữa',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
    );
  }
}

class ReceiptFinancialInfo {
  final int labourCost;
  final int partsCost;
  final int totalAmount;
  final String currency;
  final String paymentMethod;
  final String paymentStatus;
  final DateTime? paidAt;

  const ReceiptFinancialInfo({
    required this.labourCost,
    required this.partsCost,
    required this.totalAmount,
    required this.currency,
    required this.paymentMethod,
    required this.paymentStatus,
    this.paidAt,
  });

  bool get isPaid => paymentStatus.toUpperCase() == 'PAID';

  factory ReceiptFinancialInfo.fromJson(Map<String, dynamic> json) {
    return ReceiptFinancialInfo(
      labourCost: (json['labourCost'] as num?)?.round() ?? 0,
      partsCost: (json['partsCost'] as num?)?.round() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.round() ?? 0,
      currency: json['currency']?.toString() ?? 'VND',
      paymentMethod: json['paymentMethod']?.toString() ?? 'CASH',
      paymentStatus: json['paymentStatus']?.toString() ?? 'UNPAID',
      paidAt: json['paidAt'] != null
          ? DateTime.tryParse(json['paidAt'].toString())?.toLocal()
          : null,
    );
  }
}

class ReceiptWarrantyInfo {
  final int durationDays;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final String statusText;
  final List<String> terms;

  const ReceiptWarrantyInfo({
    required this.durationDays,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.statusText,
    required this.terms,
  });

  bool get isActive => status.toUpperCase() == 'ACTIVE';

  factory ReceiptWarrantyInfo.fromJson(Map<String, dynamic> json) {
    return ReceiptWarrantyInfo(
      durationDays: (json['durationDays'] as num?)?.round() ?? 30,
      startDate: DateTime.tryParse(json['startDate']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      endDate: DateTime.tryParse(json['endDate']?.toString() ?? '')?.toLocal() ??
          DateTime.now().add(const Duration(days: 30)),
      status: json['status']?.toString() ?? 'ACTIVE',
      statusText: json['statusText']?.toString() ?? 'Còn hiệu lực bảo hành',
      terms: (json['terms'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}
