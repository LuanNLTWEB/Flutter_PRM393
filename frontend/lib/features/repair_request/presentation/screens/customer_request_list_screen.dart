import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/repair_request_model.dart';
import '../providers/repair_request_provider.dart';
import '../widgets/request_item_card_widget.dart';
import 'service_category_screen.dart';
import '../../../quotations/presentation/screens/request_quotations_screen.dart';

/// Màn hình danh sách các yêu cầu sửa chữa đã tạo của Khách hàng (UC-REQ-07, 08, 09)
class CustomerRequestListScreen extends StatefulWidget {
  final int initialTabIndex;

  const CustomerRequestListScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<CustomerRequestListScreen> createState() =>
      _CustomerRequestListScreenState();
}

class _CustomerRequestListScreenState extends State<CustomerRequestListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabs = [
    'Chờ báo giá',
    'Đã chốt thợ',
    'Đã hủy',
    'Tất cả',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRequests();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests({bool refresh = false}) async {
    final auth = context.read<AuthProvider>();
    final token = auth.token ?? '';
    if (token.isEmpty) return;

    await context.read<RepairRequestProvider>().fetchMyRequests(
          token: token,
          refresh: refresh,
        );
  }

  List<RepairRequestModel> _filterRequests(
    List<RepairRequestModel> list,
    int tabIndex,
  ) {
    switch (tabIndex) {
      case 0: // Chờ báo giá (UC-REQ-07)
        return list
            .where((r) => r.status == 'OPEN' || r.status == 'QUOTED')
            .toList();
      case 1: // Đã chốt thợ
        return list
            .where((r) =>
                r.status == 'ACCEPTED' ||
                r.status == 'ON_THE_WAY' ||
                r.status == 'ARRIVED' ||
                r.status == 'IN_PROGRESS' ||
                r.status == 'COMPLETED')
            .toList();
      case 2: // Đã hủy
        return list.where((r) => r.status == 'CANCELLED').toList();
      case 3: // Tất cả
      default:
        return list;
    }
  }

  void _showRequestDetailModal(RepairRequestModel request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Thanh kéo
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Chi tiết phiếu yêu cầu',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Nội dung chi tiết
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Tên dịch vụ & Trạng thái
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            request.serviceCategory?.name ?? 'Dịch vụ sửa chữa',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Text(
                            request.statusDisplay,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Tiêu đề
                    Text(
                      request.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Mô tả chi tiết
                    const Text(
                      'Mô tả sự cố:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        request.description,
                        style: const TextStyle(fontSize: 14, height: 1.45),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Mức độ khẩn cấp & Lịch hẹn
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailCard(
                            icon: Icons.speed_rounded,
                            label: 'Mức độ',
                            value: request.urgencyDisplay,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDetailCard(
                            icon: Icons.event_available_rounded,
                            label: 'Lịch hẹn',
                            value: request.preferredTime != null
                                ? '${request.preferredTime!.day}/${request.preferredTime!.month}/${request.preferredTime!.year}\n${request.preferredTime!.hour}:${request.preferredTime!.minute.toString().padLeft(2, '0')}'
                                : 'Sớm nhất có thể',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Địa chỉ sửa chữa
                    if (request.location.address.isNotEmpty)
                      _buildDetailCard(
                        icon: Icons.location_on_rounded,
                        label: 'Địa chỉ sửa chữa',
                        value: request.location.address,
                      ),
                    const SizedBox(height: 16),

                    // Hình ảnh hiện trường
                    if (request.images.isNotEmpty) ...[
                      const Text(
                        'Ảnh hiện trường sự cố:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 90,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: request.images.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 10),
                          itemBuilder: (ctx, idx) {
                            final url = request.images[idx];
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: InkWell(
                                onTap: () => _showFullImageDialog(url),
                                child: Image.network(
                                  url,
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 90,
                                    height: 90,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.broken_image, color: Colors.grey),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Thông tin hủy nếu có
                    if (request.status == 'CANCELLED' && request.cancellationReason.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Lý do hủy yêu cầu:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    request.cancellationReason,
                                    style: const TextStyle(fontSize: 13, color: Colors.brown),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Nút theo dõi báo giá
                    ElevatedButton.icon(
                      icon: const Icon(Icons.request_quote_rounded),
                      label: Text(
                        request.quotesCount > 0
                            ? 'Xem ${request.quotesCount} báo giá từ thợ'
                            : 'Theo dõi báo giá từ thợ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RequestQuotationsScreen(
                              requestId: request.id,
                              request: request,
                            ),
                          ),
                        );
                      },
                    ),
                    if (request.status == 'OPEN' || request.status == 'QUOTED') ...[
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        key: const Key('modal_cancel_request_button'),
                        icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                        label: const Text(
                          'Hủy yêu cầu sửa chữa này',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red.shade300),
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showCancelDialog(request);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Hộp thoại xác nhận hủy yêu cầu sửa chữa
  void _showCancelDialog(RepairRequestModel request) {
    String selectedReason = 'Đã tự khắc phục được sự cố';
    final otherReasonController = TextEditingController();
    bool isOther = false;

    final reasons = [
      'Đã tự khắc phục được sự cố',
      'Thời gian không còn phù hợp',
      'Tôi muốn thay đổi thông tin yêu cầu',
      'Lý do khác',
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final provider = context.watch<RepairRequestProvider>();

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red),
                  SizedBox(width: 8),
                  Text(
                    'Hủy yêu cầu sửa chữa',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bạn có chắc chắn muốn hủy yêu cầu "${request.title}" không?',
                      style: const TextStyle(fontSize: 14, color: AppTheme.textPrimaryColor),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Vui lòng chọn lý do hủy:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...reasons.map((r) {
                      final isSelected = isOther ? (r == 'Lý do khác') : (selectedReason == r);
                      return InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          setDialogState(() {
                            if (r == 'Lý do khác') {
                              isOther = true;
                            } else {
                              isOther = false;
                              selectedReason = r;
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                size: 20,
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : Colors.grey.shade500,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(r, style: const TextStyle(fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    if (isOther) ...[
                      const SizedBox(height: 8),
                      TextField(
                        key: const Key('cancel_reason_other_input'),
                        controller: otherReasonController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Nhập lý do hủy cụ thể...',
                          hintStyle: const TextStyle(fontSize: 13),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: provider.isCancelling ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Đóng'),
                ),
                ElevatedButton(
                  key: const Key('confirm_cancel_request_button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: provider.isCancelling
                      ? null
                      : () async {
                          final auth = context.read<AuthProvider>();
                          final repairProvider = context.read<RepairRequestProvider>();
                          final messenger = ScaffoldMessenger.of(context);
                          final token = auth.token ?? '';
                          final finalReason = isOther
                              ? (otherReasonController.text.trim().isNotEmpty
                                  ? otherReasonController.text.trim()
                                  : 'Lý do khác')
                              : selectedReason;

                          final success = await repairProvider.cancelRepairRequest(
                            token: token,
                            requestId: request.id,
                            reason: finalReason,
                          );

                          if (dialogCtx.mounted) {
                            Navigator.pop(dialogCtx);
                          }
                          if (!mounted) return;

                          if (success) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Đã hủy phiếu yêu cầu thành công'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            _tabController.animateTo(2);
                          } else {
                            final err = repairProvider.cancelError ?? 'Không thể hủy yêu cầu';
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(err),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: provider.isCancelling
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Xác nhận hủy'),
                ),
              ],

            );
          },
        );
      },
    );
  }


  void _showFullImageDialog(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: const Text('Không thể tải ảnh'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RepairRequestProvider>();
    final allRequests = provider.myRequests;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Yêu cầu sửa chữa của tôi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: AppTheme.primaryColor,
          indicatorWeight: 3,
          tabs: [
            Tab(
              child: Row(
                children: [
                  const Text('Chờ báo giá'),
                  const SizedBox(width: 6),
                  _buildCountBadge(
                    provider.openRequests.length,
                    Colors.orange.shade700,
                    Colors.orange.shade50,
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                children: [
                  const Text('Đã chốt thợ'),
                  const SizedBox(width: 6),
                  _buildCountBadge(
                    provider.acceptedRequests.length,
                    Colors.green.shade700,
                    Colors.green.shade50,
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                children: [
                  const Text('Đã hủy'),
                  const SizedBox(width: 6),
                  _buildCountBadge(
                    provider.cancelledRequests.length,
                    Colors.red.shade700,
                    Colors.red.shade50,
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                children: [
                  const Text('Tất cả'),
                  const SizedBox(width: 6),
                  _buildCountBadge(
                    allRequests.length,
                    Colors.blue.shade700,
                    Colors.blue.shade50,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: provider.isLoadingRequests && allRequests.isEmpty
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : provider.requestsError != null && allRequests.isEmpty
              ? _buildErrorView(provider.requestsError!)
              : TabBarView(
                  controller: _tabController,
                  children: List.generate(_tabs.length, (tabIndex) {
                    final filtered = _filterRequests(allRequests, tabIndex);
                    return _buildRequestListTab(filtered, tabIndex);
                  }),
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tạo yêu cầu mới', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ServiceCategoryScreen(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCountBadge(int count, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 56, color: Colors.red.shade400),
            const SizedBox(height: 12),
            const Text(
              'Không thể tải danh sách yêu cầu',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              onPressed: () => _loadRequests(refresh: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestListTab(List<RepairRequestModel> items, int tabIndex) {
    if (items.isEmpty) {
      String emptyMessage;
      IconData emptyIcon;
      switch (tabIndex) {
        case 0: // Chờ báo giá
          emptyMessage = 'Bạn chưa có yêu cầu nào đang mở chờ thợ gửi báo giá';
          emptyIcon = Icons.hourglass_empty_rounded;
          break;
        case 1: // Đã chốt
          emptyMessage = 'Bạn chưa có yêu cầu nào đã chốt thợ';
          emptyIcon = Icons.assignment_turned_in_outlined;
          break;
        case 2: // Đã hủy
          emptyMessage = 'Không có yêu cầu nào đã hủy';
          emptyIcon = Icons.cancel_presentation_outlined;
          break;
        default:
          emptyMessage = 'Bạn chưa tạo yêu cầu sửa chữa nào';
          emptyIcon = Icons.post_add_outlined;
      }

      return RefreshIndicator(
        onRefresh: () => _loadRequests(refresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(emptyIcon, size: 36, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    emptyMessage,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Đăng yêu cầu ngay để nhận báo giá cạnh tranh từ các thợ lành nghề gần bạn',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Đăng yêu cầu sửa chữa'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadRequests(refresh: true),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        itemCount: items.length,
        itemBuilder: (ctx, index) {
          final request = items[index];
          return RequestItemCardWidget(
            key: ValueKey(request.id),
            request: request,
            onDetailPressed: () => _showRequestDetailModal(request),
            onCancelPressed: (request.status == 'OPEN' || request.status == 'QUOTED')
                ? () => _showCancelDialog(request)
                : null,
          );
        },

      ),
    );
  }
}
