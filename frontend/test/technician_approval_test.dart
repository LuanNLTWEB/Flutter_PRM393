import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/data/models/user_model.dart';
import 'package:frontend/features/technician/data/models/technician_profile_model.dart';
import 'package:frontend/features/technician/presentation/providers/technician_provider.dart';

void main() {
  group('UC-STF-01: Technician Approval Tests', () {
    test('TechnicianProfileModel parses approval status and documents correctly', () {
      final json = {
        'skills': ['Sửa điện', 'Sửa ống nước'],
        'experienceYears': 4,
        'bio': 'Thợ có nhiều năm kinh nghiệm tại TP.HCM',
        'idCardFront': 'https://res.cloudinary.com/test/id_front.jpg',
        'idCardBack': 'https://res.cloudinary.com/test/id_back.jpg',
        'certificates': ['https://res.cloudinary.com/test/cert1.jpg'],
        'approvalStatus': 'pending',
        'rejectionReason': '',
        'approvedAt': null,
        'rejectedAt': null,
        'approvedBy': {'fullName': 'Admin Super'},
        'isAvailable': false,
      };

      final profile = TechnicianProfileModel.fromJson(json);

      expect(profile.skills, contains('Sửa điện'));
      expect(profile.skills.length, 2);
      expect(profile.experienceYears, 4);
      expect(profile.idCardFront, 'https://res.cloudinary.com/test/id_front.jpg');
      expect(profile.idCardBack, 'https://res.cloudinary.com/test/id_back.jpg');
      expect(profile.certificates.length, 1);
      expect(profile.approvalStatus, 'pending');
      expect(profile.approvalStatusDisplay, 'Chờ phê duyệt');
      expect(profile.approvedByName, 'Admin Super');
      expect(profile.isAvailable, isFalse);
    });

    test('TechnicianProfileModel approvalStatusDisplay localizes correctly', () {
      const pendingProfile = TechnicianProfileModel(approvalStatus: 'pending');
      expect(pendingProfile.approvalStatusDisplay, 'Chờ phê duyệt');

      const approvedProfile = TechnicianProfileModel(approvalStatus: 'approved');
      expect(approvedProfile.approvalStatusDisplay, 'Đã phê duyệt');

      const rejectedProfile = TechnicianProfileModel(approvalStatus: 'rejected');
      expect(rejectedProfile.approvalStatusDisplay, 'Bị từ chối');
    });

    test('UserModel contains technicianProfile when parsed from JSON', () {
      final userJson = {
        '_id': 'tech_123',
        'fullName': 'Nguyễn Văn Thợ',
        'email': 'tho@example.com',
        'phoneNumber': '0912345678',
        'dateOfBirth': '1992-05-10T00:00:00.000Z',
        'gender': 'male',
        'role': 'technician',
        'technicianProfile': {
          'skills': ['Điện gia dụng'],
          'experienceYears': 5,
          'idCardFront': 'http://img.jpg',
          'idCardBack': 'http://img2.jpg',
          'approvalStatus': 'approved',
          'approvedBy': {'fullName': 'Staff Luân'},
        },
      };

      final user = UserModel.fromJson(userJson);

      expect(user.id, 'tech_123');
      expect(user.fullName, 'Nguyễn Văn Thợ');
      expect(user.role, 'technician');
      expect(user.roleDisplay, 'Thợ kỹ thuật');
      expect(user.technicianProfile, isNotNull);
      expect(user.technicianProfile!.skills, contains('Điện gia dụng'));
      expect(user.technicianProfile!.approvalStatus, 'approved');
      expect(user.technicianProfile!.approvedByName, 'Staff Luân');
    });

    test('TechnicianProvider initializes KYC state cleanly', () {
      final provider = TechnicianProvider();
      expect(provider.kycTechnicians, isEmpty);
      expect(provider.kycCounts['pending'], 0);
      expect(provider.kycCounts['approved'], 0);
      expect(provider.kycCounts['rejected'], 0);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
    });
  });
}
