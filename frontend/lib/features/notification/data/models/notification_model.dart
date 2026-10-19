import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    this.type = 'SYSTEM',
    this.data = const {},
    this.isRead = false,
    this.readAt,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'SYSTEM',
      data: json['data'] is Map<String, dynamic>
          ? json['data'] as Map<String, dynamic>
          : {},
      isRead: json['isRead'] == true,
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'message': message,
      'type': type,
      'data': data,
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(createdAt);
    }
  }

  String get typeDisplay {
    switch (type.toUpperCase()) {
      case 'ORDER_STATUS':
        return 'Trạng thái đơn';
      case 'QUOTATION':
        return 'Báo giá';
      case 'APPOINTMENT':
        return 'Lịch hẹn';
      case 'KYC':
        return 'Hồ sơ xét duyệt';
      case 'SYSTEM':
      default:
        return 'Hệ thống';
    }
  }

  IconData get iconData {
    switch (type.toUpperCase()) {
      case 'ORDER_STATUS':
        return Icons.local_shipping_outlined;
      case 'QUOTATION':
        return Icons.request_quote_outlined;
      case 'APPOINTMENT':
        return Icons.calendar_today_outlined;
      case 'KYC':
        return Icons.verified_user_outlined;
      case 'SYSTEM':
      default:
        return Icons.notifications_outlined;
    }
  }

  Color get typeColor {
    switch (type.toUpperCase()) {
      case 'ORDER_STATUS':
        return Colors.blue;
      case 'QUOTATION':
        return Colors.green;
      case 'APPOINTMENT':
        return Colors.purple;
      case 'KYC':
        return Colors.amber.shade800;
      case 'SYSTEM':
      default:
        return Colors.teal;
    }
  }
}
