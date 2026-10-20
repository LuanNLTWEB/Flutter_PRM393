import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Ký hiệu đồng Việt Nam (U+20AB)
const String vndSymbol = '₫';

final RegExp _nonDigits = RegExp(r'[^0-9]');

/// Chèn dấu chấm phân cách nhóm 3 chữ số kiểu Việt Nam: 1500000 -> "1.500.000"
String formatThousands(num value) {
  final isNegative = value < 0;
  final digits = value.abs().round().toString();
  final buffer = StringBuffer(isNegative ? '-' : '');

  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(digits[i]);
  }

  return buffer.toString();
}

/// Định dạng tiền VND theo cách viết của Việt Nam: 1.500.000₫
///
/// Tự chèn dấu chấm thay vì dùng [NumberFormat], vì dự án chưa bật
/// `flutter_localizations` nên locale `vi_VN` của package `intl` sẽ âm thầm rơi về
/// `en_US` và hiển thị sai (1,500,000 thay vì 1.500.000).
String formatVnd(num value) => '${formatThousands(value)}$vndSymbol';

/// Bỏ dấu phân cách để parse lại được số tiền người dùng đã gõ: "1.500.000" -> 1500000
double? parseVndInput(String? text) {
  if (text == null) return null;
  return double.tryParse(text.replaceAll(_nonDigits, ''));
}

/// Tự động thêm dấu chấm phân cách nhóm khi người dùng gõ tiền trong ô nhập.
class ThousandsSeparatorFormatter extends TextInputFormatter {
  const ThousandsSeparatorFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(_nonDigits, '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final formatted = formatThousands(int.parse(digits));

    // Giữ con trỏ đúng chỗ người dùng đang gõ, đếm theo số chữ số chứ không
    // theo số ký tự (vì dấu chấm làm độ dài chuỗi thay đổi).
    final caret = newValue.selection.baseOffset.clamp(0, newValue.text.length);
    final digitsBeforeCaret =
        newValue.text.substring(0, caret).replaceAll(_nonDigits, '').length;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: _offsetOfDigit(formatted, digitsBeforeCaret),
      ),
    );
  }

  /// Vị trí con trỏ sau khi định dạng, tương ứng với [digitIndex] chữ số thứ.
  int _offsetOfDigit(String formatted, int digitIndex) {
    if (digitIndex <= 0) return 0;
    var seen = 0;
    for (var i = 0; i < formatted.length; i++) {
      if (formatted[i] == '.') continue;
      seen++;
      if (seen == digitIndex) return i + 1;
    }
    return formatted.length;
  }
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