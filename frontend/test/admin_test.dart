import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/admin/presentation/providers/admin_provider.dart';
import 'package:frontend/features/auth/data/models/user_model.dart';

void main() {
  group('Admin Feature Tests', () {
    test('UserModel roleDisplay returns correct localization', () {
      final adminUser = UserModel(
        id: '1',
        fullName: 'Admin User',
        email: 'admin@test.com',
        phoneNumber: '0901112233',
        dateOfBirth: DateTime(1990, 1, 1),
        gender: 'male',
        role: 'admin',
        isActive: true,
      );
      expect(adminUser.roleDisplay, 'Quản trị viên');

      final staffUser = adminUser.copyWith(role: 'staff');
      expect(staffUser.roleDisplay, 'Nhân viên');

      final techUser = adminUser.copyWith(role: 'technician');
      expect(techUser.roleDisplay, 'Thợ kỹ thuật');

      final regularUser = adminUser.copyWith(role: 'user');
      expect(regularUser.roleDisplay, 'Khách hàng');
    });

    test('AdminProvider initializes with default values', () {
      final provider = AdminProvider();
      expect(provider.users, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.isActionLoading, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.successMessage, isNull);
      expect(provider.selectedRole, isNull);
      expect(provider.selectedStatus, isNull);
      expect(provider.searchQuery, isEmpty);
    });

    test('AdminProvider clearMessage clears error and success messages', () {
      final provider = AdminProvider();
      provider.clearMessage();
      expect(provider.errorMessage, isNull);
      expect(provider.successMessage, isNull);
    });
  });
}
