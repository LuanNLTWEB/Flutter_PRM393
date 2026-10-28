import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  // Lọc danh mục theo từ khóa tìm kiếm
  void setSearchKeyword(String keyword) {
    _searchKeyword = keyword;
    notifyListeners();
  }

  // Xóa bộ lọc tìm kiếm
  void clearSearch() {
    _searchKeyword = '';
    notifyListeners();
  }

  // Tìm kiếm danh mục từ máy chủ API
  Future<void> searchCategoriesFromApi(String keyword) async {
    _searchKeyword = keyword;
    if (keyword.trim().isEmpty) {
      await fetchCategories(refresh: true);
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await _dataSource.searchCategories(keyword.trim());
      _categories = results;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  // Chọn danh mục dịch vụ
  void selectCategory(ServiceCategoryModel? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // Tạo yêu cầu sửa chữa mới kèm ảnh hiện trường và địa chỉ định vị
  Future<RepairRequestModel?> createRepairRequest({
    required String token,
    required String serviceCategoryId,
    required String title,
    required String description,
    String urgency = 'medium',
    DateTime? preferredTime,
    List<XFile> images = const [],
    String? address,
    double? latitude,
    double? longitude,
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
        preferredTime: preferredTime,
        images: images,
        address: address,
        latitude: latitude,
        longitude: longitude,
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

  // State danh sách yêu cầu của tôi (UC-REQ-07)
  List<RepairRequestModel> _myRequests = [];
  bool _isLoadingRequests = false;
  String? _requestsError;
  String _selectedStatusFilter = 'ALL';

  // Getters danh sách yêu cầu
  List<RepairRequestModel> get myRequests => _myRequests;
  bool get isLoadingRequests => _isLoadingRequests;
  String? get requestsError => _requestsError;
  String get selectedStatusFilter => _selectedStatusFilter;

  // Lọc theo trạng thái yêu cầu
  List<RepairRequestModel> get openRequests =>
      _myRequests.where((r) => r.status == 'OPEN').toList();

  List<RepairRequestModel> get quotedRequests =>
      _myRequests.where((r) => r.status == 'QUOTED').toList();

  List<RepairRequestModel> get acceptedRequests => _myRequests
      .where((r) =>
          r.status == 'ACCEPTED' ||
          r.status == 'ON_THE_WAY' ||
          r.status == 'ARRIVED' ||
          r.status == 'IN_PROGRESS')
      .toList();

  List<RepairRequestModel> get completedRequests =>
      _myRequests.where((r) => r.status == 'COMPLETED').toList();

  List<RepairRequestModel> get cancelledRequests =>
      _myRequests.where((r) => r.status == 'CANCELLED').toList();


  // Reset lỗi gửi yêu cầu
  void clearSubmitError() {
    _submitError = null;
    notifyListeners();
  }

  // Tải danh sách yêu cầu của tôi (UC-REQ-07)
  Future<void> fetchMyRequests({
    required String token,
    String? tab,
    String? status,
    bool refresh = false,
  }) async {
    if (_myRequests.isNotEmpty && !refresh && _isLoadingRequests) return;

    _isLoadingRequests = true;
    _requestsError = null;
    notifyListeners();

    try {
      final list = await _dataSource.getMyRepairRequests(
        token: token,
        tab: tab,
        status: status,
      );
      _myRequests = list;
      _isLoadingRequests = false;
      notifyListeners();
    } catch (e) {
      _isLoadingRequests = false;
      _requestsError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  // Đổi bộ lọc trạng thái
  void setStatusFilter(String filter) {
    _selectedStatusFilter = filter;
    notifyListeners();
  }

  // State hủy yêu cầu sửa chữa
  bool _isCancelling = false;
  String? _cancelError;

  bool get isCancelling => _isCancelling;
  String? get cancelError => _cancelError;

  // Hủy phiếu yêu cầu trước khi chốt thợ
  Future<bool> cancelRepairRequest({
    required String token,
    required String requestId,
    String? reason,
  }) async {
    _isCancelling = true;
    _cancelError = null;
    notifyListeners();

    try {
      final updated = await _dataSource.cancelRepairRequest(
        token: token,
        requestId: requestId,
        reason: reason,
      );

      final index = _myRequests.indexWhere((r) => r.id == requestId);
      if (index != -1) {
        _myRequests[index] = updated;
      }

      _isCancelling = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isCancelling = false;
      _cancelError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}

