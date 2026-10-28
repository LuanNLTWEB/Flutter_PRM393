import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/datasources/completion_remote_datasource.dart';
import '../../data/models/completion_qr_model.dart';
import '../../../repair_request/data/models/repair_request_model.dart';

class CompletionProvider extends ChangeNotifier {
  final CompletionRemoteDataSource _dataSource;

  CompletionProvider({CompletionRemoteDataSource? dataSource})
    : _dataSource = dataSource ?? CompletionRemoteDataSource();

  bool _isUploading = false;
  bool _isGeneratingQr = false;
  bool _isConfirming = false;
  String? _errorMessage;
  RepairRequestModel? _updatedRequest;
  CompletionQrModel? _confirmationQr;

  bool get isUploading => _isUploading;
  bool get isGeneratingQr => _isGeneratingQr;
  bool get isConfirming => _isConfirming;
  String? get errorMessage => _errorMessage;
  RepairRequestModel? get updatedRequest => _updatedRequest;
  CompletionQrModel? get confirmationQr => _confirmationQr;

  Future<bool> uploadImages({
    required String token,
    required String requestId,
    required List<XFile> images,
  }) async {
    _isUploading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _updatedRequest = await _dataSource.uploadImages(
        token: token,
        requestId: requestId,
        images: images,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  Future<bool> generateCompletionQr({
    required String token,
    required String requestId,
  }) async {
    _isGeneratingQr = true;
    _errorMessage = null;
    _confirmationQr = null;
    notifyListeners();

    try {
      _confirmationQr = await _dataSource.generateCompletionQr(
        token: token,
        requestId: requestId,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isGeneratingQr = false;
      notifyListeners();
    }
  }

  Future<bool> confirmCompletion({
    required String token,
    required CompletionQrPayload payload,
  }) async {
    _isConfirming = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _dataSource.confirmCompletion(
        token: token,
        requestId: payload.requestId,
        qrToken: payload.token,
        amount: payload.amount,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isConfirming = false;
      notifyListeners();
    }
  }
}
