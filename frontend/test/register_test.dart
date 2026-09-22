import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/data/models/register_request.dart';
import 'package:frontend/main.dart';

void main() {
  test('RegisterRequest toJson serializes correctly', () {
    final dob = DateTime(1995, 5, 20);
    final request = RegisterRequest(
      fullName: 'Nguyen Van A',
      email: 'nguyenvana@example.com',
      phoneNumber: '0901234567',
      password: 'password123',
      confirmPassword: 'password123',
      dateOfBirth: dob,
      gender: 'male',
    );

    final json = request.toJson();
    expect(json['fullName'], 'Nguyen Van A');
    expect(json['email'], 'nguyenvana@example.com');
    expect(json['phoneNumber'], '0901234567');
    expect(json['password'], 'password123');
    expect(json['confirmPassword'], 'password123');
    expect(json['dateOfBirth'], dob.toIso8601String());
    expect(json['gender'], 'male');
  });

  testWidgets('Navigating to RegisterScreen on button tap', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Tap on Đăng ký button
    final registerBtn = find.text('Đăng ký');
    expect(registerBtn, findsOneWidget);
    await tester.tap(registerBtn);
    await tester.pumpAndSettle();

    // Verify RegisterScreen is pushed
    expect(find.text('Đăng ký tài khoản'), findsOneWidget);
    expect(find.text('Họ và tên *'), findsOneWidget);
    expect(find.text('Email *'), findsOneWidget);
    expect(find.text('Số điện thoại *'), findsOneWidget);
    expect(find.text('Ngày sinh *'), findsOneWidget);
    expect(find.text('Giới tính *'), findsOneWidget);
    expect(find.text('Mật khẩu *'), findsOneWidget);
    expect(find.text('Nhập lại mật khẩu *'), findsOneWidget);
  });
}
