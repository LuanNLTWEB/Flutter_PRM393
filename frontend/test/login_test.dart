import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/data/models/login_request.dart';
import 'package:frontend/main.dart';

void main() {
  test('LoginRequest toJson serializes correctly', () {
    final request = LoginRequest(
      identifier: 'test@example.com',
      password: 'password123',
    );

    final json = request.toJson();
    expect(json['identifier'], 'test@example.com');
    expect(json['password'], 'password123');
  });

  testWidgets('Navigating to LoginScreen on button tap', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Tap on Đăng nhập button
    final loginBtn = find.text('Đăng nhập');
    expect(loginBtn, findsOneWidget);
    await tester.tap(loginBtn);
    await tester.pumpAndSettle();

    // Verify LoginScreen elements
    expect(find.text('Đăng nhập tài khoản'), findsOneWidget);
    expect(find.text('Email hoặc Số điện thoại *'), findsOneWidget);
    expect(find.text('Mật khẩu *'), findsOneWidget);
    expect(find.text('Chưa có tài khoản? '), findsOneWidget);
    expect(find.text('Đăng ký ngay'), findsOneWidget);
  });
}
