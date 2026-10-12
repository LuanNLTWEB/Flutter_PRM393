import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/datasources/completion_remote_datasource.dart';
import '../../../repair_request/data/models/repair_request_model.dart';

class CompletionProvider extends ChangeNotifier {
  final CompletionRemoteDataSource _dataSource;

  CompletionProvider({CompletionRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? CompletionRemoteDataSource();

  bool _isUploading = false;
  String? _errorMessage;
  RepairRequestModel? _updatedRequest;

  bool get isUploading => _isUploading;
  String? get errorMessage => _errorMessage;
  RepairRequestModel? get updatedRequest => _updatedRequest;

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
}
