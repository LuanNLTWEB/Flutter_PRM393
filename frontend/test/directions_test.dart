import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/utils/directions.dart';

void main() {
  group('cleanAddressForMaps (UC-MAP-01)', () {
    test('cắt hậu tố liên hệ (Tên - SĐT) ở cuối địa chỉ', () {
      expect(
        cleanAddressForMaps(
          '12AB, Phường Ninh Xá (TP. Bắc Ninh), Tỉnh Bắc Ninh (Phúc An - 0912345678)',
        ),
        '12AB, Phường Ninh Xá (TP. Bắc Ninh), Tỉnh Bắc Ninh',
      );
    });

    test('cắt nhóm ngoặc cuối chỉ chứa số điện thoại', () {
      expect(
        cleanAddressForMaps('12 Lê Lợi, Quận 1 (0912345678)'),
        '12 Lê Lợi, Quận 1',
      );
    });

    test('giữ nguyên địa chỉ không có hậu tố liên hệ', () {
      const addr = '12AB, Phường Ninh Xá (TP. Bắc Ninh), Tỉnh Bắc Ninh';
      expect(cleanAddressForMaps(addr), addr);
    });

    test('không cắt ngoặc địa chỉ không chứa SĐT', () {
      const addr = 'Tòa nhà 123, Đường số 7 (Thành phố Thủ Đức)';
      expect(cleanAddressForMaps(addr), addr);
    });
  });
}
