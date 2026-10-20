import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/order_history/data/models/order_history_model.dart';
import 'package:frontend/features/order_history/presentation/screens/order_history_screen.dart';

/// Dịch vụ quản lý và bắn thông báo cục bộ khi đơn hàng đổi trạng thái (UC-NOT-01)
class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Lưu trữ trạng thái đơn hàng đã biết gần nhất để phát hiện thay đổi
  final Map<String, String> _knownStatuses = {};

  /// Hiển thị thông báo nổi (In-App Notification Banner) ở góc trên màn hình
  void showNotificationBanner({
    BuildContext? context,
    required String title,
    required String message,
    String status = 'SYSTEM',
    String? requestId,
  }) {
    final ctx = context ?? navigatorKey.currentContext;
    if (ctx == null) return;

    final overlay = Overlay.maybeOf(ctx);
    if (overlay == null) return;

    final iconData = _getStatusIcon(status);
    final statusColor = _getStatusColor(status);

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => _TopNotificationBanner(
        title: title,
        message: message,
        iconData: iconData,
        statusColor: statusColor,
        onTap: () {
          overlayEntry.remove();
          if (requestId != null) {
            Navigator.of(ctx).push(
              MaterialPageRoute(
                builder: (_) => const OrderHistoryScreen(),
              ),
            );
          }
        },
        onDismiss: () {
          overlayEntry.remove();
        },
      ),
    );

    overlay.insert(overlayEntry);

    // Tự động đóng thông báo sau 4 giây
    Future.delayed(const Duration(seconds: 4), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  /// Lắng nghe và so sánh trạng thái các đơn hàng, tự động bắn thông báo khi có thay đổi (UC-NOT-01)
  void detectStatusChanges(
    List<OrderHistoryModel> currentOrders, {
    BuildContext? context,
  }) {
    for (final order in currentOrders) {
      final prevStatus = _knownStatuses[order.id];

      // Nếu đơn hàng đã được ghi nhận trước đó và trạng thái có sự thay đổi
      if (prevStatus != null && prevStatus != order.status) {
        _triggerNotificationForStatus(order, order.status, context: context);
      }

      // Cập nhật trạng thái mới nhất
      _knownStatuses[order.id] = order.status;
    }
  }

  /// Khởi tạo trạng thái ban đầu mà không bắn thông báo
  void initializeKnownOrders(List<OrderHistoryModel> orders) {
    for (final order in orders) {
      _knownStatuses[order.id] = order.status;
    }
  }

  /// Kích hoạt thông báo tương ứng với trạng thái đơn hàng mới
  void _triggerNotificationForStatus(
    OrderHistoryModel order,
    String newStatus, {
    BuildContext? context,
  }) {
    String title;
    String message;

    switch (newStatus.toUpperCase()) {
      case 'ON_THE_WAY':
        title = 'Thợ đang trên đường đến! 🛵';
        message =
            'Thợ kỹ thuật đang di chuyển đến nhà bạn cho đơn "${order.title}". Vui lòng chuẩn bị và chú ý điện thoại.';
        break;
      case 'ARRIVED':
        title = 'Thợ đã có mặt! 📍';
        message =
            'Thợ kỹ thuật đã có mặt tại hiện trường cho đơn "${order.title}". Vui lòng đón tiếp thợ.';
        break;
      case 'IN_PROGRESS':
        title = 'Đang tiến hành sửa chữa 🔧';
        message =
            'Thợ đã có mặt tại hiện trường và bắt đầu sửa chữa sự cố "${order.title}".';
        break;
      case 'COMPLETED':
        title = 'Đơn sửa chữa đã hoàn tất! 🎉';
        message =
            'Yêu cầu "${order.title}" đã được hoàn thành. Hãy kiểm tra nghiệm thu và đánh giá thợ.';
        break;
      case 'CANCELLED':
        title = 'Đơn yêu cầu đã bị hủy ❌';
        message = 'Yêu cầu sửa chữa "${order.title}" đã chuyển sang trạng thái đã hủy.';
        break;
      case 'QUOTED':
        title = 'Có báo giá mới từ thợ! 💰';
        message =
            'Đơn "${order.title}" đã nhận được báo giá mới. Hãy vào kiểm tra và so sánh báo giá.';
        break;
      case 'ACCEPTED':
        title = 'Đã chốt thợ sửa chữa 🤝';
        message =
            'Đơn "${order.title}" đã được gán cho thợ kỹ thuật. Sẵn sàng cho lịch hẹn.';
        break;
      default:
        title = 'Cập nhật tiến độ đơn hàng 🔔';
        message = 'Đơn "${order.title}" vừa đổi sang trạng thái $newStatus.';
    }

    showNotificationBanner(
      context: context,
      title: title,
      message: message,
      status: newStatus,
      requestId: order.id,
    );
  }

  /// Hàm hỗ trợ test / demo bắn thông báo trạng thái đơn ngay lập tức (dành cho chấm điểm)
  void simulateStatusNotification(
    String status, {
    BuildContext? context,
    String? orderTitle,
  }) {
    final title = orderTitle ?? 'Sửa máy lạnh chảy nước';
    final dummyOrder = OrderHistoryModel(
      id: 'demo_123',
      title: title,
      description: 'Mô tả thử nghiệm',
      urgency: 'high',
      status: status,
      isReviewed: false,
      serviceCategoryName: 'Điện lạnh',
      serviceCategoryIcon: 'ac_unit',
      locationAddress: '123 Nguyễn Văn Cừ, Quận 5',
      createdAt: DateTime.now(),
    );

    _triggerNotificationForStatus(dummyOrder, status, context: context);
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'ON_THE_WAY':
        return Icons.moped_outlined;
      case 'ARRIVED':
        return Icons.place_outlined;
      case 'IN_PROGRESS':
        return Icons.build_outlined;
      case 'COMPLETED':
        return Icons.check_circle_outline;
      case 'CANCELLED':
        return Icons.cancel_outlined;
      case 'QUOTED':
        return Icons.request_quote_outlined;
      case 'ACCEPTED':
        return Icons.handshake_outlined;
      default:
        return Icons.notifications_active_outlined;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ON_THE_WAY':
        return Colors.orange;
      case 'ARRIVED':
        return Colors.amber.shade800;
      case 'IN_PROGRESS':
        return Colors.blue;
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      case 'QUOTED':
        return Colors.teal;
      case 'ACCEPTED':
        return Colors.purple;
      default:
        return AppTheme.primaryColor;
    }
  }
}

/// Widget thanh thông báo nổi từ cạnh trên màn hình (Floating Banner)
class _TopNotificationBanner extends StatefulWidget {
  final String title;
  final String message;
  final IconData iconData;
  final Color statusColor;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _TopNotificationBanner({
    required this.title,
    required this.message,
    required this.iconData,
    required this.statusColor,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_TopNotificationBanner> createState() => _TopNotificationBannerState();
}

class _TopNotificationBannerState extends State<_TopNotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    ));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _animController.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 8,
      left: 12,
      right: 12,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              if (details.primaryDelta != null && details.primaryDelta! < -5) {
                _dismiss();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: widget.statusColor.withValues(alpha: 0.3),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: widget.statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        widget.iconData,
                        color: widget.statusColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.message,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondaryColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Xem',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
