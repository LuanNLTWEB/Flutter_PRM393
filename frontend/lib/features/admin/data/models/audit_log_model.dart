import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Model biểu diễn một bản ghi Nhật ký hoạt động (Audit Log)
/// Dành cho người mới học Flutter: cấu trúc tường minh, dễ đọc và dễ bảo trì
class AuditLogModel {
  final String id;
  final String actorId;
  final String actorName;
  final String actorEmail;
  final String actorRole; // 'admin' hoặc 'staff'
  final String action; // Mã hành động (vd: KYC_APPROVE, USER_LOCK...)
  final String actionTitle; // Tiêu đề tiếng Việt hiển thị
  final String targetType; // 'Technician', 'User', 'Complaint', 'ServiceCategory', 'Other'
  final String targetId;
  final String targetName; // Tên đối tượng bị tác động
  final String details; // Chi tiết, lý do hoặc ghi chú biên bản
  final DateTime createdAt; // Thời gian thực hiện thao tác

  const AuditLogModel({
    required this.id,
    required this.actorId,
    required this.actorName,
    required this.actorEmail,
    required this.actorRole,
    required this.action,
    required this.actionTitle,
    required this.targetType,
    required this.targetId,
    required this.targetName,
    required this.details,
    required this.createdAt,
  });

  /// Chuyển đổi từ dữ liệu JSON của Backend sang Object Dart
  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      actorId: json['actorId']?.toString() ?? '',
      actorName: json['actorName']?.toString() ?? 'Quản trị viên',
      actorEmail: json['actorEmail']?.toString() ?? '',
      actorRole: json['actorRole']?.toString() ?? 'staff',
      action: json['action']?.toString() ?? '',
      actionTitle: json['actionTitle']?.toString() ?? 'Thao tác hệ thống',
      targetType: json['targetType']?.toString() ?? 'Other',
      targetId: json['targetId']?.toString() ?? '',
      targetName: json['targetName']?.toString() ?? '',
      details: json['details']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Chuyển đổi Object sang JSON nếu cần gửi lên server
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'actorId': actorId,
      'actorName': actorName,
      'actorEmail': actorEmail,
      'actorRole': actorRole,
      'action': action,
      'actionTitle': actionTitle,
      'targetType': targetType,
      'targetId': targetId,
      'targetName': targetName,
      'details': details,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // ==========================================================
  // CÁC HÀM TIỆN ÍCH HỖ TRỢ HIỂN THỊ GIAO DIỆN ĐẸP MẮT
  // ==========================================================

  /// Kiểm tra người thao tác có phải là Admin không
  bool get isActorAdmin => actorRole.toLowerCase() == 'admin';

  /// Chuỗi hiển thị vai trò người thao tác
  String get roleDisplay => isActorAdmin ? 'Admin' : 'Staff';

  /// Màu sắc huy hiệu vai trò
  Color get roleBadgeColor => isActorAdmin ? Colors.deepPurple : Colors.teal;

  /// Ký tự đại diện cho Avatar của người thao tác (vd: Nguyễn Văn A -> NA)
  String get actorInitials {
    final trimmed = actorName.trim();
    if (trimmed.isEmpty) return 'U';
    final parts = trimmed.split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  /// Định dạng ngày giờ chuẩn Việt Nam: 14:30 - 02/11/2026
  String get formattedDateTime {
    return DateFormat('HH:mm - dd/MM/yyyy').format(createdAt);
  }

  /// Định dạng giờ phút: 14:30
  String get formattedTime {
    return DateFormat('HH:mm').format(createdAt);
  }

  /// Định dạng ngày tháng: 02/11/2026
  String get formattedDate {
    return DateFormat('dd/MM/yyyy').format(createdAt);
  }

  /// Tính khoảng thời gian tương đối ("5 phút trước", "2 giờ trước"...)
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return formattedDate;
  }

  /// Màu sắc tương ứng theo hành động kiểm duyệt
  Color get actionColor {
    // 1. Phê duyệt hồ sơ thợ (KYC)
    if (action == 'KYC_APPROVE') return Colors.green.shade700;
    // 2. Từ chối hồ sơ thợ (KYC)
    if (action == 'KYC_REJECT') return Colors.red.shade700;

    // 3. Khóa tài khoản
    if (action == 'USER_LOCK') return Colors.red.shade800;
    // 4. Mở khóa tài khoản
    if (action == 'USER_UNLOCK') return Colors.green.shade600;
    // 5. Cập nhật quyền / Tạo staff
    if (action == 'ROLE_UPDATE' || action == 'STAFF_CREATE') {
      return Colors.deepPurple.shade600;
    }

    // 6. Xử lý khiếu nại
    if (action.startsWith('COMPLAINT_')) {
      if (action.contains('RESOLVED')) return Colors.teal.shade700;
      if (action.contains('REJECTED')) return Colors.orange.shade800;
      return Colors.blue.shade700;
    }

    // 7. Quản lý danh mục dịch vụ
    if (action.startsWith('CATEGORY_')) {
      if (action.contains('DELETE') || action.contains('DEACTIVATE')) {
        return Colors.brown.shade600;
      }
      return Colors.blue.shade800;
    }

    return Colors.grey.shade700;
  }

  /// Icon tương ứng theo hành động kiểm duyệt
  IconData get actionIcon {
    if (action == 'KYC_APPROVE') return Icons.verified_user_rounded;
    if (action == 'KYC_REJECT') return Icons.gpp_bad_rounded;
    if (action == 'USER_LOCK') return Icons.lock_outline_rounded;
    if (action == 'USER_UNLOCK') return Icons.lock_open_rounded;
    if (action == 'ROLE_UPDATE') return Icons.manage_accounts_rounded;
    if (action == 'STAFF_CREATE') return Icons.person_add_alt_1_rounded;

    if (action.startsWith('COMPLAINT_')) {
      if (action.contains('RESOLVED')) return Icons.task_alt_rounded;
      if (action.contains('REJECTED')) return Icons.cancel_outlined;
      return Icons.support_agent_rounded;
    }

    if (action.startsWith('CATEGORY_')) {
      if (action.contains('DELETE')) return Icons.delete_outline_rounded;
      if (action.contains('ACTIVATE')) return Icons.visibility_rounded;
      if (action.contains('DEACTIVATE')) return Icons.visibility_off_rounded;
      return Icons.category_rounded;
    }

    return Icons.history_rounded;
  }
}
