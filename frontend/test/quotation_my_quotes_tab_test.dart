import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/repair_request/presentation/providers/repair_request_provider.dart';
import 'package:frontend/features/quotations/presentation/providers/quotation_provider.dart';
import 'package:frontend/features/quotations/presentation/screens/nearby_requests_screen.dart';

void main() {
  testWidgets('Thợ chuyển sang tab "Đã báo giá" thấy trạng thái trống',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => RepairRequestProvider()),
          ChangeNotifierProvider(create: (_) => QuotationProvider()),
        ],
        child: const MaterialApp(home: NearbyRequestsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    // Tab mặc định là "Công khai"
    expect(find.text('Yêu cầu quanh đây'), findsOneWidget);
    expect(find.text('Công khai'), findsOneWidget);
    expect(find.text('Đã báo giá'), findsOneWidget);

    // Chuyển tab
    await tester.tap(find.text('Đã báo giá'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Yêu cầu đã báo giá'), findsOneWidget);
    expect(find.text('Bạn chưa gửi báo giá nào'), findsOneWidget);
    expect(find.textContaining('tab "Công khai"'), findsOneWidget);

    // Quay lại tab Công khai
    await tester.tap(find.text('Công khai'));
    await tester.pump();

    expect(find.text('Yêu cầu quanh đây'), findsOneWidget);
  });
}
