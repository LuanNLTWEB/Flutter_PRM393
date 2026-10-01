import 'package:flutter/material.dart';
import '../../../auth/data/models/user_model.dart';
import '../../data/datasources/admin_remote_datasource.dart';

class AdminProvider extends ChangeNotifier {
  final AdminRemoteDataSource _dataSource;

  AdminProvider({AdminRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? AdminRemoteDataSource();

  List<UserModel> _users = [];
  bool _isLoading = false;
  bool _isActionLoading = false;
  String? _errorMessage;
  String? _successMessage;

  String _searchQuery = '';
  String? _selectedRole;
  bool? _selectedStatus;

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  bool get isActionLoading => _isActionLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  String get searchQuery => _searchQuery;
  String? get selectedRole => _selectedRole;
  bool? get selectedStatus => _selectedStatus;

  /// Lấy danh sách tài khoản từ API
  Future<void> fetchUsers(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _dataSource.getUsers(
        token: token,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        role: _selectedRole,
        isActive: _selectedStatus,
      );
      _users = result;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  /// Cập nhật từ khóa tìm kiếm
  void setSearchQuery(String query, String token) {
    _searchQuery = query;
    fetchUsers(token);
  }

  /// Cập nhật bộ lọc vai trò
  void setSelectedRole(String? role, String token) {
    _selectedRole = role;
    fetchUsers(token);
  }

  /// Cập nhật bộ lọc trạng thái hoạt động
  void setSelectedStatus(bool? status, String token) {
    _selectedStatus = status;
    fetchUsers(token);
  }

  /// Reset toàn bộ bộ lọc
  void resetFilters(String token) {
    _searchQuery = '';
    _selectedRole = null;
    _selectedStatus = null;
    fetchUsers(token);
  }

  /// Tạo tài khoản Staff
  Future<bool> createStaff({
    required String token,
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
    required DateTime dateOfBirth,
    required String gender,
  }) async {
    _isActionLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final newStaff = await _dataSource.createStaff(
        token: token,
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
        confirmPassword: confirmPassword,
        dateOfBirth: dateOfBirth,
        gender: gender,
      );

      // Thêm nhân viên mới vào đầu danh sách nếu thỏa mãn bộ lọc hiện tại
      _users.insert(0, newStaff);
      _isActionLoading = false;
      _successMessage = 'Tạo tài khoản nhân viên "${newStaff.fullName}" thành công';
      notifyListeners();
      return true;
    } catch (e) {
      _isActionLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Cập nhật vai trò & quyền hạn của tài khoản
  Future<bool> updateUserRole({
    required String token,
    required String userId,
    required String role,
  }) async {
    _isActionLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final updatedUser = await _dataSource.updateUserRole(
        token: token,
        userId: userId,
        role: role,
      );

      final index = _users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _users[index] = updatedUser;
      }

      _isActionLoading = false;
      _successMessage =
          'Đã cập nhật quyền cho "${updatedUser.fullName}" thành ${updatedUser.roleDisplay}';
      notifyListeners();
      return true;
    } catch (e) {
      _isActionLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Khóa / Mở khóa tài khoản
  Future<bool> toggleUserStatus({
    required String token,
    required String userId,
    bool? isActive,
  }) async {
    _isActionLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final updatedUser = await _dataSource.toggleUserStatus(
        token: token,
        userId: userId,
        isActive: isActive,
      );

      final index = _users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _users[index] = updatedUser;
      }

      _isActionLoading = false;
      _successMessage = updatedUser.isActive
          ? 'Đã mở khóa tài khoản "${updatedUser.fullName}"'
          : 'Đã khóa tài khoản "${updatedUser.fullName}"';
      notifyListeners();
      return true;
    } catch (e) {
      _isActionLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void clearMessage() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
