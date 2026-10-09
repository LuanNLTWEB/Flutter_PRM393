import 'package:flutter/material.dart';
import '../../data/datasources/repair_request_remote_datasource.dart';
import '../../data/models/service_category_model.dart';
import '../../data/models/repair_request_model.dart';

class RepairRequestProvider extends ChangeNotifier {
  final RepairRequestRemoteDataSource _dataSource;

  RepairRequestProvider({RepairRequestRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? RepairRequestRemoteDataSource();

  // State danh mục dịch vụ
  List<ServiceCategoryModel> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;
  ServiceCategoryModel? _selectedCategory;
  String _searchKeyword = '';

  // State yêu cầu sửa chữa
  bool _isSubmitting = false;
  String? _submitError;
  RepairRequestModel? _lastCreatedRequest;

  // Danh sách danh mục
  List<ServiceCategoryModel> get categories {
    if (_searchKeyword.trim().isEmpty) {
      return _categories;
    }
    final keyword = _searchKeyword.toLowerCase().trim();
    return _categories.where((cat) {
      final nameMatches = cat.name.toLowerCase().contains(keyword);
      final descMatches = cat.description.toLowerCase().contains(keyword);
      final issuesMatch = cat.commonIssues.any((issue) => issue.toLowerCase().contains(keyword));
      return nameMatches || descMatches || issuesMatch;
    }).toList();
  }

  List<ServiceCategoryModel> get rawCategories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ServiceCategoryModel? get selectedCategory => _selectedCategory;
  String get searchKeyword => _searchKeyword;

  // Getters tạo yêu cầu
  bool get isSubmitting => _isSubmitting;
  String? get submitError => _submitError;
  RepairRequestModel? get lastCreatedRequest => _lastCreatedRequest;

  // Tải danh sách danh mục từ API
  Future<void> fetchCategories({bool refresh = false}) async {
    if (_categories.isNotEmpty && !refresh) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _dataSource.getCategories();
      _categories = result;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  // Cập nhật từ khóa tìm kiếm
  void setSearchKeyword(String keyword) {
    _searchKeyword = keyword;
    notifyListeners();
  }

  // Chọn danh mục dịch vụ
  void selectCategory(ServiceCategoryModel? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // Tạo yêu cầu sửa chữa mới
  Future<RepairRequestModel?> createRepairRequest({
    required String token,
    required String serviceCategoryId,
    required String title,
    required String description,
    String urgency = 'medium',
  }) async {
    _isSubmitting = true;
    _submitError = null;
    notifyListeners();

    try {
      final result = await _dataSource.createRepairRequest(
        token: token,
        serviceCategoryId: serviceCategoryId,
        title: title,
        description: description,
        urgency: urgency,
      );
      _lastCreatedRequest = result;
      _isSubmitting = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isSubmitting = false;
      _submitError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  // Reset lỗi gửi yêu cầu
  void clearSubmitError() {
    _submitError = null;
    notifyListeners();
  }
}
