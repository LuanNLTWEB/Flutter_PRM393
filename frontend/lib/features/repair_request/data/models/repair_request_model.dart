import 'service_category_model.dart';

/// Model dữ liệu cho yêu cầu sửa chữa
class RepairRequestModel {
  final String id;
  final String customerId;
  final String serviceCategoryId;
  final ServiceCategoryModel? serviceCategory;
  final String title;
  final String description;
  final List<String> images;
  final String urgency; // 'low', 'medium', 'high', 'emergency'
  final RepairLocationModel location;
  final String status; // 'OPEN', 'QUOTED', 'ACCEPTED', 'CANCELLED'
  final String contactPhone;
  final DateTime? preferredTime;
  final String customerNote;
  final DateTime? cancelledAt;
  final String cancellationReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RepairRequestModel({
    required this.id,
    required this.customerId,
    required this.serviceCategoryId,
    this.serviceCategory,
    required this.title,
    required this.description,
    this.images = const [],
    this.urgency = 'medium',
    required this.location,
    this.status = 'OPEN',
    required this.contactPhone,
    this.preferredTime,
    this.customerNote = '',
    this.cancelledAt,
    this.cancellationReason = '',
    required this.createdAt,
    required this.updatedAt,
  });

  factory RepairRequestModel.fromJson(Map<String, dynamic> json) {
    // Trích xuất customerId
    final rawCustomer = json['customerId'] ?? json['customer'];
    final custId = (rawCustomer is Map)
        ? (rawCustomer['_id'] ?? '')
        : (rawCustomer?.toString() ?? '');

    // Trích xuất serviceCategoryId & model
    final rawCat = json['serviceCategoryId'] ?? json['serviceCategory'];
    String catId = '';
    ServiceCategoryModel? catModel;
    if (rawCat is Map<String, dynamic>) {
      catId = rawCat['_id'] ?? '';
      catModel = ServiceCategoryModel.fromJson(rawCat);
    } else if (rawCat is String) {
      catId = rawCat;
    }

    // Trích xuất title & description
    final title = json['title'] ?? 'Yêu cầu sửa chữa';
    final desc = json['description'] ?? json['problemDescription'] ?? '';

    // Trích xuất urgency
    String urgency = json['urgency'] ?? 'medium';
    if (json['urgencyLevel'] != null) {
      final lvl = json['urgencyLevel'].toString().toLowerCase();
      if (lvl == 'normal') {
        urgency = 'medium';
      } else if (lvl == 'urgent') {
        urgency = 'high';
      } else if (['low', 'medium', 'high', 'emergency'].contains(lvl)) {
        urgency = lvl;
      }
    }

    // Trích xuất location { address, latitude, longitude }
    RepairLocationModel loc;
    if (json['location'] is Map<String, dynamic>) {
      loc = RepairLocationModel.fromJson(json['location'] as Map<String, dynamic>);
    } else if (json['address'] is Map<String, dynamic>) {
      final addrMap = json['address'] as Map<String, dynamic>;
      final fullAddr = '${addrMap['street'] ?? ''}, ${addrMap['district'] ?? ''}, ${addrMap['city'] ?? ''}'
          .replaceAll(RegExp(r'^,\s*|,\s*$'), '');
      loc = RepairLocationModel(address: fullAddr);
    } else if (json['address'] is String) {
      loc = RepairLocationModel(address: json['address']);
    } else {
      loc = const RepairLocationModel(address: '');
    }

    // Trích xuất status (OPEN, QUOTED, ACCEPTED, CANCELLED)
    String status = json['status'] ?? 'OPEN';
    if (status == 'pending') {
      status = 'OPEN';
    } else if (status == 'cancelled') {
      status = 'CANCELLED';
    }

    return RepairRequestModel(
      id: json['_id'] ?? json['id'] ?? '',
      customerId: custId,
      serviceCategoryId: catId,
      serviceCategory: catModel,
      title: title,
      description: desc,
      images: json['images'] != null ? List<String>.from(json['images']) : const [],
      urgency: urgency,
      location: loc,
      status: status,
      contactPhone: json['contactPhone'] ?? '',
      preferredTime: json['preferredTime'] != null
          ? DateTime.tryParse(json['preferredTime'])
          : null,
      customerNote: json['customerNote'] ?? '',
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.tryParse(json['cancelledAt'])
          : null,
      cancellationReason: json['cancellationReason'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serviceCategoryId': serviceCategoryId,
      'title': title,
      'description': description,
      'images': images,
      'urgency': urgency,
      'location': location.toJson(),
      'contactPhone': contactPhone,
      if (preferredTime != null) 'preferredTime': preferredTime!.toIso8601String(),
      'customerNote': customerNote,
    };
  }

  /// Backward-compatible getters
  String get problemDescription => description;
  String get addressString => location.address;
  String get urgencyLevel => urgency;

  /// Hiển thị trạng thái thân thiện
  String get statusDisplay {
    switch (status) {
      case 'OPEN':
        return 'Chờ báo giá';
      case 'QUOTED':
        return 'Đã có báo giá';
      case 'ACCEPTED':
        return 'Đã chốt thợ';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  /// Hiển thị mức độ khẩn cấp
  String get urgencyDisplay {
    switch (urgency) {
      case 'low':
        return 'Thấp';
      case 'medium':
        return 'Bình thường';
      case 'high':
        return 'Khẩn cấp';
      case 'emergency':
        return 'Cực kỳ khẩn cấp';
      default:
        return urgency;
    }
  }
}

/// Thông tin địa chỉ và tọa độ sửa chữa
class RepairLocationModel {
  final String address;
  final double? latitude;
  final double? longitude;

  const RepairLocationModel({
    required this.address,
    this.latitude,
    this.longitude,
  });

  factory RepairLocationModel.fromJson(Map<String, dynamic> json) {
    return RepairLocationModel(
      address: json['address'] ?? '',
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }
}
