import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/quotations/presentation/widgets/quotation_format.dart';

void main() {
  group('formatVnd', () {
    test('dùng dấu chấm phân cách nhóm 3 chữ số kiểu Việt Nam', () {
      expect(formatVnd(999), '999₫');
      expect(formatVnd(1000), '1.000₫');
      expect(formatVnd(150000), '150.000₫');
      expect(formatVnd(1500000), '1.500.000₫');
      expect(formatVnd(100000000), '100.000.000₫');
    });

    test('giữ nguyên số 0 và số chưa đủ 4 chữ số', () {
      expect(formatVnd(0), '0₫');
      expect(formatVnd(5), '5₫');
      expect(formatVnd(99), '99₫');
      expect(formatVnd(100), '100₫');
    });

    test('làm tròn số thực trước khi chèn dấu chấm', () {
      expect(formatVnd(1500.4), '1.500₫');
      expect(formatVnd(1500.5), '1.501₫');
      expect(formatVnd(1000.49), '1.000₫');
    });

    test('giữ dấu âm ở đầu', () {
      expect(formatVnd(-250000), '-250.000₫');
      expect(formatVnd(-999), '-999₫');
    });

    test('chấp nhận cả double', () {
      expect(formatVnd(1234567.89), '1.234.568₫');
    });

    test('không dùng NumberFormat nên không phụ thuộc locale', () {
      // Nếu ai đó đổi lại về NumberFormat('#,##0', 'vi_VN') mà quên bật
      // flutter_localizations, các assertion trên sẽ fail vì ra "1,500,000".
      expect(formatVnd(1500000), isNot(contains(',')));
    });
  });

  group('formatThousands', () {
    test('chèn dấu chấm mà không thêm ký hiệu đồng', () {
      expect(formatThousands(0), '0');
      expect(formatThousands(150000), '150.000');
      expect(formatThousands(100000000), '100.000.000');
      expect(formatThousands(-250000), '-250.000');
    });
  });

  group('parseVndInput', () {
    test('đọc được số đã có dấu chấm phân cách', () {
      expect(parseVndInput('1.500.000'), 1500000);
      expect(parseVndInput('150.000'), 150000);
      expect(parseVndInput('999'), 999);
      expect(parseVndInput('0'), 0);
    });

    test('trả về null khi rỗng hoặc chỉ có ký tự phân cách', () {
      expect(parseVndInput(''), isNull);
      expect(parseVndInput('...'), isNull);
      expect(parseVndInput(null), isNull);
    });
  });

  group('ThousandsSeparatorFormatter', () {
    const formatter = ThousandsSeparatorFormatter();

    TextEditingValue type(String text) {
      return formatter.formatEditUpdate(
        const TextEditingValue(),
        TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        ),
      );
    }

    test('tự chèn dấu chấm khi người dùng gõ', () {
      expect(type('1').text, '1');
      expect(type('15').text, '15');
      expect(type('150').text, '150');
      expect(type('1500').text, '1.500');
      expect(type('1500000').text, '1.500.000');
    });

    test('bỏ ký tự không phải số và chuẩn hoá lại', () {
      expect(type('abc').text, '');
      expect(type('1a5b0').text, '150');
      expect(type('1.500.000').text, '1.500.000');
    });

    test('xóa hết số thì trả về chuỗi rỗng', () {
      expect(type('').text, '');
      expect(type('...').text, '');
    });

    test('giữ con trỏ đúng chỗ khi gõ ở giữa', () {
      final result = type('1500');
      expect(result.text, '1.500');
      expect(result.selection.baseOffset, 5);
    });
  });
}