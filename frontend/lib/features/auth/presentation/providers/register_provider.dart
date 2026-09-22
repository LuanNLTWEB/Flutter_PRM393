import 'package:flutter/material.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/models/register_request.dart';

class RegisterProvider extends ChangeNotifier {
  final AuthRemoteDataSource _dataSource;

  RegisterProvider({AuthRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? AuthRemoteDataSource();

  bool _isLoading = false;
  String? _errorMessage;
  bool _isSuccess = false;
  String? _successMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSuccess => _isSuccess;
  String? get successMessage => _successMessage;

  Future<bool> register(RegisterRequest request) async {
    _isLoading = true;
    _errorMessage = null;
    _isSuccess = false;
    _successMessage = null;
    notifyListeners();

    try {
      final response = await _dataSource.register(request);
      _isLoading = false;
      _isSuccess = true;
      _successMessage = response['message'] ?? 'Đăng ký thành công!';
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isSuccess = false;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _isLoading = false;
    _errorMessage = null;
    _isSuccess = false;
    _successMessage = null;
    notifyListeners();
  }
}
