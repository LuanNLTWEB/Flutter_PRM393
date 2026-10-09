import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/quotations/presentation/providers/quotation_provider.dart';
import 'package:frontend/features/quotations/presentation/screens/request_quotations_screen.dart';

void main() {
  testWidgets('Màn hình báo giá hiển thị banner & trạng thái trống cho Khách hàng',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => QuotationProvider()),
        ],
        child: const MaterialApp(
          home: RequestQuotationsScreen(requestId: 'req_test'),
        ),
      ),
    );

    // Kích hoạt postFrameCallback (gọi API nhưng không có token -> bỏ qua)
    await tester.pump();
    await tester.pump();

    expect(find.text('Báo giá nhận được'), findsOneWidget);
    expect(find.textContaining('Chưa có báo giá nào'), findsOneWidget);
    expect(find.text('Chưa có thợ nào báo giá'), findsOneWidget);

    // Thanh sắp xếp không hiện khi chưa có báo giá
    expect(find.text('So sánh theo:'), findsNothing);
  });

  testWidgets('Nhấn nút làm mới không gây lỗi khi chưa đăng nhập',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => QuotationProvider()),
        ],
        child: const MaterialApp(
          home: RequestQuotationsScreen(requestId: 'req_test'),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pump();

    expect(find.text('Báo giá nhận được'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
