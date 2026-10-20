import 'package:flutter/material.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../repair_request/data/models/service_category_model.dart';
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

  // Quản lý Danh mục dịch vụ (UC-STF-02)
  List<ServiceCategoryModel> _categories = [];
  int _categoriesTotal = 0;
  int _categoriesActive = 0;
  int _categoriesInactive = 0;
  bool _isCategoriesLoading = false;
  String? _categoryFilter; // null / 'ALL', 'ACTIVE', 'INACTIVE'
  String _categorySearchQuery = '';

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

  // ==========================================================
  // GETTERS & METHODS FOR CATEGORY MANAGEMENT (UC-STF-02)
  // ==========================================================

  List<ServiceCategoryModel> get categories {
    var list = _categories;
    if (_categoryFilter == 'ACTIVE') {
      list = list.where((c) => c.isActive).toList();
    } else if (_categoryFilter == 'INACTIVE') {
      list = list.where((c) => !c.isActive).toList();
    }
    if (_categorySearchQuery.trim().isNotEmpty) {
      final q = _categorySearchQuery.toLowerCase().trim();
      list = list.where((c) =>
          c.name.toLowerCase().contains(q) ||
          c.description.toLowerCase().contains(q) ||
          c.slug.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  List<ServiceCategoryModel> get rawCategories => _categories;
  int get categoriesTotal => _categoriesTotal;
  int get categoriesActive => _categoriesActive;
  int get categoriesInactive => _categoriesInactive;
  bool get isCategoriesLoading => _isCategoriesLoading;
  String? get categoryFilter => _categoryFilter;
  String get categorySearchQuery => _categorySearchQuery;

  void setCategoryFilter(String? filter) {
    _categoryFilter = filter;
    notifyListeners();
  }

  void setCategorySearch(String query) {
    _categorySearchQuery = query;
    notifyListeners();
  }

  /// Lấy danh sách danh mục quản trị kèm thống kê
  Future<void> fetchCategoriesForManage(String token) async {
    _isCategoriesLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _dataSource.getCategoriesForManage(token: token);
      _categories = res['categories'] as List<ServiceCategoryModel>;
      _categoriesTotal = res['total'] as int;
      _categoriesActive = res['activeCount'] as int;
      _categoriesInactive = res['inactiveCount'] as int;
      _isCategoriesLoading = false;
      notifyListeners();
    } catch (e) {
      _isCategoriesLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  /// Tạo danh mục mới
  Future<bool> createCategory({
    required String token,
    required String name,
    required String description,
    required String icon,
    required String color,
    required double basePrice,
    List<String> commonIssues = const [],
    bool isActive = true,
    int sortOrder = 0,
  }) async {
    _isActionLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final newCat = await _dataSource.createCategory(
        token: token,
        name: name,
        description: description,
        icon: icon,
        color: color,
        basePrice: basePrice,
        commonIssues: commonIssues,
        isActive: isActive,
        sortOrder: sortOrder,
      );

      _categories.insert(0, newCat);
      _categoriesTotal++;
      if (newCat.isActive) {
        _categoriesActive++;
      } else {
        _categoriesInactive++;
      }

      _isActionLoading = false;
      _successMessage = 'Tạo danh mục "${newCat.name}" thành công';
      notifyListeners();
      return true;
    } catch (e) {
      _isActionLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Cập nhật danh mục
  Future<bool> updateCategory({
    required String token,
    required String id,
    String? name,
    String? description,
    String? icon,
    String? color,
    double? basePrice,
    List<String>? commonIssues,
    bool? isActive,
    int? sortOrder,
  }) async {
    _isActionLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final updatedCat = await _dataSource.updateCategory(
        token: token,
        id: id,
        name: name,
        description: description,
        icon: icon,
        color: color,
        basePrice: basePrice,
        commonIssues: commonIssues,
        isActive: isActive,
        sortOrder: sortOrder,
      );

      final idx = _categories.indexWhere((c) => c.id == id);
      if (idx != -1) {
        _categories[idx] = updatedCat;
      }
      _categoriesActive = _categories.where((c) => c.isActive).length;
      _categoriesInactive = _categories.where((c) => !c.isActive).length;

      _isActionLoading = false;
      _successMessage = 'Cập nhật danh mục "${updatedCat.name}" thành công';
      notifyListeners();
      return true;
    } catch (e) {
      _isActionLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Đổi trạng thái kích hoạt / ẩn danh mục
  Future<bool> toggleCategoryStatus({
    required String token,
    required String id,
  }) async {
    _isActionLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final updatedCat = await _dataSource.toggleCategoryStatus(
        token: token,
        id: id,
      );

      final idx = _categories.indexWhere((c) => c.id == id);
      if (idx != -1) {
        _categories[idx] = updatedCat;
      }
      _categoriesActive = _categories.where((c) => c.isActive).length;
      _categoriesInactive = _categories.where((c) => !c.isActive).length;

      _isActionLoading = false;
      _successMessage = updatedCat.isActive
          ? 'Đã kích hoạt danh mục "${updatedCat.name}"'
          : 'Đã tạm ẩn danh mục "${updatedCat.name}"';
      notifyListeners();
      return true;
    } catch (e) {
      _isActionLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Xóa danh mục
  Future<bool> deleteCategory({
    required String token,
    required String id,
  }) async {
    _isActionLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final res = await _dataSource.deleteCategory(
        token: token,
        id: id,
      );

      final softDeleted = res['softDeleted'] == true;
      if (softDeleted) {
        final idx = _categories.indexWhere((c) => c.id == id);
        if (idx != -1) {
          final old = _categories[idx];
          _categories[idx] = ServiceCategoryModel(
            id: old.id,
            name: old.name,
            slug: old.slug,
            description: old.description,
            icon: old.icon,
            color: old.color,
            basePrice: old.basePrice,
            commonIssues: old.commonIssues,
            isActive: false,
            sortOrder: old.sortOrder,
          );
        }
      } else {
        _categories.removeWhere((c) => c.id == id);
        _categoriesTotal--;
      }
      _categoriesActive = _categories.where((c) => c.isActive).length;
      _categoriesInactive = _categories.where((c) => !c.isActive).length;

      _isActionLoading = false;
      _successMessage = res['message'] as String;
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
