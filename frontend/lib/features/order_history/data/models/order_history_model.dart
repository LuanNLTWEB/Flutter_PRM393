import '../../../repair_request/data/models/repair_request_model.dart';

class OrderHistoryModel {
  final String id;
  final String title;
  final String description;
  final String urgency;
  final String status;
  final bool isReviewed;
  final String serviceCategoryName;
  final String serviceCategoryIcon;
  final String? assignedTechnicianId;
  final String? assignedTechnicianName;
  final double? assignedTechnicianRating;
  final DateTime? createdAt;
  final String locationAddress;
  final DateTime? preferredTime;
  final String appointmentStatus; // PENDING, CONFIRMED, RESCHEDULED
  final DateTime? proposedTime;
  final String rescheduleNote;
  final String rescheduleRejectNote;

  /// Chi phí phát sinh Thợ khai báo (UC-WRK-05 / UC-WRK-06)
  final List<AdditionalCostModel> additionalCosts;

  OrderHistoryModel({
    required this.id,
    required this.title,
    required this.description,
    required this.urgency,
    required this.status,
    required this.isReviewed,
    required this.serviceCategoryName,
    required this.serviceCategoryIcon,
    this.assignedTechnicianId,
    this.assignedTechnicianName,
    this.assignedTechnicianRating,
    this.createdAt,
    required this.locationAddress,
    this.preferredTime,
    this.appointmentStatus = 'PENDING',
    this.proposedTime,
    this.rescheduleNote = '',
    this.rescheduleRejectNote = '',
    this.additionalCosts = const [],
  });

  factory OrderHistoryModel.fromJson(Map<String, dynamic> json) {
    String categoryName = 'Dịch vụ sửa chữa';
    String categoryIcon = '';
    if (json['serviceCategoryId'] is Map<String, dynamic>) {
      final cat = json['serviceCategoryId'] as Map<String, dynamic>;
      categoryName = cat['name'] ?? 'Dịch vụ sửa chữa';
      categoryIcon = cat['icon'] ?? '';
    }

    String? techId;
    String? techName;
    double? techRating;
    if (json['assignedTechnicianId'] is Map<String, dynamic>) {
      final tech = json['assignedTechnicianId'] as Map<String, dynamic>;
      techId = tech['_id']?.toString();
      techName = tech['fullName']?.toString();
      techRating = (tech['rating'] as num?)?.toDouble();
    } else if (json['assignedTechnicianId'] != null) {
      techId = json['assignedTechnicianId'].toString();
    }

    String address = 'Chưa cập nhật địa chỉ';
    if (json['location'] is Map<String, dynamic>) {
      address = json['location']['address'] ?? 'Chưa cập nhật địa chỉ';
    }

    return OrderHistoryModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? 'Yêu cầu sửa chữa',
      description: json['description'] ?? '',
      urgency: (json['urgency'] ?? 'medium').toString().toLowerCase(),
      status: (json['status'] ?? 'OPEN').toString().toUpperCase(),
      isReviewed: json['isReviewed'] == true,
      serviceCategoryName: categoryName,
      serviceCategoryIcon: categoryIcon,
      assignedTechnicianId: techId,
      assignedTechnicianName: techName,
      assignedTechnicianRating: techRating,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())?.toLocal()
          : null,
      locationAddress: address,
      preferredTime: json['preferredTime'] != null
          ? DateTime.tryParse(json['preferredTime'].toString())?.toLocal()
          : null,
      appointmentStatus:
          (json['appointmentStatus'] ?? 'PENDING').toString().toUpperCase(),
      proposedTime: json['proposedTime'] != null
          ? DateTime.tryParse(json['proposedTime'].toString())?.toLocal()
          : null,
      rescheduleNote: (json['rescheduleNote'] ?? '').toString(),
      rescheduleRejectNote: (json['rescheduleRejectNote'] ?? '').toString(),
      additionalCosts: (json['additionalCosts'] is List)
          ? (json['additionalCosts'] as List)
              .whereType<Map<String, dynamic>>()
              .map(AdditionalCostModel.fromJson)
              .toList()
          : const [],
    );
  }

  String get statusDisplay {
    switch (status) {
      case 'OPEN':
        return 'Chờ báo giá';
      case 'QUOTED':
        return 'Đã có báo giá';
      case 'ACCEPTED':
        return 'Đã chọn thợ';
      case 'ON_THE_WAY':
        return 'Thợ đang trên đường đến';
      case 'ARRIVED':
        return 'Thợ đã có mặt';
      case 'IN_PROGRESS':
        return 'Đang sửa chữa';
      case 'COMPLETED':
        return 'Đã hoàn tất';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  bool get isCompleted => status == 'COMPLETED';

  String get urgencyDisplay {
    switch (urgency) {
      case 'high':
        return 'Khẩn cấp';
      case 'medium':
        return 'Trung bình';
      case 'low':
        return 'Thấp';
      default:
        return 'Trung bình';
    }
  }
}
