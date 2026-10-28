import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
    String paymentMethod = 'CASH',
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

  Future<bool> uploadPartsInvoices({
    required String token,
    required String requestId,
    required List<XFile> images,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _invoice = await _dataSource.uploadPartsInvoiceImages(
        token: token,
        requestId: requestId,
        images: images,
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

  Future<bool> confirmPaymentReceived({
    required String token,
    required String requestId,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _invoice = await _dataSource.confirmPaymentReceived(
        token: token,
        requestId: requestId,
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
