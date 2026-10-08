import '../../../technician/data/models/technician_profile_model.dart';


class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final DateTime dateOfBirth;
  final String gender;
  final String role;
  final String avatar;
  final bool isActive;
  final DateTime? createdAt;
  final TechnicianProfileModel? technicianProfile;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.dateOfBirth,
    required this.gender,
    required this.role,
    this.avatar = '',
    this.isActive = true,
    this.createdAt,
    this.technicianProfile,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'].toString()) ?? DateTime(2000)
          : DateTime(2000),
      gender: json['gender'] ?? 'male',
      role: json['role'] ?? 'user',
      avatar: json['avatar'] ?? '',
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      technicianProfile: json['technicianProfile'] != null
          ? TechnicianProfileModel.fromJson(
              json['technicianProfile'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'gender': gender,
      'role': role,
      'avatar': avatar,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'technicianProfile': technicianProfile?.toJson(),
    };
  }


  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? gender,
    String? role,
    String? avatar,
    bool? isActive,
    DateTime? createdAt,
    TechnicianProfileModel? technicianProfile,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      role: role ?? this.role,
      avatar: avatar ?? this.avatar,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      technicianProfile: technicianProfile ?? this.technicianProfile,
    );
  }



  String get roleDisplay {
    switch (role.toLowerCase()) {
      case 'technician':
        return 'Thợ kỹ thuật';
      case 'staff':
        return 'Nhân viên';
      case 'admin':
        return 'Quản trị viên';
      case 'user':
      default:
        return 'Khách hàng';
    }
  }

  String get genderDisplay {
    switch (gender.toLowerCase()) {
      case 'male':
        return 'Nam';
      case 'female':
        return 'Nữ';
      default:
        return 'Khác';
    }
  }

  String get initials {
    final parts = fullName.trim().split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
