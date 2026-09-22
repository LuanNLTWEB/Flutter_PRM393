import 'package:flutter/material.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/models/login_request.dart';

class LoginProvider extends ChangeNotifier {
  final AuthRemoteDataSource _dataSource;

  LoginProvider({AuthRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? AuthRemoteDataSource();

  bool _isLoading = false;
  String? _errorMessage;
  bool _isSuccess = false;
  String? _token;
  Map<String, dynamic>? _user;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSuccess => _isSuccess;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;

  Future<bool> login(LoginRequest request) async {
    _isLoading = true;
    _errorMessage = null;
    _isSuccess = false;
    notifyListeners();

    try {
      final response = await _dataSource.login(request);
      final data = response['data'] as Map<String, dynamic>?;
      _token = data?['token'] as String?;
      _user = data?['user'] as Map<String, dynamic>?;
      _isLoading = false;
      _isSuccess = true;
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
    _token = null;
    _user = null;
    notifyListeners();
  }
}
