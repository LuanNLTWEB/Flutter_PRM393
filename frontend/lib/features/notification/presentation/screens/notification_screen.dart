import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/notification_model.dart';
import '../providers/notification_provider.dart';
import 'package:frontend/features/notification/services/local_notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
  }

  void _loadNotifications() {
    final token = context.read<AuthProvider>().token;
    if (token != null && token.isNotEmpty) {
      context.read<NotificationProvider>().fetchNotifications(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final token = context.watch<AuthProvider>().token ?? '';
    final unreadCount = provider.unreadCount;
    final notifications = provider.filteredNotifications;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Trung tâm thông báo'),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        centerTitle: true,
        actions: [
          if (provider.notifications.isNotEmpty)
            PopupMenuButton<String>(
              tooltip: 'Tùy chọn',
              onSelected: (value) {
                if (value == 'read_all') {
                  _markAllRead(context, token);
                } else if (value == 'clear_all') {
                  _confirmClearAll(context, token);
                } else if (value == 'demo_status') {
                  _showDemoStatusDialog(context);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'demo_status',
                  child: Row(
                    children: [
                      Icon(Icons.moped_outlined, color: Colors.orange, size: 20),
                      SizedBox(width: 10),
                      Text('Thử nghiệm bắn thông báo (UC-NOT-01)'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'read_all',
                  child: Row(
                    children: [
                      Icon(Icons.done_all, color: Colors.blue, size: 20),
                      SizedBox(width: 10),
                      Text('Đọc tất cả'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep_outlined, color: Colors.red, size: 20),
                      SizedBox(width: 10),
                      Text('Xóa tất cả'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Thanh bộ lọc nhanh
          _buildFilterBar(provider),

          // Danh sách thông báo
          Expanded(
            child: provider.isLoading && provider.notifications.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () async => _loadNotifications(),
                    child: notifications.isEmpty
                        ? _buildEmptyState(provider)
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                            itemCount: notifications.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (ctx, index) {
                              final item = notifications[index];
                              return _buildNotificationCard(
                                context,
                                item,
                                token,
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(NotificationProvider provider) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Lọc Tất cả vs Chưa đọc
            FilterChip(
              selected: !provider.filterUnreadOnly && provider.filterType == null,
              label: const Text('Tất cả'),
              onSelected: (_) {
                provider.setFilterUnreadOnly(false);
                provider.setFilterType(null);
              },
            ),
            const SizedBox(width: 8),
            FilterChip(
              selected: provider.filterUnreadOnly,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Chưa đọc'),
                  if (provider.unreadCount > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${provider.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              onSelected: (val) {
                provider.setFilterUnreadOnly(val);
              },
            ),
            const SizedBox(width: 8),
            FilterChip(
              selected: provider.filterType == 'ORDER_STATUS',
              label: const Text('Đơn sửa chữa'),
              avatar: const Icon(Icons.local_shipping_outlined, size: 16),
              onSelected: (val) {
                provider.setFilterType(val ? 'ORDER_STATUS' : null);
              },
            ),
            const SizedBox(width: 8),
            FilterChip(
              selected: provider.filterType == 'QUOTATION',
              label: const Text('Báo giá'),
              avatar: const Icon(Icons.request_quote_outlined, size: 16),
              onSelected: (val) {
                provider.setFilterType(val ? 'QUOTATION' : null);
              },
            ),
            const SizedBox(width: 8),
            FilterChip(
              selected: provider.filterType == 'KYC',
              label: const Text('Xét duyệt'),
              avatar: const Icon(Icons.verified_user_outlined, size: 16),
              onSelected: (val) {
                provider.setFilterType(val ? 'KYC' : null);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(NotificationProvider provider) {
    final isFiltered = provider.filterUnreadOnly || provider.filterType != null;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: 400,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFiltered
                  ? Icons.filter_alt_off_outlined
                  : Icons.notifications_off_outlined,
              size: 72,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              isFiltered
                  ? 'Không tìm thấy thông báo thỏa điều kiện lọc'
                  : 'Hộp thư thông báo của bạn đang trống',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              isFiltered
                  ? 'Thử đổi sang bộ lọc "Tất cả" để xem các tin khác.'
                  : 'Các cập nhật về đơn hàng, báo giá và tài khoản sẽ hiển thị ở đây.',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (isFiltered) ...[
              const SizedBox(height: 14),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.clear_all),
                label: const Text('Xem tất cả thông báo'),
                onPressed: () {
                  provider.setFilterUnreadOnly(false);
                  provider.setFilterType(null);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    NotificationModel item,
    String token,
  ) {
    final isUnread = !item.isRead;

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (_) {
        context.read<NotificationProvider>().deleteNotification(token, item.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa 1 thông báo'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isUnread
                ? AppTheme.primaryColor.withValues(alpha: 0.3)
                : Colors.grey.shade200,
            width: isUnread ? 1.2 : 1,
          ),
        ),
        color: isUnread
            ? AppTheme.primaryColor.withValues(alpha: 0.04)
            : Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (isUnread) {
              context.read<NotificationProvider>().markAsRead(token, item.id);
            }
            _showNotificationDetail(context, item);
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon loại thông báo
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: item.typeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.iconData, color: item.typeColor, size: 22),
                ),
                const SizedBox(width: 12),

                // Nội dung thông báo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: item.typeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.typeDisplay,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: item.typeColor,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            item.timeAgo,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          if (isUnread) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isUnread ? FontWeight.bold : FontWeight.w600,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.message,
                        style: TextStyle(
                          fontSize: 12,
                          color: isUnread
                              ? AppTheme.textPrimaryColor
                              : AppTheme.textSecondaryColor,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNotificationDetail(BuildContext context, NotificationModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.typeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.iconData, color: item.typeColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.typeDisplay,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: item.typeColor,
                        ),
                      ),
                      Text(
                        item.timeAgo,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.message,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đóng'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _markAllRead(BuildContext context, String token) async {
    final success =
        await context.read<NotificationProvider>().markAllAsRead(token);
    if (context.mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã đánh dấu tất cả thông báo là đã đọc!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _confirmClearAll(BuildContext context, String token) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa tất cả'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa toàn bộ lịch sử thông báo không?\nThao tác này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final success =
                  await context.read<NotificationProvider>().clearAll(token);
              if (context.mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã xóa tất cả thông báo!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );
  }

  void _showDemoStatusDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Thử Nghiệm Bắn Thông Báo (UC-NOT-01)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Chọn trạng thái đơn hàng để kích hoạt thông báo nổi trên màn hình:',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                child: Icon(Icons.moped),
              ),
              title: const Text('Thợ đang trên đường đến (ON_THE_WAY)'),
              subtitle: const Text('Bắn thông báo thợ bắt đầu di chuyển tới nhà'),
              onTap: () {
                Navigator.pop(ctx);
                LocalNotificationService.instance.simulateStatusNotification(
                  'ON_THE_WAY',
                  context: context,
                );
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
                child: Icon(Icons.place),
              ),
              title: const Text('Thợ đã có mặt (ARRIVED)'),
              subtitle: const Text('Bắn thông báo thợ đã đến hiện trường'),
              onTap: () {
                Navigator.pop(ctx);
                LocalNotificationService.instance.simulateStatusNotification(
                  'ARRIVED',
                  context: context,
                );
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                child: Icon(Icons.build),
              ),
              title: const Text('Đang sửa chữa (IN_PROGRESS)'),
              subtitle: const Text('Thợ đã đến nơi và bắt đầu công việc'),
              onTap: () {
                Navigator.pop(ctx);
                LocalNotificationService.instance.simulateStatusNotification(
                  'IN_PROGRESS',
                  context: context,
                );
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                child: Icon(Icons.check_circle),
              ),
              title: const Text('Đã hoàn thành sửa chữa (COMPLETED)'),
              subtitle: const Text('Sửa xong, nghiệm thu & đánh giá'),
              onTap: () {
                Navigator.pop(ctx);
                LocalNotificationService.instance.simulateStatusNotification(
                  'COMPLETED',
                  context: context,
                );
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                child: Icon(Icons.request_quote),
              ),
              title: const Text('Có báo giá mới (QUOTED)'),
              subtitle: const Text('Thợ gửi báo giá tiền công & linh kiện'),
              onTap: () {
                Navigator.pop(ctx);
                LocalNotificationService.instance.simulateStatusNotification(
                  'QUOTED',
                  context: context,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
