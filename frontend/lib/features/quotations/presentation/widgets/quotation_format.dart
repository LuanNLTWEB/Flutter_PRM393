import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Định dạng tiền VND: 150.000 đ
String formatVnd(num value) {
  return '${NumberFormat('#,##0', 'vi_VN').format(value)} đ';
}

/// Hiển thị thời gian tương đối: "5 phút trước"
String timeAgo(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inSeconds < 60) return 'Vừa xong';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
  if (diff.inHours < 24) return '${diff.inHours} giờ trước';
  if (diff.inDays < 7) return '${diff.inDays} ngày trước';
  return DateFormat('dd/MM/yyyy').format(dateTime);
}

/// Màu cảnh báo theo mức độ khẩn cấp
Color urgencyColor(String urgency) {
  switch (urgency) {
    case 'emergency':
      return const Color(0xFFDC2626);
    case 'high':
      return const Color(0xFFF97316);
    case 'low':
      return const Color(0xFF16A34A);
    case 'medium':
    default:
      return const Color(0xFF2563EB);
  }
}

/// Text hiển thị mức độ khẩn cấp
String urgencyLabel(String urgency) {
  switch (urgency) {
    case 'emergency':
      return 'Cực kỳ khẩn cấp';
    case 'high':
      return 'Khẩn cấp';
    case 'low':
      return 'Thấp';
    case 'medium':
    default:
      return 'Bình thường';
  }
}
