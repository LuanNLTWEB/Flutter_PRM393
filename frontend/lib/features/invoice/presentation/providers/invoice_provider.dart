import 'package:flutter/material.dart';

import '../../data/datasources/invoice_local_datasource.dart';
import '../../data/datasources/invoice_remote_datasource.dart';
import '../../data/models/invoice_model.dart';

class InvoiceProvider extends ChangeNotifier {
  final InvoiceRemoteDataSource _remoteDataSource;
  final InvoiceLocalDataSource _localDataSource;

  InvoiceProvider({
    InvoiceRemoteDataSource? remoteDataSource,
    InvoiceLocalDataSource? localDataSource,
  }) : _remoteDataSource = remoteDataSource ?? InvoiceRemoteDataSource(),
       _localDataSource = localDataSource ?? InvoiceLocalDataSource();

  List<InvoiceModel> _invoices = [];
  bool _isLoading = false;
  bool _isShowingOfflineData = false;
  DateTime? _cachedAt;
  String? _errorMessage;

  List<InvoiceModel> get invoices => _invoices;
  bool get isLoading => _isLoading;
  bool get isShowingOfflineData => _isShowingOfflineData;
  DateTime? get cachedAt => _cachedAt;
  String? get errorMessage => _errorMessage;

  /// Ưu tiên tải dữ liệu mới nhất; khi không có mạng, hiển thị bản đã lưu trên máy.
  Future<void> fetchInvoices({
    required String token,
    required String userId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final invoices = await _remoteDataSource.getMyInvoices(token: token);
      await _localDataSource.cacheInvoices(userId: userId, invoices: invoices);
      _invoices = invoices;
      _isShowingOfflineData = false;
      _cachedAt = DateTime.now();
    } catch (error) {
      try {
        final cached = await _localDataSource.getCachedInvoices(userId);
        if (cached == null) {
          _invoices = [];
          _isShowingOfflineData = false;
          _cachedAt = null;
          _errorMessage = 'Chưa có hóa đơn nào được lưu trên thiết bị. Hãy kết nối mạng để đồng bộ lần đầu.';
        } else {
          _invoices = cached.invoices;
          _isShowingOfflineData = true;
          _cachedAt = cached.cachedAt;
        }
      } catch (_) {
        _invoices = [];
        _isShowingOfflineData = false;
        _cachedAt = null;
        _errorMessage = 'Không thể mở dữ liệu hóa đơn đã lưu trên thiết bị.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
