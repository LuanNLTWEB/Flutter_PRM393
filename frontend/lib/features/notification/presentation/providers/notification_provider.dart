import 'package:flutter/material.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../data/models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRemoteDataSource _dataSource;

  NotificationProvider({NotificationRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? NotificationRemoteDataSource();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _errorMessage;

  String? _filterType;
  bool _filterUnreadOnly = false;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get filterType => _filterType;
  bool get filterUnreadOnly => _filterUnreadOnly;

  List<NotificationModel> get filteredNotifications {
    return _notifications.where((n) {
      if (_filterUnreadOnly && n.isRead) {
        return false;
      }
      if (_filterType != null && _filterType!.isNotEmpty && n.type != _filterType) {
        return false;
      }
      return true;
    }).toList();
  }

  void setFilterType(String? type) {
    _filterType = type;
    notifyListeners();
  }

  void setFilterUnreadOnly(bool unreadOnly) {
    _filterUnreadOnly = unreadOnly;
    notifyListeners();
  }

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Lấy danh sách thông báo
  Future<void> fetchNotifications(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _dataSource.getNotifications(token, limit: 50);
      _notifications = res['notifications'] as List<NotificationModel>;
      _unreadCount = res['unreadCount'] as int;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Lấy nhanh số lượng chưa đọc (ví dụ dùng cho badge trên AppBar)
  Future<void> fetchUnreadCount(String token) async {
    try {
      _unreadCount = await _dataSource.getUnreadCount(token);
      notifyListeners();
    } catch (_) {
      // Bỏ qua lỗi ngầm khi đếm badge
    }
  }

  /// Đánh dấu một thông báo đã đọc
  Future<bool> markAsRead(String token, String id) async {
    try {
      final updated = await _dataSource.markAsRead(token, id);
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        if (!_notifications[index].isRead && _unreadCount > 0) {
          _unreadCount--;
        }
        _notifications[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Đánh dấu tất cả là đã đọc
  Future<bool> markAllAsRead(String token) async {
    try {
      await _dataSource.markAllAsRead(token);
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true, readAt: DateTime.now()))
          .toList();
      _unreadCount = 0;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Xóa một thông báo
  Future<bool> deleteNotification(String token, String id) async {
    try {
      await _dataSource.deleteNotification(token, id);
      final item = _notifications.firstWhere(
        (n) => n.id == id,
        orElse: () => NotificationModel(
          id: '',
          title: '',
          message: '',
          createdAt: DateTime.now(),
        ),
      );
      if (!item.isRead && _unreadCount > 0) {
        _unreadCount--;
      }
      _notifications.removeWhere((n) => n.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Xóa toàn bộ thông báo
  Future<bool> clearAll(String token) async {
    try {
      await _dataSource.clearAllNotifications(token);
      _notifications.clear();
      _unreadCount = 0;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
