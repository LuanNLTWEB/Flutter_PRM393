import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:frontend/features/profile/data/datasources/user_remote_datasource.dart';
import 'package:frontend/features/profile/presentation/widgets/change_password_dialog.dart';

class MockUserRemoteDataSource extends UserRemoteDataSource {
  bool shouldSucceed = true;
  String? failMessage;
  String? lastCurrentPassword;
  String? lastNewPassword;

  @override
  Future<void> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    lastCurrentPassword = currentPassword;
    lastNewPassword = newPassword;
    if (!shouldSucceed) {
      throw Exception(failMessage ?? 'Mật khẩu hiện tại không chính xác');
    }
  }
}

class FakeAuthProvider extends AuthProvider {
  final MockUserRemoteDataSource mockDataSource;

  FakeAuthProvider({required this.mockDataSource})
      : super(
          authDataSource: AuthRemoteDataSource(),
          userDataSource: mockDataSource,
        );

  @override
  String? get token => 'fake-jwt-token';

  @override
  bool get isAuthenticated => true;

  @override
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await mockDataSource.changePassword(
        token: token!,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}

Widget createTestableWidget({required FakeAuthProvider authProvider}) {
  return ChangeNotifierProvider<AuthProvider>.value(
    value: authProvider,
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const ChangePasswordDialog(),
                );
              },
              child: const Text('Mở đổi mật khẩu'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  late MockUserRemoteDataSource mockUserRemoteDataSource;
  late FakeAuthProvider fakeAuthProvider;

  setUp(() {
    mockUserRemoteDataSource = MockUserRemoteDataSource();
    fakeAuthProvider = FakeAuthProvider(mockDataSource: mockUserRemoteDataSource);
  });

  Future<void> openDialog(WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget(authProvider: fakeAuthProvider));
    await tester.tap(find.text('Mở đổi mật khẩu'));
    await tester.pumpAndSettle();
  }

  group('ChangePasswordDialog Tests', () {
    testWidgets('renders all input fields, title and action buttons',
        (tester) async {
      await openDialog(tester);

      expect(find.text('Đổi mật khẩu'), findsOneWidget);
      expect(find.text('Nhập mật khẩu cũ và đặt mật khẩu mới'), findsOneWidget);
      expect(find.byKey(const Key('current_password_field')), findsOneWidget);
      expect(find.byKey(const Key('new_password_field')), findsOneWidget);
      expect(find.byKey(const Key('confirm_password_field')), findsOneWidget);
      expect(find.byKey(const Key('submit_change_password_button')), findsOneWidget);
      expect(find.text('Hủy'), findsOneWidget);
    });

    testWidgets('validates empty inputs correctly', (tester) async {
      await openDialog(tester);

      final submitBtn = find.byKey(const Key('submit_change_password_button'));
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập mật khẩu hiện tại'), findsOneWidget);
      expect(find.text('Vui lòng nhập mật khẩu mới'), findsOneWidget);
      expect(find.text('Vui lòng xác nhận mật khẩu mới'), findsOneWidget);
    });

    testWidgets('validates password length under 6 characters', (tester) async {
      await openDialog(tester);

      await tester.enterText(
        find.byKey(const Key('current_password_field')),
        'oldpass123',
      );
      await tester.enterText(
        find.byKey(const Key('new_password_field')),
        '12345',
      );
      await tester.enterText(
        find.byKey(const Key('confirm_password_field')),
        '12345',
      );

      final submitBtn = find.byKey(const Key('submit_change_password_button'));
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Mật khẩu mới phải có ít nhất 6 ký tự'), findsOneWidget);
    });

    testWidgets('validates new password cannot be the same as current password',
        (tester) async {
      await openDialog(tester);

      await tester.enterText(
        find.byKey(const Key('current_password_field')),
        'password123',
      );
      await tester.enterText(
        find.byKey(const Key('new_password_field')),
        'password123',
      );
      await tester.enterText(
        find.byKey(const Key('confirm_password_field')),
        'password123',
      );

      final submitBtn = find.byKey(const Key('submit_change_password_button'));
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(
        find.text('Mật khẩu mới không được trùng với mật khẩu hiện tại'),
        findsOneWidget,
      );
    });

    testWidgets('validates password confirmation mismatch', (tester) async {
      await openDialog(tester);

      await tester.enterText(
        find.byKey(const Key('current_password_field')),
        'oldpassword123',
      );
      await tester.enterText(
        find.byKey(const Key('new_password_field')),
        'newpassword123',
      );
      await tester.enterText(
        find.byKey(const Key('confirm_password_field')),
        'differentpassword',
      );

      final submitBtn = find.byKey(const Key('submit_change_password_button'));
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Xác nhận mật khẩu không khớp'), findsOneWidget);
    });

    testWidgets('successful change password submission triggers datasource with correct data',
        (tester) async {
      await openDialog(tester);

      await tester.enterText(
        find.byKey(const Key('current_password_field')),
        'oldPass123',
      );
      await tester.enterText(
        find.byKey(const Key('new_password_field')),
        'newPass456',
      );
      await tester.enterText(
        find.byKey(const Key('confirm_password_field')),
        'newPass456',
      );

      final submitBtn = find.byKey(const Key('submit_change_password_button'));
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(mockUserRemoteDataSource.lastCurrentPassword, 'oldPass123');
      expect(mockUserRemoteDataSource.lastNewPassword, 'newPass456');
      expect(find.text('Đổi mật khẩu thành công!'), findsOneWidget);
    });
  });
}
