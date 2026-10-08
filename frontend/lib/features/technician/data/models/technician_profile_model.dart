class TechnicianProfileModel {
  final List<String> skills;
  final int experienceYears;
  final String bio;
  final String idCardFront;
  final String idCardBack;
  final List<String> certificates;
  final String approvalStatus; // pending, approved, rejected
  final String rejectionReason;
  final DateTime? approvedAt;
  final bool isAvailable;
  final int completedJobsCount;
  final double rating;
  final int reviewCount;

  const TechnicianProfileModel({
    this.skills = const [],
    this.experienceYears = 0,
    this.bio = '',
    this.idCardFront = '',
    this.idCardBack = '',
    this.certificates = const [],
    this.approvalStatus = 'pending',
    this.rejectionReason = '',
    this.approvedAt,
    this.isAvailable = false,
    this.completedJobsCount = 0,
    this.rating = 5.0,
    this.reviewCount = 0,
  });

  factory TechnicianProfileModel.fromJson(Map<String, dynamic> json) {
    return TechnicianProfileModel(
      skills: (json['skills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      experienceYears: (json['experienceYears'] as num?)?.toInt() ?? 0,
      bio: json['bio']?.toString() ?? '',
      idCardFront: json['idCardFront']?.toString() ?? '',
      idCardBack: json['idCardBack']?.toString() ?? '',
      certificates: (json['certificates'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      approvalStatus: json['approvalStatus']?.toString() ?? 'pending',
      rejectionReason: json['rejectionReason']?.toString() ?? '',
      approvedAt: json['approvedAt'] != null
          ? DateTime.tryParse(json['approvedAt'].toString())
          : null,
      isAvailable: json['isAvailable'] == true,
      completedJobsCount: (json['completedJobsCount'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skills': skills,
      'experienceYears': experienceYears,
      'bio': bio,
      'idCardFront': idCardFront,
      'idCardBack': idCardBack,
      'certificates': certificates,
      'approvalStatus': approvalStatus,
      'rejectionReason': rejectionReason,
      'approvedAt': approvedAt?.toIso8601String(),
      'isAvailable': isAvailable,
      'completedJobsCount': completedJobsCount,
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }

  String get approvalStatusDisplay {
    switch (approvalStatus.toLowerCase()) {
      case 'approved':
        return 'Đã phê duyệt';
      case 'rejected':
        return 'Bị từ chối';
      case 'pending':
      default:
        return 'Chờ phê duyệt';
    }
  }
}
