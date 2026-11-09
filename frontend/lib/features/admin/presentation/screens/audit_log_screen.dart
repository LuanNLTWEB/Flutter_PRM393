import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/audit_log_model.dart';
import '../providers/admin_provider.dart';

/// Màn hình Nhật Ký Hoạt Động (Audit Log)
/// Giúp Admin và Staff xem toàn bộ lịch sử thao tác và hành động kiểm duyệt:
/// - Thời gian thực hiện (ngày giờ chuẩn & thời gian tương đối)
/// - Người thực hiện (Admin hay Staff cụ thể)
/// - Hành động kiểm duyệt (Duyệt/Từ chối thợ, Khóa/Mở tài khoản, Xử lý khiếu nại, Sửa danh mục...)
/// - Đối tượng bị tác động và ghi chú/lý do chi tiết
///
/// Code được viết đơn giản, rõ ràng, dễ hiểu cho người mới học Flutter.
class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    // Tự động tải danh sách nhật ký và thống kê khi mở màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Hàm tải dữ liệu nhật ký từ server
  void _loadData() {
    final token = context.read<AuthProvider>().token;
    if (token != null && token.isNotEmpty) {
      final adminProvider = context.read<AdminProvider>();
      adminProvider.fetchAuditLogs(token);
      adminProvider.fetchAuditLogStats(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final token = context.watch<AuthProvider>().token ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: _isSearchExpanded
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên, email, đối tượng...',
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      adminProvider.setAuditLogSearchQuery('', token);
                    },
                  ),
                ),
                onSubmitted: (value) {
                  adminProvider.setAuditLogSearchQuery(value, token);
                },
              )
            : const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nhật Ký Hoạt Động',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Lịch sử kiểm duyệt của Staff & Admin',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondaryColor,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
        actions: [
          IconButton(
            tooltip: _isSearchExpanded ? 'Đóng tìm kiếm' : 'Tìm kiếm nhật ký',
            icon: Icon(_isSearchExpanded ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearchExpanded = !_isSearchExpanded;
                if (!_isSearchExpanded) {
                  _searchController.clear();
                  adminProvider.setAuditLogSearchQuery('', token);
                }
              });
            },
          ),
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: Column(
          children: [
            // 1. Thẻ thống kê số lượng kiểm duyệt
            _buildStatsHeader(adminProvider.auditLogStats),

            // 2. Các thanh bộ lọc (Vai trò & Nhóm nghiệp vụ)
            _buildFiltersSection(adminProvider, token),

            const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),

            // 3. Danh sách nhật ký hoạt động
            Expanded(
              child: _buildLogList(adminProvider, token),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // WIDGETS CON: THỐNG KÊ, BỘ LỌC VÀ DANH SÁCH THẺ
  // ==========================================================

  /// Khung thống kê nhanh các số liệu
  Widget _buildStatsHeader(Map<String, int> stats) {
    final total = stats['total'] ?? 0;
    final adminCount = stats['adminCount'] ?? 0;
    final staffCount = stats['staffCount'] ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Tổng thao tác', '$total', AppTheme.primaryColor),
          Container(width: 1, height: 28, color: Colors.grey.shade200),
          _buildStatItem('Admin thực hiện', '$adminCount', Colors.deepPurple),
          Container(width: 1, height: 28, color: Colors.grey.shade200),
          _buildStatItem('Staff thực hiện', '$staffCount', Colors.teal),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  /// Phần các Chip bộ lọc
  Widget _buildFiltersSection(AdminProvider adminProvider, String token) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dòng 1: Lọc theo Người thực hiện (Admin / Staff)
          Row(
            children: [
              const Text(
                'Người thực hiện:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'Tất cả',
                        isSelected: adminProvider.auditLogRoleFilter == null,
                        onSelected: () => adminProvider.setAuditLogRoleFilter(null, token),
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: 'Admin',
                        isSelected: adminProvider.auditLogRoleFilter == 'admin',
                        selectedColor: Colors.deepPurple,
                        onSelected: () => adminProvider.setAuditLogRoleFilter('admin', token),
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: 'Staff (Nhân viên)',
                        isSelected: adminProvider.auditLogRoleFilter == 'staff',
                        selectedColor: Colors.teal,
                        onSelected: () => adminProvider.setAuditLogRoleFilter('staff', token),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Dòng 2: Lọc theo Nhóm nghiệp vụ kiểm duyệt
          Row(
            children: [
              const Text(
                'Nghiệp vụ:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'Tất cả',
                        isSelected: adminProvider.auditLogActionGroupFilter == null,
                        onSelected: () =>
                            adminProvider.setAuditLogActionGroupFilter(null, token),
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: 'Duyệt Thợ (KYC)',
                        isSelected: adminProvider.auditLogActionGroupFilter == 'KYC',
                        onSelected: () =>
                            adminProvider.setAuditLogActionGroupFilter('KYC', token),
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: 'Quản lý Tài khoản',
                        isSelected: adminProvider.auditLogActionGroupFilter == 'USER',
                        onSelected: () =>
                            adminProvider.setAuditLogActionGroupFilter('USER', token),
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: 'Xử lý Khiếu nại',
                        isSelected: adminProvider.auditLogActionGroupFilter == 'COMPLAINT',
                        onSelected: () =>
                            adminProvider.setAuditLogActionGroupFilter('COMPLAINT', token),
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: 'Danh mục dịch vụ',
                        isSelected: adminProvider.auditLogActionGroupFilter == 'CATEGORY',
                        onSelected: () =>
                            adminProvider.setAuditLogActionGroupFilter('CATEGORY', token),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    Color? selectedColor,
  }) {
    final activeColor = selectedColor ?? AppTheme.primaryColor;
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.shade300,
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
          ),
        ),
      ),
    );
  }

  /// Hiển thị danh sách nhật ký hoạt động
  Widget _buildLogList(AdminProvider adminProvider, String token) {
    if (adminProvider.isAuditLogsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (adminProvider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                adminProvider.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.red),
              ),
              const SizedBox(height: 16),
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

    final logs = adminProvider.auditLogs;

    if (logs.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_toggle_off_rounded,
                  size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'Chưa có nhật ký hoạt động nào',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Mọi thao tác kiểm duyệt của Staff và Admin sẽ được tự động lưu lại tại đây.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.filter_alt_off, size: 16),
                label: const Text('Xóa bộ lọc'),
                onPressed: () {
                  _searchController.clear();
                  adminProvider.resetAuditLogFilters(token);
                },
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return _buildAuditLogCard(log);
      },
    );
  }

  /// Thẻ hiển thị một bản ghi nhật ký kiểm duyệt
  Widget _buildAuditLogCard(AuditLogModel log) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hàng 1: Người thực hiện + Huy hiệu vai trò + Thời gian
            Row(
              children: [
                // Avatar người thực hiện
                CircleAvatar(
                  radius: 16,
                  backgroundColor: log.roleBadgeColor.withValues(alpha: 0.12),
                  child: Text(
                    log.actorInitials,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: log.roleBadgeColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Họ tên người thao tác + Badge Admin/Staff
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              log.actorName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: log.roleBadgeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: log.roleBadgeColor.withValues(alpha: 0.3),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              log.roleDisplay,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: log.roleBadgeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (log.actorEmail.isNotEmpty)
                        Text(
                          log.actorEmail,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondaryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),

                // Thời gian thao tác (giờ phút và thời gian tương đối)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      log.timeAgo,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      log.formattedDateTime,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Hàng 2: Hành động kiểm duyệt (Icon nổi bật + Tiêu đề)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: log.actionColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    log.actionIcon,
                    size: 16,
                    color: log.actionColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.actionTitle,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: log.actionColor,
                        ),
                      ),
                      if (log.targetName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppTheme.textPrimaryColor,
                            ),
                            children: [
                              TextSpan(
                                text: _getTargetTypeLabel(log.targetType),
                                style: const TextStyle(
                                  color: AppTheme.textSecondaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextSpan(
                                text: log.targetName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            // Hàng 3: Chi tiết/Lý do nếu có (hiển thị trong khung xám bo tròn)
            if (log.details.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 13,
                      color: AppTheme.textSecondaryColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        log.details,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                          height: 1.3,
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

  /// Nhãn hiển thị loại đối tượng kiểm duyệt
  String _getTargetTypeLabel(String targetType) {
    switch (targetType) {
      case 'Technician':
        return 'Thợ: ';
      case 'User':
        return 'Tài khoản: ';
      case 'Complaint':
        return 'Khiếu nại: ';
      case 'ServiceCategory':
        return 'Danh mục: ';
      default:
        return 'Đối tượng: ';
    }
  }
}
