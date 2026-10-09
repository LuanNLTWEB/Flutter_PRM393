import 'package:flutter/material.dart';
import '../../data/datasources/order_history_remote_datasource.dart';
import '../../data/models/order_history_model.dart';

class OrderHistoryProvider extends ChangeNotifier {
  final OrderHistoryRemoteDataSource _dataSource;

  OrderHistoryProvider({OrderHistoryRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? OrderHistoryRemoteDataSource();

  List<OrderHistoryModel> _orders = [];
  Map<String, dynamic> _counts = {};
  bool _isLoading = false;
  bool _isSeeding = false;
  String? _errorMessage;
  String? _successMessage;
  String _currentTab = 'ALL';

  List<OrderHistoryModel> get orders => _orders;
  Map<String, dynamic> get counts => _counts;
  bool get isLoading => _isLoading;
  bool get isSeeding => _isSeeding;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String get currentTab => _currentTab;

  /// Tải danh sách đơn hàng theo tab
  Future<void> fetchOrders(String token, {String tab = 'ALL'}) async {
    _isLoading = true;
    _errorMessage = null;
    _currentTab = tab;
    notifyListeners();

    try {
      final result = await _dataSource.getMyOrders(
        token: token,
        tab: tab == 'ALL' ? null : tab,
      );

      _orders = result['orders'] as List<OrderHistoryModel>? ?? [];
      _counts = result['counts'] as Map<String, dynamic>? ?? {};
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  /// Tạo đơn hàng hoàn tất mẫu để thử nghiệm đánh giá
  Future<bool> seedDemoOrder(String token) async {
    _isSeeding = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final newOrder = await _dataSource.seedDemoCompletedOrder(token: token);
      _orders.insert(0, newOrder);
      _isSeeding = false;
      _successMessage = 'Đã tạo thành công đơn hàng hoàn tất mẫu để bạn đánh giá!';
      notifyListeners();
      return true;
    } catch (e) {
      _isSeeding = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Cập nhật trạng thái đã đánh giá trên danh sách cục bộ
  void markOrderReviewed(String orderId) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final old = _orders[index];
      _orders[index] = OrderHistoryModel(
        id: old.id,
        title: old.title,
        description: old.description,
        urgency: old.urgency,
        status: old.status,
        isReviewed: true,
        serviceCategoryName: old.serviceCategoryName,
        serviceCategoryIcon: old.serviceCategoryIcon,
        assignedTechnicianId: old.assignedTechnicianId,
        assignedTechnicianName: old.assignedTechnicianName,
        assignedTechnicianRating: old.assignedTechnicianRating,
        createdAt: old.createdAt,
        locationAddress: old.locationAddress,
      );
      notifyListeners();
    }
  }

  void clearMessage() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
