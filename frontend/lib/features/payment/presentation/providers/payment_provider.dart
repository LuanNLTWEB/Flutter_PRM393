import 'package:flutter/material.dart';

import '../../data/datasources/payment_remote_datasource.dart';
import '../../data/models/invoice_model.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentRemoteDataSource _dataSource;

  PaymentProvider({PaymentRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? PaymentRemoteDataSource();

  InvoiceModel? _invoice;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  InvoiceModel? get invoice => _invoice;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  Future<void> fetchInvoice({
    required String token,
    required String requestId,
  }) async {
    // Provider được dùng chung trong toàn app; không để hóa đơn của đơn trước
    // hiển thị nhầm khi mở một request khác hoặc khi request mới bị lỗi.
    _invoice = null;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _invoice = await _dataSource.getInvoice(
        token: token,
        requestId: requestId,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> selectPaymentMethod({
    required String token,
    required String requestId,
    required String paymentMethod,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _invoice = await _dataSource.selectPaymentMethod(
        token: token,
        requestId: requestId,
        paymentMethod: paymentMethod,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
