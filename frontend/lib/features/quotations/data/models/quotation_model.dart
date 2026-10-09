/// Model dữ liệu báo giá của Thợ gửi cho Khách hàng
class QuotationModel {
  final String id;
  final String requestId;
  final String technicianId;
  final double labourCost;
  final double partsCost;
  final double total;
  final String note;
  final String status; // SENT, ACCEPTED, REJECTED, RETRACTED
  final DateTime createdAt;
  final DateTime? resolvedAt;

  // Thông tin công khai của Thợ (populate từ backend)
  final String technicianName;
  final String technicianAvatar;
  final double rating;
  final int reviewCount;
  final int completedJobsCount;
  final bool technicianIsAvailable;
  final List<String> skills;

  const QuotationModel({
    required this.id,
    required this.requestId,
    required this.technicianId,
    required this.labourCost,
    required this.partsCost,
    required this.total,
    this.note = '',
    this.status = 'SENT',
    required this.createdAt,
    this.resolvedAt,
    this.technicianName = '',
    this.technicianAvatar = '',
    this.rating = 5.0,
    this.reviewCount = 0,
    this.completedJobsCount = 0,
    this.technicianIsAvailable = false,
    this.skills = const [],
  });

  factory QuotationModel.fromJson(Map<String, dynamic> json) {
    // technicianId có thể là chuỗi hoặc object đã populate
    String techId = '';
    String techName = '';
    String techAvatar = '';
    double rating = 5.0;
    int reviewCount = 0;
    int completedJobs = 0;
    bool isAvailable = false;
    List<String> skills = const [];

    final rawTech = json['technicianId'];
    if (rawTech is Map<String, dynamic>) {
      techId = rawTech['_id']?.toString() ?? '';
      techName = rawTech['fullName']?.toString() ?? '';
      techAvatar = rawTech['avatar']?.toString() ?? '';
      final profile = rawTech['technicianProfile'];
      if (profile is Map<String, dynamic>) {
        rating = (profile['rating'] as num?)?.toDouble() ?? 5.0;
        reviewCount = (profile['reviewCount'] as num?)?.toInt() ?? 0;
        completedJobs = (profile['completedJobsCount'] as num?)?.toInt() ?? 0;
        isAvailable = profile['isAvailable'] == true;
        skills = (profile['skills'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [];
      }
    } else if (rawTech != null) {
      techId = rawTech.toString();
    }

    // requestId có thể là chuỗi hoặc object đã populate
    final rawReq = json['requestId'];
    final reqId = (rawReq is Map)
        ? (rawReq['_id']?.toString() ?? '')
        : (rawReq?.toString() ?? '');

    return QuotationModel(
      id: json['_id'] ?? json['id'] ?? '',
      requestId: reqId,
      technicianId: techId,
      labourCost: (json['labourCost'] as num?)?.toDouble() ?? 0,
      partsCost: (json['partsCost'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      note: json['note']?.toString() ?? '',
      status: json['status']?.toString() ?? 'SENT',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.tryParse(json['resolvedAt'].toString())
          : null,
      technicianName: techName,
      technicianAvatar: techAvatar,
      rating: rating,
      reviewCount: reviewCount,
      completedJobsCount: completedJobs,
      technicianIsAvailable: isAvailable,
      skills: skills,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'requestId': requestId,
      'technicianId': technicianId,
      'labourCost': labourCost,
      'partsCost': partsCost,
      'total': total,
      'note': note,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      if (resolvedAt != null) 'resolvedAt': resolvedAt!.toIso8601String(),
    };
  }

  /// Trạng thái thân thiện theo yêu cầu của người dùng
  String get statusDisplay {
    switch (status) {
      case 'SENT':
        return 'Đã gửi';
      case 'ACCEPTED':
        return 'Đã chốt';
      case 'REJECTED':
        return 'Bị từ chối';
      case 'RETRACTED':
        return 'Đã thu hồi';
      default:
        return status;
    }
  }

  bool get canEdit => status == 'SENT';

  int get starRating => rating.round().clamp(1, 5);
}
