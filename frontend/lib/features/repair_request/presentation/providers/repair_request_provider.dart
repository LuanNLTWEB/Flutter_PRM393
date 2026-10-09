import 'package:flutter/material.dart';
import '../../data/datasources/repair_request_remote_datasource.dart';
import '../../data/models/service_category_model.dart';

class RepairRequestProvider extends ChangeNotifier {
  final RepairRequestRemoteDataSource _dataSource;

  RepairRequestProvider({RepairRequestRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? RepairRequestRemoteDataSource();

  List<ServiceCategoryModel> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;
  ServiceCategoryModel? _selectedCategory;
  String _searchKeyword = '';

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

  /// Tải danh mục dịch vụ sửa chữa từ API (UC-REQ-01)
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

  /// Cập nhật từ khóa tìm kiếm dịch vụ
  void setSearchKeyword(String keyword) {
    _searchKeyword = keyword;
    notifyListeners();
  }

  /// Chọn danh mục dịch vụ
  void selectCategory(ServiceCategoryModel? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  /// Xóa thông báo lỗi
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
