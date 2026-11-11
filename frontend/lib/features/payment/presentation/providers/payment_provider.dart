/// Author: Lam Hoang Phuc (CE191132)
/// Use Cases: #UC-PAY-01, #UC-PAY-02, #UC-PAY-03, #UC-PAY-04, #UC-PAY-05
/// Description: State Management Provider cho hóa đơn, thu tiền mặt và biên nhận điện tử
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/datasources/payment_remote_datasource.dart';
import '../../data/models/electronic_receipt_model.dart';
import '../../data/models/invoice_model.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentRemoteDataSource _dataSource;

  PaymentProvider({PaymentRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? PaymentRemoteDataSource();

  InvoiceModel? _invoice;
  ElectronicReceiptModel? _receipt;
  bool _isLoading = false;
  bool _isLoadingReceipt = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _receiptError;

  InvoiceModel? get invoice => _invoice;
  ElectronicReceiptModel? get receipt => _receipt;
  bool get isLoading => _isLoading;
  bool get isLoadingReceipt => _isLoadingReceipt;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String? get receiptError => _receiptError;

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

  Future<void> fetchElectronicReceipt({
    required String token,
    required String requestId,
  }) async {
    _receipt = null;
    _isLoadingReceipt = true;
    _receiptError = null;
    notifyListeners();

    try {
      _receipt = await _dataSource.getElectronicReceipt(
        token: token,
        requestId: requestId,
      );
    } catch (e) {
      _receiptError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoadingReceipt = false;
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
