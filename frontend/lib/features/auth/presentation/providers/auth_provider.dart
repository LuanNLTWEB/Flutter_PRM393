import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/models/login_request.dart';
import '../../data/models/register_request.dart';
import '../../data/models/user_model.dart';
import '../../../profile/data/datasources/user_remote_datasource.dart';
import 'package:image_picker/image_picker.dart';

class AuthProvider extends ChangeNotifier {

  static const String _prefTokenKey = 'homefix_token';
  static const String _prefUserKey = 'homefix_user';

  final AuthRemoteDataSource _authDataSource;
  final UserRemoteDataSource _userDataSource;

  AuthProvider({
    AuthRemoteDataSource? authDataSource,
    UserRemoteDataSource? userDataSource,
  })  : _authDataSource = authDataSource ?? AuthRemoteDataSource(),
        _userDataSource = userDataSource ?? UserRemoteDataSource();

  UserModel? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get isAuthenticated => _token != null && _currentUser != null;

  /// Tự động đăng nhập khi mở app nếu token còn lưu
  Future<void> tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(_prefTokenKey);
      final savedUserJson = prefs.getString(_prefUserKey);

      if (savedToken == null || savedUserJson == null) {
        return;
      }

      _token = savedToken;
      _currentUser = UserModel.fromJson(jsonDecode(savedUserJson));
      notifyListeners();

      // Đồng bộ thông tin mới nhất từ server
      await refreshProfile();
    } catch (e) {
      debugPrint('Lỗi khi tự động đăng nhập: $e');
    }
  }

  /// Lấy thông tin người dùng mới nhất từ server
  Future<void> refreshProfile() async {
    if (_token == null) return;
    try {
      final user = await _userDataSource.getProfile(_token!);
      _currentUser = user;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefUserKey, jsonEncode(user.toJson()));
      notifyListeners();
    } catch (e) {
      // Nếu token hết hạn hoặc lỗi xác thực, đăng xuất
      if (e.toString().contains('401') ||
          e.toString().contains('Token không hợp lệ') ||
          e.toString().contains('hết hạn')) {
        await logout();
      }
    }
  }

  /// Xử lý đăng nhập
  Future<bool> login(String identifier, String password) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final response = await _authDataSource.login(
        LoginRequest(identifier: identifier, password: password),
      );

      final data = response['data'] as Map<String, dynamic>?;
      final tokenStr = data?['token'] as String?;
      final userMap = data?['user'] as Map<String, dynamic>?;

      if (tokenStr == null || userMap == null) {
        throw Exception('Dữ liệu phản hồi từ máy chủ không hợp lệ');
      }

      _token = tokenStr;
      _currentUser = UserModel.fromJson(userMap);

      // Lưu trữ phiên đăng nhập vào bộ nhớ máy
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefTokenKey, _token!);
      await prefs.setString(_prefUserKey, jsonEncode(_currentUser!.toJson()));

      _isLoading = false;
      _successMessage = 'Đăng nhập thành công';
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Xử lý đăng ký
  Future<bool> register(RegisterRequest request) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final response = await _authDataSource.register(request);
      _isLoading = false;
      _successMessage = response['message'] ?? 'Đăng ký tài khoản thành công';
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Cập nhật thông tin cá nhân (Profile)
  Future<bool> updateProfile({
    String? fullName,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? gender,
  }) async {
    if (_token == null) {
      _errorMessage = 'Bạn chưa đăng nhập';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final updatedUser = await _userDataSource.updateProfile(
        token: _token!,
        fullName: fullName,
        phoneNumber: phoneNumber,
        dateOfBirth: dateOfBirth,
        gender: gender,
      );

      _currentUser = updatedUser;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefUserKey, jsonEncode(updatedUser.toJson()));

      _isLoading = false;
      _successMessage = 'Cập nhật thông tin thành công';
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Đổi mật khẩu
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_token == null) {
      _errorMessage = 'Bạn chưa đăng nhập';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _userDataSource.changePassword(
        token: _token!,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      _isLoading = false;
      _successMessage = 'Đổi mật khẩu thành công';
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Cập nhật ảnh đại diện lên Cloudinary
  Future<bool> updateAvatar(XFile imageFile) async {
    if (_token == null) {
      _errorMessage = 'Bạn chưa đăng nhập';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final avatarUrl = await _userDataSource.updateAvatar(
        token: _token!,
        imageFile: imageFile,
      );

      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(avatar: avatarUrl);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefUserKey, jsonEncode(_currentUser!.toJson()));
      }

      _isLoading = false;
      _successMessage = 'Cập nhật ảnh đại diện thành công';
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Đăng xuất khỏi ứng dụng
  Future<void> logout() async {

    _token = null;
    _currentUser = null;
    _errorMessage = null;
    _successMessage = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefTokenKey);
    await prefs.remove(_prefUserKey);

    notifyListeners();
  }

  void clearMessage() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
