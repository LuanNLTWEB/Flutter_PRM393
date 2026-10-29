import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/directions.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../review/presentation/screens/create_review_screen.dart';
import '../../../review/presentation/screens/technician_reviews_screen.dart';
import '../../../quotations/presentation/providers/quotation_provider.dart';
import '../../../quotations/presentation/screens/request_quotations_screen.dart';
import '../../../quotations/presentation/widgets/quotation_format.dart';
import '../../../repair_request/data/models/repair_request_model.dart';
import '../../../repair_request/presentation/widgets/schedule_time_slot_picker.dart';
import '../../data/models/order_history_model.dart';
import 'order_detail_screen.dart';
import '../providers/order_history_provider.dart';
import '../../../repair_request/presentation/screens/service_category_screen.dart';
import '../../../invoice/presentation/screens/invoices_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  late final List<String> _tabs;
  late final List<String> _tabLabels;

  @override
  void initState() {
    super.initState();
    final isCustomer = context.read<AuthProvider>().currentUser?.role == 'user';
    _tabs = isCustomer
        ? ['ALL', 'OPEN', 'QUOTED', 'ACCEPTED', 'COMPLETED', 'CANCELLED']
        : ['ALL', 'PROCESSING', 'COMPLETED', 'CANCELLED'];
    _tabLabels = isCustomer
        ? [
            'Tất cả',
            'Chờ báo giá',
            'Đã báo giá',
            'Đã chốt thợ',
            'Đã hoàn tất',
            'Đã hủy',
          ]
        : ['Tất cả', 'Đang xử lý', 'Đã hoàn tất', 'Đã hủy'];
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _fetchCurrentTabOrders();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCurrentTabOrders();
    });
  }

  void _fetchCurrentTabOrders() {
    final token = context.read<AuthProvider>().token;
    if (token != null) {
      final tab = _tabs[_tabController.index];
      context.read<OrderHistoryProvider>().fetchOrders(token, tab: tab);
    }
  }

  List<OrderHistoryModel> _ordersForCurrentTab(List<OrderHistoryModel> orders) {
    final tab = _tabs[_tabController.index];
    switch (tab) {
      case 'OPEN':
        return orders.where((order) => order.status == 'OPEN').toList();
      case 'QUOTED':
        return orders.where((order) => order.status == 'QUOTED').toList();
      case 'ACCEPTED':
        return orders
            .where(
              (order) => const [
                'ACCEPTED',
                'ON_THE_WAY',
                'ARRIVED',
                'IN_PROGRESS',
              ].contains(order.status),
            )
            .toList();
      case 'COMPLETED':
        return orders.where((order) => order.status == 'COMPLETED').toList();
      case 'CANCELLED':
        return orders.where((order) => order.status == 'CANCELLED').toList();
      default:
        return orders;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return Colors.green.shade700;
      case 'CANCELLED':
        return Colors.red.shade700;
      case 'IN_PROGRESS':
        return Colors.blue.shade700;
      case 'ON_THE_WAY':
        return Colors.teal.shade700;
      case 'ARRIVED':
        return Colors.amber.shade800;
      case 'ACCEPTED':
        return Colors.teal.shade700;
      default:
        return Colors.orange.shade800;
    }
  }

  Widget _buildTimeRow({
    required IconData icon,
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: highlight ? Colors.orange.shade800 : Colors.grey.shade600,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: highlight
                ? Colors.orange.shade900
                : AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: highlight
                ? Colors.orange.shade900
                : AppTheme.textPrimaryColor,
          ),
        ),
      ],
    );
  }

  Future<void> _respondAppointment(
    OrderHistoryModel order,
    String action,
  ) async {
    final isAccept = action == 'accept';
    final reasonController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isAccept ? 'Đồng ý khung giờ mới?' : 'Giữ nguyên giờ cũ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAccept
                  ? 'Bạn đồng ý với thợ vào ${order.proposedTime != null ? DateFormat('dd/MM/yyyy HH:mm').format(order.proposedTime!) : 'khung giờ mới'}?'
                  : 'Thợ sẽ phải đề xuất khung giờ khác. Giờ hẹn cũ được giữ nguyên.',
            ),
            if (!isAccept) ...[
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLength: 300,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Lý do từ chối (không bắt buộc)',
                  hintText: 'VD: Khung giờ đó tôi đi làm chưa về',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isAccept
                  ? Colors.green.shade600
                  : Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isAccept ? 'Đồng ý' : 'Từ chối'),
          ),
        ],
      ),
    );
    if (result != true || !mounted) {
      reasonController.dispose();
      return;
    }
    // Lưu lý do rồi dispose ngay để không rò controller
    final reason = isAccept ? '' : reasonController.text.trim();
    reasonController.dispose();

    final token = context.read<AuthProvider>().token ?? '';
    final prov = context.read<OrderHistoryProvider>();
    final ok = await prov.respondAppointment(
      token,
      order.id,
      action: action,
      reason: reason,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (prov.successMessage ?? 'Phản hồi thành công')
              : (prov.errorMessage ?? 'Phản hồi thất bại'),
        ),
        backgroundColor: ok ? Colors.green.shade700 : Colors.red.shade600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyProv = context.watch<OrderHistoryProvider>();
    final visibleOrders = _ordersForCurrentTab(historyProv.orders);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử đơn hàng'),

        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondaryColor,
          indicatorColor: AppTheme.primaryColor,
          indicatorWeight: 3,
          tabs: _tabLabels.map((label) => Tab(text: label)).toList(),
        ),
      ),
      body: historyProv.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _fetchCurrentTabOrders(),
              child: visibleOrders.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.separated(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: visibleOrders.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final order = visibleOrders[index];
                        return _buildOrderCard(context, order, historyProv);
                      },
                    ),
            ),
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    OrderHistoryModel order,
    OrderHistoryProvider historyProv,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final formattedDate = order.createdAt != null
        ? dateFormat.format(order.createdAt!)
        : '';
    final statusColor = _getStatusColor(order.status);
    // Nút phản hồi lịch hẹn là nghiệp vụ riêng của Khách hàng (authorize('user'))
    final isCustomer =
        context.read<AuthProvider>().currentUser?.role == 'user';

    // Bấm vào card → xem chi tiết đơn hàng (nơi có phần phê duyệt chi phí)
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
        );
        // Tải lại danh sách để phản ánh trạng thái chi phí sau khi duyệt
        if (!context.mounted) return;
        final token = context.read<AuthProvider>().token ?? '';
        if (token.isNotEmpty) {
          final tab = _tabs[_tabController.index];
          context.read<OrderHistoryProvider>().fetchOrders(token, tab: tab);
        }
      },
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dòng tiêu đề & Trạng thái
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      order.serviceCategoryName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      order.statusDisplay,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Tiêu đề sự cố
              Text(
                order.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 4),

              // Mô tả triệu chứng
              if (order.description.isNotEmpty) ...[
                Text(
                  order.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Địa chỉ & Thời gian
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.locationAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ),
                  if (formattedDate.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Thông tin Thợ kỹ thuật phụ trách
              if (order.assignedTechnicianId != null) ...[
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.primaryColor.withValues(
                        alpha: 0.1,
                      ),
                      child: const Icon(
                        Icons.engineering_rounded,
                        color: AppTheme.primaryColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.assignedTechnicianName ?? 'Thợ sửa chữa',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          if (order.assignedTechnicianRating != null)
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Colors.amber,
                                  size: 14,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${order.assignedTechnicianRating!.toStringAsFixed(1)} ⭐',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // KHU VỰC THAO TÁC ĐÁNH GIÁ (CHUẨN NGHIỆP VỤ UC-RAT-01)
              if (order.isCompleted && order.assignedTechnicianId != null) ...[
                if (context.read<AuthProvider>().currentUser?.role ==
                    'user') ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: const BorderSide(color: AppTheme.primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.receipt_long_outlined, size: 18),
                      label: const Text('Xem hóa đơn (có thể xem offline)'),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const InvoicesScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (!order.isReviewed) ...[
                  // Chưa đánh giá: Hiện nút vàng nổi bật để khách đánh giá thợ
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.star_rounded, size: 20),
                      label: const Text(
                        'Đánh giá thợ kỹ thuật',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () async {
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateReviewScreen(
                              technicianId: order.assignedTechnicianId!,
                              technicianName:
                                  order.assignedTechnicianName ??
                                  'Thợ kỹ thuật',
                              bookingId: order.id,
                            ),
                          ),
                        );

                        if (result == true) {
                          historyProv.markOrderReviewed(order.id);
                        }
                      },
                    ),
                  ),
                ] else ...[
                  // Đã đánh giá: Hiện nút xem lại đánh giá
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: const BorderSide(color: AppTheme.primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.rate_review_outlined, size: 18),
                      label: const Text('Xem & chỉnh sửa đánh giá'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TechnicianReviewsScreen(
                              technicianId: order.assignedTechnicianId!,
                              technicianName:
                                  order.assignedTechnicianName ??
                                  'Thợ kỹ thuật',
                              bookingId: order.id,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ] else if (!order.isCompleted) ...[
                // Đơn OPEN/QUOTED: cho phép khách xem báo giá & chọn thợ (UC-QUO-06/08)
                if (order.status == 'OPEN' || order.status == 'QUOTED') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.request_quote_outlined, size: 18),
                      label: Text(
                        order.status == 'QUOTED'
                            ? 'Xem báo giá & chọn thợ'
                            : 'Theo dõi báo giá',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                RequestQuotationsScreen(requestId: order.id),
                          ),
                        );
                        // Tải lại để cập nhật trạng thái (đã chốt thợ / hủy...)
                        if (context.mounted) _fetchCurrentTabOrders();
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                // Đơn ACCEPTED/ON_THE_WAY/IN_PROGRESS: hiển thị thông tin lịch hẹn
                if (order.status == 'ACCEPTED' ||
                    order.status == 'ON_THE_WAY' ||
                    order.status == 'ARRIVED' ||
                    order.status == 'IN_PROGRESS') ...[
                  if (order.status == 'ON_THE_WAY') ...[
                    // Thợ đang trên đường đến nhà khách (UC-WRK-01)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.teal.shade400),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.navigation,
                            size: 18,
                            color: Colors.teal.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              order.preferredTime != null
                                  ? 'Thợ đang trên đường đến (lịch hẹn ${dateFormat.format(order.preferredTime!)})'
                                  : 'Thợ đang trên đường đến nhà khách',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (order.appointmentStatus == 'RESCHEDULED') ...[
                    // Thợ đề xuất khung giờ mới — khách phản hồi (UC-SCH-02)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.swap_horiz,
                                size: 16,
                                color: Colors.orange.shade800,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Thợ đề xuất đổi lịch hẹn',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildTimeRow(
                            icon: Icons.schedule,
                            label: 'Giờ cũ:',
                            value: order.preferredTime != null
                                ? dateFormat.format(order.preferredTime!)
                                : 'Không rõ',
                          ),
                          const SizedBox(height: 4),
                          _buildTimeRow(
                            icon: Icons.event_available,
                            label: 'Giờ mới thợ đề xuất:',
                            value: order.proposedTime != null
                                ? dateFormat.format(order.proposedTime!)
                                : 'Không rõ',
                            highlight: true,
                          ),
                          if (order.rescheduleNote.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Lý do: ${order.rescheduleNote}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          // Chỉ Khách hàng mới phản hồi được (backend authorize('user'))
                          if (isCustomer) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red.shade700,
                                      side: BorderSide(
                                        color: Colors.red.shade300,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    icon: const Icon(Icons.close, size: 16),
                                    label: const Text(
                                      'Giữ giờ cũ',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    onPressed: () =>
                                        _respondAppointment(order, 'reject'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade600,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    icon: const Icon(Icons.check, size: 16),
                                    label: const Text(
                                      'Đồng ý giờ mới',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    onPressed: () =>
                                        _respondAppointment(order, 'accept'),
                                  ),
                                ),
                              ],
                            ),
                          ] else
                            // Thợ xem read-only — chờ khách phản hồi,
                            // thao tác của thợ nằm ngay dưới card này
                            Text(
                              'Đang chờ khách phản hồi khung giờ bạn đề xuất.',
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ] else if (order.status == 'ARRIVED') ...[
                    // Thợ đã có mặt, chờ bắt đầu sửa chữa (UC-ARR-01)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade400),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.place_outlined,
                            size: 18,
                            color: Colors.amber.shade800,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              order.preferredTime != null
                                  ? 'Thợ đã có mặt (lịch hẹn ${dateFormat.format(order.preferredTime!)}) — sắp bắt đầu sửa chữa'
                                  : 'Thợ đã có mặt tại hiện trường — sắp bắt đầu sửa chữa',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (order.status == 'IN_PROGRESS') ...[
                    // Thợ đã có mặt và đang sửa chữa (UC-ARR-01)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.indigo.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.home_repair_service_outlined,
                            size: 18,
                            color: Colors.indigo.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              order.preferredTime != null
                                  ? 'Thợ đã có mặt và đang sửa chữa (lịch hẹn ${dateFormat.format(order.preferredTime!)})'
                                  : 'Thợ đã có mặt và đang sửa chữa tại hiện trường',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (order.appointmentStatus == 'CONFIRMED') ...[
                    // Thợ ĐÃ xác nhận — xanh lá, icon tick, chữ đậm
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade400),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 18,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Lịch hẹn ${order.preferredTime != null ? dateFormat.format(order.preferredTime!) : ''} — THỢ ĐÃ XÁC NHẬN',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Chờ thợ xác nhận — xanh dương nhạt, icon đồng hồ cát
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.shade300,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.hourglass_top,
                            size: 16,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Đã chốt thợ — CHỜ THỢ XÁC NHẬN lịch hẹn',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ] else if (order.status == 'CANCELLED') ...[
                  // Đơn đã hủy — ghi chú riêng, không hiển thị nhầm "đang tiến trình"
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.cancel_outlined,
                          size: 16,
                          color: Colors.red.shade700,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Đơn hàng đã bị hủy.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (order.status != 'OPEN' &&
                    order.status != 'QUOTED') ...[
                  // Đơn chưa hoàn tất khác: Hiển thị ghi chú trạng thái
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.grey),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Đơn hàng đang trong tiến trình sửa chữa, bạn có thể đánh giá sau khi hoàn tất nghiệm thu.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
              // KHU HÀNH ĐỘNG CỦA THỢ trên card "Đang xử lý"
              // (UC-SCH-02, UC-WRK-01/02/04/05/07) — chỉ thợ được chốt thấy
              if (!isCustomer &&
                  const [
                    'ACCEPTED',
                    'ON_THE_WAY',
                    'ARRIVED',
                    'IN_PROGRESS',
                  ].contains(order.status)) ...[
                const SizedBox(height: 12),
                _buildTechnicianActions(context, order),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Khu hành động của Thợ: xác nhận / đổi lịch hẹn (UC-SCH-02), đang trên
  /// đường (UC-WRK-01), chỉ đường (UC-WRK-02), bắt đầu sửa chữa (UC-WRK-04),
  /// khai báo chi phí (UC-WRK-05), báo hủy tại chỗ (UC-WRK-07).
  Widget _buildTechnicianActions(BuildContext context, OrderHistoryModel order) {
    final quoteProv = context.watch<QuotationProvider>();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final isPreferredTimePast =
        order.preferredTime != null &&
        order.preferredTime!.isBefore(DateTime.now());

    // Nút chỉ đường tới nhà khách (UC-WRK-02)
    Widget directionsButton() {
      final hasDestination =
          order.locationAddress.trim().isNotEmpty ||
          (order.latitude != null && order.longitude != null);
      if (!hasDestination) return const SizedBox.shrink();
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryColor,
            side: BorderSide(
              color: AppTheme.primaryColor.withValues(alpha: 0.5),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(Icons.navigation_outlined, size: 16),
          label: const Text(
            'Chỉ đường tới khách bằng Google Maps',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
          onPressed: () => _openDirections(order),
        ),
      );
    }

    // Khu lịch hẹn — chỉ khi đơn mới được chốt & chưa xác nhận (UC-SCH-02)
    if (order.status == 'ACCEPTED' &&
        order.appointmentStatus != 'CONFIRMED') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.event_available_outlined,
                  size: 16,
                  color: Colors.blue,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Lịch hẹn',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    order.appointmentStatus == 'RESCHEDULED'
                        ? 'Đã đề xuất giờ mới'
                        : 'Chờ xác nhận',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (order.preferredTime != null)
              Text(
                'Giờ khách đề xuất: ${dateFormat.format(order.preferredTime!)}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              )
            else
              const Text(
                'Khách chưa chọn giờ hẹn',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            if (order.appointmentStatus == 'RESCHEDULED' &&
                order.proposedTime != null) ...[
              const SizedBox(height: 4),
              Text(
                'Đề xuất của bạn: ${dateFormat.format(order.proposedTime!)}',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade800,
                ),
              ),
              if (order.rescheduleNote.isNotEmpty)
                Text(
                  'Lý do: ${order.rescheduleNote}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
            ],
            // Khách vừa từ chối khung giờ đề xuất — hiển thị lý do (nếu có)
            if (order.appointmentStatus == 'PENDING' &&
                order.rescheduleRejectNote.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: Text(
                  'Khách từ chối khung giờ bạn đề xuất: '
                  '${order.rescheduleRejectNote}',
                  style: TextStyle(fontSize: 11.5, color: Colors.red.shade800),
                ),
              ),
            ],
            const SizedBox(height: 10),
            // Giờ hẹn đã qua — chỉ cho phép đề xuất khung giờ mới
            if (isPreferredTimePast) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: Text(
                  'Giờ hẹn đã qua — hãy bấm "Đổi lịch hẹn" để đề xuất khung giờ mới.',
                  style: TextStyle(fontSize: 11.5, color: Colors.red.shade800),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (order.appointmentStatus == 'RESCHEDULED') ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.hourglass_top,
                      size: 14,
                      color: Colors.orange.shade800,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Đang chờ khách phản hồi khung giờ bạn đề xuất. '
                        'Bạn có thể đề xuất khung giờ khác nếu cần.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange.shade800,
                    side: BorderSide(color: Colors.orange.shade400),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.swap_horiz, size: 16),
                  label: const Text(
                    'Đề xuất khung giờ khác',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: quoteProv.isSubmitting
                      ? null
                      : () => _showRescheduleSheet(order),
                ),
              ),
            ] else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange.shade800,
                        side: BorderSide(color: Colors.orange.shade400),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.swap_horiz, size: 16),
                      label: const Text(
                        'Đổi lịch hẹn',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: quoteProv.isSubmitting
                          ? null
                          : () => _showRescheduleSheet(order),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text(
                        'Đồng ý giờ hẹn',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed:
                          (quoteProv.isSubmitting ||
                              order.preferredTime == null ||
                              isPreferredTimePast)
                          ? null
                          : () => _confirmAppointment(order),
                    ),
                  ),
                ],
              ),
          ],
        ),
      );
    }

    // Đơn đã tiến trình — bảng trạng thái + nút hành động tiếp theo
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (order.status == 'ACCEPTED') ...[
          // Lịch hẹn đã chốt — thợ bấm "Đang trên đường đến nhà khách" (UC-WRK-01)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.navigation, size: 16),
              label: const Text(
                'Đang trên đường đến nhà khách',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
              onPressed: quoteProv.isSubmitting
                  ? null
                  : () => _markOnTheWay(order),
            ),
          ),
        ] else if (order.status == 'ON_THE_WAY') ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade600,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.place_outlined, size: 16),
              label: const Text(
                'Đã có mặt tại hiện trường',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
              onPressed: quoteProv.isSubmitting
                  ? null
                  : () => _markArrived(order),
            ),
          ),
        ] else if (order.status == 'ARRIVED') ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade600,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.build_outlined, size: 16),
              label: const Text(
                'Bắt đầu sửa chữa',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
              onPressed: quoteProv.isSubmitting
                  ? null
                  : () => _markWorking(order),
            ),
          ),
        ] else if (order.status == 'IN_PROGRESS') ...[
          // Chi phí phát sinh đã khai báo (UC-WRK-05)
          if (order.additionalCosts.isNotEmpty) ...[
            ...order.additionalCosts.map(_buildCostTile),
            const SizedBox(height: 4),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange.shade800,
                side: BorderSide(color: Colors.orange.shade400),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.add_card_outlined, size: 16),
              label: const Text(
                'Khai báo chi phí phát sinh',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
              onPressed: quoteProv.isSubmitting
                  ? null
                  : () => _declareAdditionalCost(order),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade300),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: quoteProv.isSubmitting
                  ? null
                  : () => _cancelOnsite(order),
              child: const Text(
                'Báo hủy tại chỗ',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
        if (order.status != 'IN_PROGRESS') ...[
          const SizedBox(height: 8),
          directionsButton(),
        ],
      ],
    );
  }

  Widget _buildCostTile(AdditionalCostModel cost) {
    final Color borderColor;
    final Color statusColor;
    switch (cost.status) {
      case 'APPROVED':
        borderColor = Colors.green.shade300;
        statusColor = Colors.green.shade800;
        break;
      case 'REJECTED':
        borderColor = Colors.red.shade200;
        statusColor = Colors.red.shade700;
        break;
      case 'PENDING':
      default:
        borderColor = Colors.orange.shade300;
        statusColor = Colors.orange.shade900;
        break;
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${cost.name} x${cost.quantity}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Thành tiền: ${formatVnd(cost.total)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor),
            ),
            child: Text(
              cost.statusDisplay,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Mở Google Maps chỉ đường tới nhà khách (UC-WRK-02)
  Future<void> _openDirections(OrderHistoryModel order) async {
    final ok = await openGoogleMapsDirections(
      latitude: order.latitude,
      longitude: order.longitude,
      address: order.locationAddress,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không mở được Google Maps — chưa có địa chỉ khách'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Tải lại đơn của tab hiện tại + nút bấm đang disabled tới khi xong
  Future<bool> _runTechAction(
    Future<bool> Function() action, {
    required String fallbackSuccess,
    required String fallbackError,
    required Color successColor,
  }) async {
    final token = context.read<AuthProvider>().token ?? '';
    if (token.isEmpty) return false;

    final ok = await action();
    if (mounted) _fetchCurrentTabOrders();
    if (!mounted) return ok;

    final prov = context.read<QuotationProvider>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (prov.successMessage ?? fallbackSuccess)
              : (prov.errorMessage ?? fallbackError),
        ),
        backgroundColor: ok ? successColor : Colors.red.shade600,
      ),
    );
    return ok;
  }

  /// Thợ xác nhận giờ hẹn khách đề xuất (UC-SCH-02)
  Future<void> _confirmAppointment(OrderHistoryModel order) async {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đồng ý giờ hẹn?'),
        content: Text(
          order.preferredTime != null
              ? 'Bạn xác nhận sẽ đến nhà khách vào ${dateFormat.format(order.preferredTime!)}?'
              : 'Bạn xác nhận đồng ý với lịch hẹn này?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await _runTechAction(
      () => context.read<QuotationProvider>().confirmAppointment(
        token: context.read<AuthProvider>().token ?? '',
        requestId: order.id,
      ),
      fallbackSuccess: 'Xác nhận lịch hẹn thành công',
      fallbackError: 'Xác nhận lịch hẹn thất bại',
      successColor: Colors.green.shade700,
    );
  }

  /// Thợ bấm "Đang trên đường đến nhà khách" (UC-WRK-01)
  Future<void> _markOnTheWay(OrderHistoryModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Bắt đầu di chuyển?'),
        content: const Text(
          'Bạn xác nhận đang trên đường đến nhà khách? Khách sẽ thấy trạng thái mới của đơn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await _runTechAction(
      () => context.read<QuotationProvider>().markOnTheWay(
        token: context.read<AuthProvider>().token ?? '',
        requestId: order.id,
      ),
      fallbackSuccess: 'Đã cập nhật: đang trên đường đến nhà khách',
      fallbackError: 'Cập nhật trạng thái di chuyển thất bại',
      successColor: Colors.blue.shade700,
    );
  }

  /// Thợ bấm "Đã có mặt tại hiện trường" (UC-ARR-01)
  Future<void> _markArrived(OrderHistoryModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đã có mặt?'),
        content: const Text(
          'Bạn xác nhận đã có mặt tại nhà khách? Khách sẽ được thông báo và bạn có thể bắt đầu sửa chữa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo.shade600,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await _runTechAction(
      () => context.read<QuotationProvider>().markArrived(
        token: context.read<AuthProvider>().token ?? '',
        requestId: order.id,
      ),
      fallbackSuccess: 'Đã cập nhật: đã có mặt tại hiện trường',
      fallbackError: 'Cập nhật trạng thái đã có mặt thất bại',
      successColor: Colors.indigo.shade700,
    );
  }

  /// Thợ bấm "Bắt đầu sửa chữa" (UC-WRK-04)
  Future<void> _markWorking(OrderHistoryModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Bắt đầu sửa chữa?'),
        content: const Text(
          'Bạn xác nhận bắt đầu sửa chữa? Khách sẽ được thông báo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade600,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await _runTechAction(
      () => context.read<QuotationProvider>().markWorking(
        token: context.read<AuthProvider>().token ?? '',
        requestId: order.id,
      ),
      fallbackSuccess: 'Đã cập nhật: đang sửa chữa',
      fallbackError: 'Cập nhật trạng thái thất bại',
      successColor: Colors.teal.shade700,
    );
  }

  /// Thợ khai báo chi phí phát sinh — nhiều mục trong 1 lần (UC-WRK-05)
  Future<void> _declareAdditionalCost(OrderHistoryModel order) async {
    final token = context.read<AuthProvider>().token ?? '';
    if (token.isEmpty) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _DeclareCostDialog(),
    );
    if (result == null || !mounted) return;

    final items = (result['items'] as List).cast<Map<String, dynamic>>();
    final note = result['note'] as String? ?? '';
    await _runTechAction(
      () => context.read<QuotationProvider>().declareAdditionalCost(
        token: token,
        requestId: order.id,
        items: items,
        note: note,
      ),
      fallbackSuccess: 'Đã khai báo chi phí phát sinh',
      fallbackError: 'Khai báo chi phí thất bại',
      successColor: Colors.orange.shade700,
    );
  }

  /// Thợ báo hủy tại chỗ (UC-WRK-07)
  Future<void> _cancelOnsite(OrderHistoryModel order) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Báo hủy tại chỗ?'),
        content: TextField(
          controller: reasonController,
          autofocus: true,
          maxLength: 300,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Lý do hủy *',
            hintText: 'VD: Thiết bị hư hỏng quá nặng, cần kiểm tra thêm',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Để sau'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final value = reasonController.text.trim();
              if (value.length < 10) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Lý do phải có ít nhất 10 ký tự'),
                  ),
                );
                return;
              }
              Navigator.pop(dialogContext, value);
            },
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );
    reasonController.dispose();
    if (reason == null || !mounted) return;

    await _runTechAction(
      () => context.read<QuotationProvider>().cancelOnsite(
        token: context.read<AuthProvider>().token ?? '',
        requestId: order.id,
        reason: reason,
      ),
      fallbackSuccess: 'Đã báo hủy tại chỗ',
      fallbackError: 'Báo hủy tại chỗ thất bại',
      successColor: Colors.green.shade700,
    );
  }

  /// Thợ đề xuất khung giờ mới — bottom sheet chọn ngày/giờ (UC-SCH-02)
  Future<void> _showRescheduleSheet(OrderHistoryModel order) async {
    final token = context.read<AuthProvider>().token ?? '';
    if (token.isEmpty) return;

    DateTime? picked;
    final noteController = TextEditingController();

    final proposed = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.swap_horiz, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'Đề xuất khung giờ mới',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      order.preferredTime != null
                          ? 'Khách đề xuất: ${DateFormat('dd/MM/yyyy HH:mm').format(order.preferredTime!)}'
                          : 'Khách chưa chọn giờ hẹn',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ScheduleTimeSlotPicker(
                      onScheduleChanged: (schedule) =>
                          setSheetState(() => picked = schedule),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      maxLength: 300,
                      decoration: const InputDecoration(
                        labelText: 'Lý do đổi lịch (không bắt buộc)',
                        hintText:
                            'VD: Tôi bận khung giờ đó, đề xuất 14h cùng ngày',
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: picked == null
                            ? null
                            : () => Navigator.pop(sheetCtx, picked),
                        child: const Text(
                          'Gửi đề xuất',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (proposed == null || !mounted) {
      noteController.dispose();
      return;
    }
    // Lưu ghi chú rồi dispose ngay để không rò controller ở các nhánh return
    final note = noteController.text.trim();
    noteController.dispose();

    // Mirror validate backend: ≥15 phút, ≤14 ngày
    final now = DateTime.now();
    void showError(String message) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }

    if (!proposed.isAfter(now)) {
      showError('Khung giờ đề xuất phải ở tương lai');
      return;
    }
    if (proposed.isBefore(now.add(const Duration(minutes: 15)))) {
      showError('Khung giờ đề xuất cần cách hiện tại ít nhất 15 phút');
      return;
    }
    if (proposed.isAfter(now.add(const Duration(days: 14)))) {
      showError('Khung giờ đề xuất không được vượt quá 14 ngày');
      return;
    }

    await _runTechAction(
      () => context.read<QuotationProvider>().proposeAppointment(
        token: token,
        requestId: order.id,
        proposedTime: proposed,
        note: note,
      ),
      fallbackSuccess: 'Đề xuất khung giờ mới thành công',
      fallbackError: 'Đề xuất khung giờ mới thất bại',
      successColor: Colors.green.shade700,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa có đơn hàng nào trong mục này',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Các yêu cầu sửa chữa và dịch vụ bạn đã sử dụng sẽ được hiển thị và cập nhật liên tục tại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.handyman_outlined, size: 18),
              label: const Text('Xem danh mục dịch vụ'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: const BorderSide(color: AppTheme.primaryColor),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ServiceCategoryScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 1 dòng nhập phụ tùng trong dialog khai báo chi phí
class _CostDraftRow {
  final nameCtrl = TextEditingController();
  final qtyCtrl = TextEditingController();
  final priceCtrl = TextEditingController();

  void dispose() {
    nameCtrl.dispose();
    qtyCtrl.dispose();
    priceCtrl.dispose();
  }
}

/// Dialog khai báo nhiều hạng mục chi phí phát sinh trong 1 lần (UC-WRK-05)
/// Trả về `{'items': List<Map<String, dynamic>>, 'note': String}` hoặc null nếu hủy.
class _DeclareCostDialog extends StatefulWidget {
  const _DeclareCostDialog();

  @override
  State<_DeclareCostDialog> createState() => _DeclareCostDialogState();
}

class _DeclareCostDialogState extends State<_DeclareCostDialog> {
  static const int _maxRows = 20;

  final List<_CostDraftRow> _rows = [_CostDraftRow()];
  final TextEditingController _noteCtrl = TextEditingController();

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    _noteCtrl.dispose();
    super.dispose();
  }

  num get _total => _rows.fold<num>(0, (sum, row) {
    final qty = int.tryParse(row.qtyCtrl.text.trim()) ?? 0;
    final price = parseVndInput(row.priceCtrl.text) ?? 0;
    return sum + (qty > 0 ? price * qty : 0);
  });

  void _submit() {
    final items = <Map<String, dynamic>>[];
    for (var i = 0; i < _rows.length; i++) {
      final row = _rows[i];
      final name = row.nameCtrl.text.trim();
      final qty = int.tryParse(row.qtyCtrl.text.trim()) ?? 0;
      final price = parseVndInput(row.priceCtrl.text);
      if (name.isEmpty || qty < 1 || price == null || price <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Hạng mục ${i + 1}: vui lòng nhập tên, số lượng ≥ 1 và đơn giá hợp lệ',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      items.add({'name': name, 'quantity': qty, 'unitPrice': price});
    }
    Navigator.pop(context, {'items': items, 'note': _noteCtrl.text.trim()});
  }

  Widget _buildRow(int index) {
    final row = _rows[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(10, 6, 4, 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Hạng mục ${index + 1}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                icon: Icon(Icons.close, size: 18, color: Colors.red.shade400),
                tooltip: 'Xóa hạng mục',
                onPressed: _rows.length <= 1
                    ? null
                    : () {
                        setState(() {
                          _rows.removeAt(index).dispose();
                        });
                      },
              ),
            ],
          ),
          TextField(
            controller: row.nameCtrl,
            maxLength: 200,
            style: const TextStyle(fontSize: 13.5),
            decoration: const InputDecoration(
              labelText: 'Phụ tùng / hạng mục *',
              hintText: 'VD: Cụm van nước nóng',
              border: OutlineInputBorder(),
              isDense: true,
              counterText: '',
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 70,
                child: TextField(
                  controller: row.qtyCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 13.5),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'SL *',
                    hintText: 'VD: 1',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: row.priceCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 13.5),
                  inputFormatters: [const ThousandsSeparatorFormatter()],
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Đơn giá (₫) *',
                    hintText: 'VD: 250.000',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Khai báo chi phí phát sinh'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < _rows.length; i++) _buildRow(i),
              if (_rows.length < _maxRows)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _rows.add(_CostDraftRow())),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Thêm hạng mục'),
                  ),
                ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'Tổng cộng:',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatVnd(_total),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteCtrl,
                maxLength: 300,
                maxLines: 2,
                style: const TextStyle(fontSize: 13.5),
                decoration: const InputDecoration(
                  labelText: 'Ghi chú chung (tùy chọn)',
                  border: OutlineInputBorder(),
                  isDense: true,
                  counterText: '',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.shade700,
            foregroundColor: Colors.white,
          ),
          onPressed: _submit,
          child: Text('Gửi khai báo (${_rows.length} mục)'),
        ),
      ],
    );
  }
}
