import 'package:flutter/material.dart';

import '../../data/datasources/complaint_remote_datasource.dart';
import '../../data/models/complaint_model.dart';

class ComplaintProvider extends ChangeNotifier {
  final ComplaintRemoteDataSource _dataSource;

  ComplaintProvider({ComplaintRemoteDataSource? dataSource})
    : _dataSource = dataSource ?? ComplaintRemoteDataSource();

  List<ComplaintModel> _complaints = [];
  Map<String, dynamic> _counts = {};
  bool _isLoading = false;
  bool _isActionLoading = false;
  String _statusFilter = 'ALL';
  String? _errorMessage;
  String? _successMessage;

  List<ComplaintModel> get complaints => _complaints;
  int countOf(String status) => (_counts[status] as num?)?.toInt() ?? 0;
  bool get isLoading => _isLoading;
  bool get isActionLoading => _isActionLoading;
  String get statusFilter => _statusFilter;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<void> fetchComplaints(String token, {String? status}) async {
    if (status != null) _statusFilter = status;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _dataSource.getComplaints(
        token: token,
        status: _statusFilter,
      );
      _complaints = data['complaints'] as List<ComplaintModel>;
      _counts = data['counts'] as Map<String, dynamic>;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> handleComplaint({
    required String token,
    required String complaintId,
    required String status,
    required String staffNote,
  }) async {
    _isActionLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final updated = await _dataSource.handleComplaint(
        token: token,
        complaintId: complaintId,
        status: status,
        staffNote: staffNote,
      );
      final index = _complaints.indexWhere((item) => item.id == complaintId);
      if (index >= 0) _complaints[index] = updated;
      _successMessage = 'Đã cập nhật hồ sơ khiếu nại';
      return true;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }
}
