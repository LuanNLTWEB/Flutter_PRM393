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
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      locationAddress: address,
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
}
