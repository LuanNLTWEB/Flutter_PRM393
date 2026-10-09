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
  String? _errorMessage;
  String? _successMessage;
  String _currentTab = 'ALL';

  List<OrderHistoryModel> get orders => _orders;
  Map<String, dynamic> get counts => _counts;
  bool get isLoading => _isLoading;
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
