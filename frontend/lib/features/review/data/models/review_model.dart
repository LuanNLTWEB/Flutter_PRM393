class ReviewModel {
  final String id;
  final String customerId;
  final String customerName;
  final String technicianId;
  final String? bookingId;
  final double rating;
  final List<String> tags;
  final String comment;
  final ReviewReplyModel? reply;
  final DateTime? createdAt;

  ReviewModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.technicianId,
    this.bookingId,
    required this.rating,
    required this.tags,
    required this.comment,
    this.reply,
    this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    String customerName = 'Khách hàng';
    String customerId = '';

    if (json['customerId'] is Map<String, dynamic>) {
      final customerMap = json['customerId'] as Map<String, dynamic>;
      customerId = customerMap['_id'] ?? '';
      customerName = customerMap['fullName'] ?? 'Khách hàng';
    } else if (json['customerId'] != null) {
      customerId = json['customerId'].toString();
    }

    return ReviewModel(
      id: json['_id'] ?? json['id'] ?? '',
      customerId: customerId,
      customerName: customerName,
      technicianId: json['technicianId'] is Map
          ? (json['technicianId']['_id'] ?? '')
          : (json['technicianId'] ?? '').toString(),
      bookingId: json['bookingId']?.toString(),
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      tags: json['tags'] != null
          ? List<String>.from((json['tags'] as List).map((e) => e.toString()))
          : [],
      comment: json['comment'] ?? '',
      reply: json['reply'] != null && json['reply']['comment'] != null
          ? ReviewReplyModel.fromJson(json['reply'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'technicianId': technicianId,
      if (bookingId != null) 'bookingId': bookingId,
      'rating': rating,
      'tags': tags,
      'comment': comment,
    };
  }
}

class ReviewReplyModel {
  final String comment;
  final DateTime? repliedAt;

  ReviewReplyModel({
    required this.comment,
    this.repliedAt,
  });

  factory ReviewReplyModel.fromJson(Map<String, dynamic> json) {
    return ReviewReplyModel(
      comment: json['comment'] ?? '',
      repliedAt: json['repliedAt'] != null
          ? DateTime.tryParse(json['repliedAt'].toString())
          : null,
    );
  }
}

class ReviewSummaryModel {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> starBreakdown;

  ReviewSummaryModel({
    required this.averageRating,
    required this.totalReviews,
    required this.starBreakdown,
  });

  factory ReviewSummaryModel.fromJson(Map<String, dynamic> json) {
    final Map<int, int> breakdown = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    if (json['starBreakdown'] is Map) {
      final map = json['starBreakdown'] as Map;
      map.forEach((key, value) {
        final starKey = int.tryParse(key.toString());
        if (starKey != null && breakdown.containsKey(starKey)) {
          breakdown[starKey] = (value as num?)?.toInt() ?? 0;
        }
      });
    }

    return ReviewSummaryModel(
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 5.0,
      totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
      starBreakdown: breakdown,
    );
  }
}
