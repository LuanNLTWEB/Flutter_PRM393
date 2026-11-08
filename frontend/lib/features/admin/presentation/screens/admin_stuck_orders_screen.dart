// Tác giả: Bảo (CE191178)
// Chức năng: Giám sát đơn hàng bị treo - Can thiệp hủy đơn hoặc hỗ trợ điều phối lại thợ khác (#UC-STF-04)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/admin_provider.dart';

class AdminStuckOrdersScreen extends StatefulWidget {
  const AdminStuckOrdersScreen({super.key});

  @override
  State<AdminStuckOrdersScreen> createState() => _AdminStuckOrdersScreenState();
}

class _AdminStuckOrdersScreenState extends State<AdminStuckOrdersScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    final token = context.read<AuthProvider>().token;
    if (token != null && token.isNotEmpty) {
      context.read<AdminProvider>().fetchStuckRequests(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = context.watch<AuthProvider>().token ?? '';
    final adminProvider = context.watch<AdminProvider>();
    final counts = adminProvider.stuckCounts;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        title: const Text(
          'Giám sát đơn hàng bị treo',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryHeader(counts),
          _buildSearchAndFilters(adminProvider, token),
          Expanded(
            child: _buildRequestList(adminProvider, token),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(Map<String, int> counts) {
    final totalActive = counts['totalActive'] ?? 0;
    final stuckCount = counts['stuckCount'] ?? 0;
    final overdueCount = counts['overdueCount'] ?? 0;
    final noTechCount = counts['noTechCount'] ?? 0;
    final inProgressCount = counts['inProgressCount'] ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCounterItem('Đang mở', '$totalActive', Colors.blueGrey),
          _buildCounterItem('Bị treo', '$stuckCount', Colors.red.shade700),
          _buildCounterItem('Quá giờ hẹn', '$overdueCount', Colors.deepOrange),
          _buildCounterItem('Chờ thợ', '$noTechCount', Colors.amber.shade800),
          _buildCounterItem('Đang làm', '$inProgressCount', Colors.blue.shade700),
        ],
      ),
    );
  }

  Widget _buildCounterItem(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters(AdminProvider provider, String token) {
    final filters = [
      {'key': 'ALL', 'label': 'Tất cả đơn mở'},
      {'key': 'STUCK', 'label': 'Đơn bị treo'},
      {'key': 'OVERDUE', 'label': 'Quá giờ hẹn'},
      {'key': 'NO_TECH', 'label': 'Chưa chốt thợ'},
      {'key': 'IN_PROGRESS', 'label': 'Đang thực hiện'},
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm theo tiêu đề đơn, tên/SĐT khách hoặc thợ...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        provider.setStuckSearchQuery('', token);
                      },
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 14,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (val) => provider.setStuckSearchQuery(val, token),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filters.map((item) {
                final key = item['key']!;
                final label = item['label']!;
                final isSelected = provider.stuckFilter == key;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryColor,
                    backgroundColor: Colors.grey.shade100,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? Colors.white
                          : AppTheme.textPrimaryColor,
                    ),
                    onSelected: (_) => provider.setStuckFilter(key, token),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestList(AdminProvider provider, String token) {
    if (provider.isStuckLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null && provider.stuckRequests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                provider.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Thử lại'),
                onPressed: _loadData,
              ),
            ],
          ),
        ),
      );
    }

    final requests = provider.stuckRequests;
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 60,
              color: Colors.green.shade400,
            ),
            const SizedBox(height: 12),
            const Text(
              'Không có đơn hàng nào bị treo trong bộ lọc hiện tại',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          return _buildStuckRequestCard(requests[index], provider, token);
        },
      ),
    );
  }

  Widget _buildStuckRequestCard(
    Map<String, dynamic> req,
    AdminProvider provider,
    String token,
  ) {
    final requestId = (req['_id'] ?? req['id'] ?? '').toString();
    final title = (req['title'] ?? 'Yêu cầu sửa chữa').toString();
    final status = (req['status'] ?? 'OPEN').toString();
    final urgency = (req['urgency'] ?? 'medium').toString();
    final staffNote = (req['staffInterventionNote'] ?? '').toString();

    final category = req['serviceCategoryId'] is Map
        ? Map<String, dynamic>.from(req['serviceCategoryId'] as Map)
        : <String, dynamic>{};
    final customer = req['customerId'] is Map
        ? Map<String, dynamic>.from(req['customerId'] as Map)
        : <String, dynamic>{};
    final technician = req['assignedTechnicianId'] is Map
        ? Map<String, dynamic>.from(req['assignedTechnicianId'] as Map)
        : null;
    final location = req['location'] is Map
        ? Map<String, dynamic>.from(req['location'] as Map)
        : <String, dynamic>{};
    final stuckInfo = req['stuckInfo'] is Map
        ? Map<String, dynamic>.from(req['stuckInfo'] as Map)
        : <String, dynamic>{};

    final isStuck = stuckInfo['isStuck'] == true;
    final severity = (stuckInfo['stuckSeverity'] ?? 'NORMAL').toString();
    final stuckReason = (stuckInfo['stuckReason'] ?? '').toString();
    final preferredTimeStr = req['preferredTime']?.toString();
    final createdAtStr = req['createdAt']?.toString();

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    String preferredTimeDisplay = 'Chưa đặt lịch hẹn';
    if (preferredTimeStr != null && preferredTimeStr.isNotEmpty) {
      final dt = DateTime.tryParse(preferredTimeStr)?.toLocal();
      if (dt != null) preferredTimeDisplay = dateFormat.format(dt);
    }

    String createdDisplay = '';
    if (createdAtStr != null && createdAtStr.isNotEmpty) {
      final dt = DateTime.tryParse(createdAtStr)?.toLocal();
      if (dt != null) createdDisplay = dateFormat.format(dt);
    }

    final severityColor = severity == 'HIGH'
        ? Colors.red.shade700
        : (severity == 'MEDIUM'
            ? Colors.orange.shade800
            : Colors.blueGrey.shade600);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isStuck ? severityColor.withValues(alpha: 0.5) : Colors.grey.shade200,
          width: isStuck ? 1.4 : 1,
        ),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hàng trạng thái + mức độ cảnh báo
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isStuck ? Icons.warning_amber_rounded : Icons.schedule,
                        size: 14,
                        color: severityColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isStuck
                            ? (severity == 'HIGH' ? 'TREO NGHIÊM TRỌNG' : 'ĐƠN BỊ TREO')
                            : 'ĐANG THEO DÕI',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: severityColor,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(status),
                _buildUrgencyBadge(urgency),
              ],
            ),
            const SizedBox(height: 10),

            // Tiêu đề & Danh mục
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Danh mục: ${category['name'] ?? 'Dịch vụ sửa chữa'} • Tạo lúc: $createdDisplay',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 8),

            // Lý do bị treo
            if (stuckReason.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: severityColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: severityColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        stuckReason,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: severityColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 10),

            // Thông tin Khách hàng, Thợ, Giờ hẹn, Địa chỉ
            _buildInfoRow(
              Icons.person_outline,
              'Khách hàng:',
              '${customer['fullName'] ?? 'N/A'} (${customer['phoneNumber'] ?? 'Chưa có SĐT'})',
            ),
            const SizedBox(height: 4),
            _buildInfoRow(
              Icons.engineering_outlined,
              'Thợ phụ trách:',
              technician != null
                  ? '${technician['fullName']} (${technician['phoneNumber'] ?? ''})'
                  : 'Chưa có thợ tiếp nhận',
              valueColor: technician != null
                  ? Colors.teal.shade700
                  : Colors.orange.shade800,
            ),
            const SizedBox(height: 4),
            _buildInfoRow(
              Icons.event_available_outlined,
              'Giờ hẹn:',
              preferredTimeDisplay,
            ),
            const SizedBox(height: 4),
            _buildInfoRow(
              Icons.location_on_outlined,
              'Địa chỉ:',
              (location['address'] ?? 'Chưa cập nhật địa chỉ').toString(),
            ),

            if (staffNote.isNotEmpty) ...[
              const SizedBox(height: 6),
              _buildInfoRow(
                Icons.support_agent,
                'Ghi chú Staff:',
                staffNote,
                valueColor: Colors.deepPurple,
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Nút hành động can thiệp của Staff
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.cancel_outlined, size: 17),
                    label: const Text(
                      'Can thiệp hủy đơn',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _showCancelDialog(
                      context: context,
                      requestId: requestId,
                      requestTitle: title,
                      provider: provider,
                      token: token,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                    label: const Text(
                      'Điều phối lại thợ',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _showReassignDialog(
                      context: context,
                      req: req,
                      provider: provider,
                      token: token,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: valueColor ?? AppTheme.textPrimaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final labels = {
      'OPEN': 'Đang mở',
      'QUOTED': 'Đã có báo giá',
      'ACCEPTED': 'Đã chốt thợ',
      'ON_THE_WAY': 'Đang di chuyển',
      'ARRIVED': 'Đã đến nơi',
      'IN_PROGRESS': 'Đang sửa chữa',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        labels[status] ?? status,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade800,
        ),
      ),
    );
  }

  Widget _buildUrgencyBadge(String urgency) {
    final map = {
      'emergency': {'label': 'Khẩn cấp', 'color': Colors.red.shade700},
      'high': {'label': 'Ưu tiên cao', 'color': Colors.deepOrange},
      'medium': {'label': 'Bình thường', 'color': Colors.teal},
      'low': {'label': 'Thấp', 'color': Colors.grey.shade700},
    };
    final item = map[urgency] ?? map['medium']!;
    final color = item['color'] as Color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        item['label'] as String,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  void _showCancelDialog({
    required BuildContext context,
    required String requestId,
    required String requestTitle,
    required AdminProvider provider,
    required String token,
  }) {
    final reasonController = TextEditingController();
    final quickReasons = [
      'Khách hàng không liên lạc được sau nhiều lần gọi',
      'Không có kỹ thuật viên khả dụng tại khu vực này',
      'Kỹ thuật viên gặp sự cố đột xuất, khách đồng ý hủy đơn',
      'Đơn hàng bị treo quá hạn lịch hẹn và không thể điều phối lại',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text(
            'Can thiệp hủy đơn hàng',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đơn: "$requestTitle"',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Chọn nhanh lý do hoặc nhập chi tiết:',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: quickReasons.map((r) {
                    return ActionChip(
                      label: Text(r, style: const TextStyle(fontSize: 11)),
                      onPressed: () {
                        reasonController.text = r;
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Lý do hủy đơn vận hành *',
                    hintText: 'Nhập lý do can thiệp hủy đơn (ít nhất 5 ký tự)...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final reason = reasonController.text.trim();
                if (reason.length < 5) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập lý do hủy ít nhất 5 ký tự'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx);
                final ok = await provider.staffCancelRequest(
                  token: token,
                  requestId: requestId,
                  reason: reason,
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? (provider.successMessage ?? 'Đã hủy đơn thành công')
                          : (provider.errorMessage ?? 'Không thể hủy đơn'),
                    ),
                    backgroundColor: ok ? Colors.green : Colors.red,
                  ),
                );
              },
              child: const Text('Xác nhận hủy đơn'),
            ),
          ],
        );
      },
    );
  }

  void _showReassignDialog({
    required BuildContext context,
    required Map<String, dynamic> req,
    required AdminProvider provider,
    required String token,
  }) {
    final requestId = (req['_id'] ?? req['id'] ?? '').toString();
    final requestTitle = (req['title'] ?? 'Yêu cầu sửa chữa').toString();
    final currentTech = req['assignedTechnicianId'] is Map
        ? Map<String, dynamic>.from(req['assignedTechnicianId'] as Map)
        : null;
    final currentTechId =
        currentTech != null ? (currentTech['_id'] ?? currentTech['id'] ?? '').toString() : '';

    final availableTechs = provider.availableTechnicians
        .where((t) => (t['_id'] ?? t['id'] ?? '').toString() != currentTechId)
        .toList();

    final preferredTimeStr = req['preferredTime']?.toString();
    final preferredDt = preferredTimeStr != null
        ? DateTime.tryParse(preferredTimeStr)?.toLocal()
        : null;
    final isOverduePreferred =
        preferredDt != null && preferredDt.isBefore(DateTime.now());

    String mode = availableTechs.isNotEmpty ? 'ASSIGN' : 'REOPEN';
    String? selectedTechId = availableTechs.isNotEmpty
        ? (availableTechs.first['_id'] ?? availableTechs.first['id']).toString()
        : null;
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Điều phối lại thợ sửa chữa',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đơn: "$requestTitle"',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (currentTech != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Thợ hiện tại: ${currentTech['fullName']} (${currentTech['phoneNumber'] ?? ''})',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                    if (isOverduePreferred) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.update,
                              size: 15,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Đơn đã quá giờ hẹn cũ — khi điều phối lại, hệ thống sẽ tự động gia hạn khung giờ hẹn mới (+2 giờ) để mở khóa xác nhận lịch hẹn.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      enabled: availableTechs.isNotEmpty,
                      leading: Icon(
                        mode == 'ASSIGN'
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: availableTechs.isEmpty
                            ? Colors.grey
                            : (mode == 'ASSIGN'
                                ? AppTheme.primaryColor
                                : Colors.grey),
                      ),
                      title: const Text(
                        'Chỉ định trực tiếp Thợ mới',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Gán ngay cho một kỹ thuật viên rảnh & đã duyệt KYC',
                        style: TextStyle(fontSize: 11),
                      ),
                      onTap: availableTechs.isEmpty
                          ? null
                          : () {
                              setDialogState(() => mode = 'ASSIGN');
                            },
                    ),
                    if (mode == 'ASSIGN') ...[
                      if (availableTechs.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Hiện không có thợ rảnh khả dụng để gán trực tiếp.',
                            style: TextStyle(fontSize: 12, color: Colors.orange),
                          ),
                        )
                      else
                        DropdownButtonFormField<String>(
                          initialValue: selectedTechId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Chọn kỹ thuật viên thay thế',
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          items: availableTechs.map((tech) {
                            final id = (tech['_id'] ?? tech['id']).toString();
                            final name = (tech['fullName'] ?? 'Thợ').toString();
                            final phone = (tech['phoneNumber'] ?? '').toString();
                            final profile = tech['technicianProfile'] is Map
                                ? Map<String, dynamic>.from(
                                    tech['technicianProfile'] as Map,
                                  )
                                : <String, dynamic>{};
                            final rating = ((profile['rating'] ??
                                        profile['averageRating'] ??
                                        tech['rating']) as num?)
                                    ?.toDouble() ??
                                5.0;
                            final isOnline = profile['isAvailable'] == true;
                            return DropdownMenuItem<String>(
                              value: id,
                              child: Text(
                                '$name ($phone) • ${rating.toStringAsFixed(1)} sao ${isOnline ? "[Online]" : ""}',
                                style: const TextStyle(fontSize: 12.5),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setDialogState(() => selectedTechId = val);
                          },
                        ),
                    ],
                    const SizedBox(height: 6),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: Icon(
                        mode == 'REOPEN'
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: mode == 'REOPEN'
                            ? AppTheme.primaryColor
                            : Colors.grey,
                      ),
                      title: const Text(
                        'Gỡ thợ cũ & Mở lại đơn (OPEN)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Đưa đơn về danh sách mở để các thợ quanh khu vực báo giá lại',
                        style: TextStyle(fontSize: 11),
                      ),
                      onTap: () {
                        setDialogState(() => mode = 'REOPEN');
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: noteController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Ghi chú điều phối (tùy chọn)',
                        hintText: 'Nhập ghi chú gửi đến khách hàng và kỹ thuật viên...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (mode == 'ASSIGN' &&
                        (selectedTechId == null || selectedTechId!.isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng chọn kỹ thuật viên thay thế'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    final ok = await provider.staffReassignRequest(
                      token: token,
                      requestId: requestId,
                      newTechnicianId: mode == 'ASSIGN' ? selectedTechId : null,
                      mode: mode,
                      note: noteController.text.trim(),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? (provider.successMessage ??
                                  'Đã điều phối lại đơn hàng thành công')
                              : (provider.errorMessage ??
                                  'Không thể điều phối lại đơn hàng'),
                        ),
                        backgroundColor: ok ? Colors.green : Colors.red,
                      ),
                    );
                  },
                  child: const Text('Xác nhận điều phối'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
