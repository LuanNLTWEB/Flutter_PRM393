import 'package:flutter/material.dart';

import '../../data/datasources/order_history_remote_datasource.dart';
import '../../data/models/order_history_model.dart';

import 'package:frontend/features/notification/services/local_notification_service.dart';

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

      // UC-NOT-01: Tự động bắn thông báo khi phát hiện trạng thái đơn thay đổi
      LocalNotificationService.instance.detectStatusChanges(_orders);

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
        preferredTime: old.preferredTime,
        appointmentStatus: old.appointmentStatus,
        proposedTime: old.proposedTime,
        rescheduleNote: old.rescheduleNote,
        rescheduleRejectNote: old.rescheduleRejectNote,
      );
      notifyListeners();
    }
  }

  /// Khách đồng ý / từ chối khung giờ thợ đề xuất (UC-LIC-01)
  Future<bool> respondAppointment(
    String token,
    String orderId, {
    required String action, // 'accept' | 'reject'
    String reason = '',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _dataSource.respondAppointment(
        token: token,
        requestId: orderId,
        action: action,
        reason: reason,
      );

      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        final old = _orders[index];
        if (action == 'accept') {
          _orders[index] = OrderHistoryModel(
            id: old.id,
            title: old.title,
            description: old.description,
            urgency: old.urgency,
            status: old.status,
            isReviewed: old.isReviewed,
            serviceCategoryName: old.serviceCategoryName,
            serviceCategoryIcon: old.serviceCategoryIcon,
            assignedTechnicianId: old.assignedTechnicianId,
            assignedTechnicianName: old.assignedTechnicianName,
            assignedTechnicianRating: old.assignedTechnicianRating,
            createdAt: old.createdAt,
            locationAddress: old.locationAddress,
            preferredTime: old.proposedTime ?? old.preferredTime,
            appointmentStatus: 'CONFIRMED',
            proposedTime: null,
            rescheduleNote: '',
            rescheduleRejectNote: '',
          );
          _successMessage = 'Đã đồng ý khung giờ mới với thợ';
        } else {
          _orders[index] = OrderHistoryModel(
            id: old.id,
            title: old.title,
            description: old.description,
            urgency: old.urgency,
            status: old.status,
            isReviewed: old.isReviewed,
            serviceCategoryName: old.serviceCategoryName,
            serviceCategoryIcon: old.serviceCategoryIcon,
            assignedTechnicianId: old.assignedTechnicianId,
            assignedTechnicianName: old.assignedTechnicianName,
            assignedTechnicianRating: old.assignedTechnicianRating,
            createdAt: old.createdAt,
            locationAddress: old.locationAddress,
            preferredTime: old.preferredTime,
            appointmentStatus: 'PENDING',
            proposedTime: null,
            rescheduleNote: '',
            rescheduleRejectNote: reason.trim(),
          );
          _successMessage = 'Đã từ chối khung giờ mới';
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Khách báo hủy tại chỗ (UC-WRK-07)
  Future<bool> cancelOnsite(
    String token,
    String orderId, {
    required String reason,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _dataSource.cancelOnsite(
        token: token,
        requestId: orderId,
        reason: reason,
      );
      _successMessage = 'Đã báo hủy tại chỗ';
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearMessage() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
