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
  final String appointmentStatus; // 'PENDING', 'CONFIRMED', 'RESCHEDULED'
  final DateTime? proposedTime;
  final String rescheduleNote;
  final String rescheduleRejectNote;
  final String customerNote;
  final DateTime? cancelledAt;
  final String cancellationReason;
  final DateTime? onTheWayAt; // thời điểm thợ bấm "Đang trên đường"
  final int quotesCount; // số lượng báo giá của thợ gửi đến
  final bool hasQuoted; // thợ đang xem đã tự gửi báo giá cho phiếu này chưa
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
    this.appointmentStatus = 'PENDING',
    this.proposedTime,
    this.rescheduleNote = '',
    this.rescheduleRejectNote = '',
    this.customerNote = '',
    this.cancelledAt,
    this.cancellationReason = '',
    this.onTheWayAt,
    this.quotesCount = 0,
    this.hasQuoted = false,
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
          ? DateTime.tryParse(json['preferredTime'])?.toLocal()
          : null,
      appointmentStatus: json['appointmentStatus'] ?? 'PENDING',
      proposedTime: json['proposedTime'] != null
          ? DateTime.tryParse(json['proposedTime'])?.toLocal()
          : null,
      rescheduleNote: json['rescheduleNote'] ?? '',
      rescheduleRejectNote: json['rescheduleRejectNote'] ?? '',
      customerNote: json['customerNote'] ?? '',
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.tryParse(json['cancelledAt'])?.toLocal()
          : null,
      cancellationReason: json['cancellationReason'] ?? '',
      onTheWayAt: json['onTheWayAt'] != null
          ? DateTime.tryParse(json['onTheWayAt'])?.toLocal()
          : null,
      quotesCount: json['quotesCount'] is int
          ? json['quotesCount']
          : (json['quotesCount'] is num
              ? (json['quotesCount'] as num).toInt()
              : (json['quotationCount'] is num
                  ? (json['quotationCount'] as num).toInt()
                  : 0)),
      hasQuoted: json['hasQuoted'] == true,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '')?.toLocal() ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '')?.toLocal() ??
          DateTime.now(),
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
      if (preferredTime != null)
        'preferredTime': preferredTime!.toUtc().toIso8601String(),
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
      case 'ON_THE_WAY':
        return 'Đang trên đường';
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

  /// Hiển thị trạng thái lịch hẹn
  String get appointmentStatusDisplay {
    switch (appointmentStatus) {
      case 'CONFIRMED':
        return 'Đã xác nhận lịch hẹn';
      case 'RESCHEDULED':
        return 'Đang chờ đổi lịch';
      default:
        return 'Chờ thợ xác nhận lịch';
    }
  }

  /// Sentinel để phân biệt "không truyền" với "truyền null" trong copyWith
  static const Object _unset = Object();

  RepairRequestModel copyWith({
    String? status,
    String? appointmentStatus,
    Object? preferredTime = _unset,
    Object? proposedTime = _unset,
    Object? rescheduleNote = _unset,
    Object? rescheduleRejectNote = _unset,
    Object? onTheWayAt = _unset,
    int? quotesCount,
    bool? hasQuoted,
  }) {
    return RepairRequestModel(
      id: id,
      customerId: customerId,
      serviceCategoryId: serviceCategoryId,
      serviceCategory: serviceCategory,
      title: title,
      description: description,
      images: images,
      urgency: urgency,
      location: location,
      status: status ?? this.status,
      contactPhone: contactPhone,
      preferredTime: identical(preferredTime, _unset)
          ? this.preferredTime
          : preferredTime as DateTime?,
      appointmentStatus: appointmentStatus ?? this.appointmentStatus,
      proposedTime: identical(proposedTime, _unset)
          ? this.proposedTime
          : proposedTime as DateTime?,
      rescheduleNote: identical(rescheduleNote, _unset)
          ? this.rescheduleNote
          : (rescheduleNote as String?) ?? '',
      rescheduleRejectNote: identical(rescheduleRejectNote, _unset)
          ? this.rescheduleRejectNote
          : (rescheduleRejectNote as String?) ?? '',
      customerNote: customerNote,
      cancelledAt: cancelledAt,
      cancellationReason: cancellationReason,
      onTheWayAt: identical(onTheWayAt, _unset)
          ? this.onTheWayAt
          : onTheWayAt as DateTime?,
      quotesCount: quotesCount ?? this.quotesCount,
      hasQuoted: hasQuoted ?? this.hasQuoted,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
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
