import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../review/presentation/screens/create_review_screen.dart';
import '../../../review/presentation/screens/technician_reviews_screen.dart';
import '../../data/models/order_history_model.dart';
import '../providers/order_history_provider.dart';
import '../../../repair_request/presentation/screens/service_category_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabs = ['ALL', 'PROCESSING', 'COMPLETED', 'CANCELLED'];
  final List<String> _tabLabels = [
    'Tất cả',
    'Đang xử lý',
    'Đã hoàn tất',
    'Đã hủy'
  ];

  @override
  void initState() {
    super.initState();
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
      case 'ACCEPTED':
        return Colors.teal.shade700;
      default:
        return Colors.orange.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyProv = context.watch<OrderHistoryProvider>();

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
              child: historyProv.orders.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.separated(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: historyProv.orders.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final order = historyProv.orders[index];
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
    final formattedDate =
        order.createdAt != null ? dateFormat.format(order.createdAt!) : '';
    final statusColor = _getStatusColor(order.status);

    return Card(
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                const Icon(Icons.location_on_outlined,
                    size: 14, color: AppTheme.textSecondaryColor),
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
                    backgroundColor:
                        AppTheme.primaryColor.withValues(alpha: 0.1),
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
                              const Icon(Icons.star_rounded,
                                  color: Colors.amber, size: 14),
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
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateReviewScreen(
                            technicianId: order.assignedTechnicianId!,
                            technicianName: order.assignedTechnicianName ??
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
                    label: const Text('Xem đánh giá của bạn'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TechnicianReviewsScreen(
                            technicianId: order.assignedTechnicianId!,
                            technicianName: order.assignedTechnicianName ??
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
              // Đơn chưa hoàn tất: Hiển thị ghi chú trạng thái
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
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined,
                size: 64, color: Colors.grey.shade400),
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
              style:
                  TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.handyman_outlined, size: 18),
              label: const Text('Xem danh mục dịch vụ'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: const BorderSide(color: AppTheme.primaryColor),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
