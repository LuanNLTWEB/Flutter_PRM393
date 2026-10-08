import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../auth/data/models/user_model.dart';
import '../../data/datasources/technician_remote_datasource.dart';

class TechnicianProvider extends ChangeNotifier {
  final TechnicianRemoteDataSource _dataSource;

  TechnicianProvider({TechnicianRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? TechnicianRemoteDataSource();

  List<UserModel> _publicTechnicians = [];
  UserModel? _selectedTechnician;
  List<UserModel> _kycTechnicians = [];

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  List<UserModel> get publicTechnicians => _publicTechnicians;
  UserModel? get selectedTechnician => _selectedTechnician;
  List<UserModel> get kycTechnicians => _kycTechnicians;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Lấy danh sách thợ công khai đã duyệt
  Future<void> fetchPublicTechnicians({String? skill, String? search}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _publicTechnicians = await _dataSource.getPublicTechnicians(
        skill: skill,
        search: search,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Lấy chi tiết hồ sơ công khai của thợ
  Future<void> fetchTechnicianDetail(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedTechnician = await _dataSource.getPublicTechnicianDetail(id);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Đăng ký tài khoản Thợ
  Future<bool> registerTechnician({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
    required DateTime dateOfBirth,
    required String gender,
    required List<String> skills,
    required int experienceYears,
    required String bio,
    required XFile idCardFront,
    required XFile idCardBack,
    List<XFile> certificates = const [],
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final res = await _dataSource.registerTechnician(
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
        confirmPassword: confirmPassword,
        dateOfBirth: dateOfBirth,
        gender: gender,
        skills: skills,
        experienceYears: experienceYears,
        bio: bio,
        idCardFront: idCardFront,
        idCardBack: idCardBack,
        certificates: certificates,
      );
      _successMessage = res['message'] ?? 'Đăng ký thợ thành công!';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Lấy danh sách KYC cho Admin & Staff
  Future<void> fetchKYCTechnicians(String token, {String status = 'pending'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _kycTechnicians = await _dataSource.getKYCTechnicians(token, status: status);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Duyệt hồ sơ Thợ
  Future<bool> approveTechnician(String token, String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _dataSource.approveTechnician(token, id);
      _successMessage = 'Đã phê duyệt hồ sơ thợ thành công!';
      // Cập nhật local list
      _kycTechnicians.removeWhere((item) => item.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Từ chối hồ sơ Thợ kèm lý do
  Future<bool> rejectTechnician(String token, String id, String reason) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _dataSource.rejectTechnician(token, id, reason);
      _successMessage = 'Đã từ chối hồ sơ thợ thành công!';
      // Cập nhật local list
      _kycTechnicians.removeWhere((item) => item.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Thợ tự bật/tắt nhận việc
  Future<bool?> toggleAvailability(String token, {bool? isAvailable}) async {
    try {
      final newStatus = await _dataSource.toggleAvailability(token, isAvailable: isAvailable);
      return newStatus;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }
}
