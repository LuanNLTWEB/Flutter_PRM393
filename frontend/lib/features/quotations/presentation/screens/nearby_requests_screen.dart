import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../repair_request/data/models/repair_request_model.dart';
import '../../../repair_request/data/models/service_category_model.dart';
import '../../../repair_request/presentation/providers/repair_request_provider.dart';
import '../../../repair_request/presentation/widgets/schedule_time_slot_picker.dart';
import '../../data/datasources/quotation_remote_datasource.dart';
import '../providers/quotation_provider.dart';
import '../widgets/quotation_format.dart';
import 'request_detail_screen.dart';

/// Feed yêu cầu sửa chữa đang mở dành cho Thợ (UC-QUO-01)
/// + bộ lọc danh mục dịch vụ / khẩn cấp (UC-QUO-02)
/// + tab "Yêu cầu đã báo giá" để xem/sửa/thu hồi báo giá (UC-QUO-05)
class NearbyRequestsScreen extends StatefulWidget {
  const NearbyRequestsScreen({super.key});

  @override
  State<NearbyRequestsScreen> createState() => _NearbyRequestsScreenState();
}

class _NearbyRequestsScreenState extends State<NearbyRequestsScreen> {
  String? _selectedSlug;
  int _activeTab = 0; // 0 = Công khai (OPEN), 1 = Đã báo giá

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load(refresh: true);
      context.read<RepairRequestProvider>().fetchCategories();
    });
  }

  Future<void> _load({bool refresh = false}) async {
    final token = context.read<AuthProvider>().token ?? '';
    if (token.isEmpty) return;
    await context.read<QuotationProvider>().fetchNearbyRequests(
          token: token,
          categorySlug: _selectedSlug,
          refresh: refresh,
        );
  }

  Future<void> _loadMyQuotes({bool refresh = false}) async {
    final token = context.read<AuthProvider>().token ?? '';
    if (token.isEmpty) return;
    await context
        .read<QuotationProvider>()
        .fetchMyQuotations(token: token, refresh: refresh);
  }

  void _switchTab(int index) {
    if (_activeTab == index) return;
    setState(() => _activeTab = index);
    if (index == 1) {
      _loadMyQuotes(refresh: true);
    } else {
      _load(refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories =
        context.watch<RepairRequestProvider>().rawCategories;

    return Scaffold(
      appBar: AppBar(
        title: Text(_activeTab == 0 ? 'Yêu cầu quanh đây' : 'Yêu cầu đã báo giá'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh),
            onPressed: () => _activeTab == 0
                ? _load(refresh: true)
                : _loadMyQuotes(refresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabs(),
          if (_activeTab == 0) _buildFilters(categories),
          Expanded(
            child: Consumer<QuotationProvider>(
              builder: (context, provider, _) {
                if (_activeTab == 1) return _buildMyQuotes(provider);

                if (provider.isLoading && provider.nearbyRequests.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.errorMessage != null &&
                    provider.nearbyRequests.isEmpty) {
                  return _ErrorState(
                    message: provider.errorMessage!,
                    onRetry: () => _load(refresh: true),
                  );
                }

                if (provider.nearbyRequests.isEmpty) {
                  return const _EmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () => _load(refresh: true),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: provider.nearbyRequests.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _LocationHint(hasLocation: provider.hasLocation);
                      }
                      final request = provider.nearbyRequests[index - 1];
                      return _RequestCard(
                        request: request,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                RequestDetailScreen(requestId: request.id, request: request),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyQuotes(QuotationProvider provider) {
    if (provider.isLoading && provider.myQuotes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null && provider.myQuotes.isEmpty) {
      return _ErrorState(
        message: provider.errorMessage!,
        onRetry: () => _loadMyQuotes(refresh: true),
      );
    }

    if (provider.myQuotes.isEmpty) {
      return const _MyQuotesEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => _loadMyQuotes(refresh: true),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        itemCount: provider.myQuotes.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = provider.myQuotes[index];
          return _MyQuoteCard(
            item: item,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RequestDetailScreen(
                    requestId: item.request.id,
                    request: item.request,
                  ),
                ),
              );
              if (context.mounted) _loadMyQuotes(refresh: true);
            },
          );
        },
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: AppTheme.surfaceColor,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'Công khai',
              icon: Icons.public,
              selected: _activeTab == 0,
              onTap: () => _switchTab(0),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _TabButton(
              label: 'Đã báo giá',
              icon: Icons.request_quote_outlined,
              selected: _activeTab == 1,
              onTap: () => _switchTab(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(List<ServiceCategoryModel> categories) {
    return Container(
      color: AppTheme.surfaceColor,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lọc theo chuyên môn',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Tất cả',
                  selected: _selectedSlug == null,
                  onTap: () {
                    setState(() => _selectedSlug = null);
                    _load(refresh: true);
                  },
                ),
                const SizedBox(width: 8),
                ...categories.map(
                  (category) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: category.name,
                      selected: _selectedSlug == category.slug,
                      onTap: () {
                        setState(() => _selectedSlug =
                            _selectedSlug == category.slug ? null : category.slug);
                        _load(refresh: true);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor
              : AppTheme.primaryColor.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppTheme.primaryColor
                : AppTheme.primaryColor.withValues(alpha: 0.25),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }
}

class _LocationHint extends StatelessWidget {
  final bool hasLocation;

  const _LocationHint({required this.hasLocation});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: (hasLocation ? Colors.green : Colors.orange).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            hasLocation ? Icons.location_on : Icons.location_off,
            size: 16,
            color: hasLocation ? Colors.green.shade700 : Colors.orange.shade800,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasLocation
                  ? 'Đang sắp xếp theo khoảng cách từ vị trí của bạn'
                  : 'Chưa có tọa độ vị trí — sắp xếp theo mức độ khẩn cấp',
              style: TextStyle(
                fontSize: 12,
                color: hasLocation
                    ? Colors.green.shade800
                    : Colors.orange.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final RepairRequestModel request;
  final VoidCallback onTap;

  const _RequestCard({required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: urgencyColor(request.urgency).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    urgencyLabel(request.urgency),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: urgencyColor(request.urgency),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    request.serviceCategory?.name ?? 'Dịch vụ',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  timeAgo(request.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              request.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              request.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.lock_outline,
                    size: 14, color: AppTheme.textSecondaryColor),
                const SizedBox(width: 4),
                const Text(
                  'Địa chỉ & SĐT ẩn đến khi được chốt',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
                ),
                const Spacer(),
                Text(
                  request.statusDisplay,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? AppTheme.primaryColor
                : AppTheme.primaryColor.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : AppTheme.primaryColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyQuoteCard extends StatelessWidget {
  final MyQuotationItem item;
  final VoidCallback onTap;

  const _MyQuoteCard({required this.item, required this.onTap});

  Color get _quoteStatusColor {
    switch (item.quote.status) {
      case 'ACCEPTED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      case 'RETRACTED':
        return Colors.grey;
      default:
        return AppTheme.primaryColor;
    }
  }

  String _formatDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/${dt.year} $hh:$mm';
  }

  /// Khu vực xác nhận / đổi lịch hẹn — chỉ hiện khi Thợ được chốt (UC-LIC-01)
  Widget _buildAppointmentSection(BuildContext context) {
    final request = item.request;
    final provider = context.watch<QuotationProvider>();

    return Container(
      margin: const EdgeInsets.only(top: 10),
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
              const Icon(Icons.event_available_outlined,
                  size: 16, color: Colors.blue),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _appointmentStatusColor
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  request.appointmentStatusDisplay,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _appointmentStatusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (request.preferredTime != null)
            Row(
              children: [
                const Icon(Icons.schedule, size: 14,
                    color: AppTheme.textSecondaryColor),
                const SizedBox(width: 4),
                Text(
                  'Giờ khách đề xuất: ${_formatDateTime(request.preferredTime!)}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            )
          else
            const Text(
              'Khách chưa chọn giờ hẹn',
              style: TextStyle(
                fontSize: 12.5,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          if (request.appointmentStatus == 'RESCHEDULED' &&
              request.proposedTime != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.swap_horiz, size: 14,
                    color: Colors.orange.shade700),
                const SizedBox(width: 4),
                Text(
                  'Đề xuất của bạn: ${_formatDateTime(request.proposedTime!)}',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
            if (request.rescheduleNote.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Lý do: ${request.rescheduleNote}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ),
          ],
          // Khách vừa từ chối khung giờ đề xuất — hiển thị lý do (nếu có)
          if (request.appointmentStatus == 'PENDING' &&
              request.rescheduleRejectNote.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.cancel_outlined,
                      size: 14, color: Colors.red.shade700),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Khách từ chối khung giờ bạn đề xuất: '
                      '${request.rescheduleRejectNote}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.red.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (request.appointmentStatus != 'CONFIRMED') ...[
            const SizedBox(height: 10),
            if (request.appointmentStatus == 'RESCHEDULED') ...[
              // Đang chờ Khách phản hồi — chỉ cho phép đề xuất khung giờ khác
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.hourglass_top,
                        size: 14, color: Colors.orange.shade800),
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
                        fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                  onPressed: provider.isSubmitting
                      ? null
                      : () => _showRescheduleSheet(context),
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
                            fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                      onPressed: provider.isSubmitting
                          ? null
                          : () => _showRescheduleSheet(context),
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
                            fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                      onPressed: (provider.isSubmitting ||
                              request.preferredTime == null)
                          ? null
                          : () => _confirmAppointment(context),
                    ),
                  ),
                ],
              ),
          ] else if (request.status == 'ACCEPTED') ...[
            // Lịch hẹn đã xác nhận — thợ bấm "Đang trên đường đến nhà khách" (UC-DI-01)
            const SizedBox(height: 10),
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
                  style: TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
                onPressed: provider.isSubmitting
                    ? null
                    : () => _markOnTheWay(context),
              ),
            ),
          ] else if (request.status == 'ON_THE_WAY') ...[
            // Đã bấm di chuyển — hiển thị trạng thái
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.navigation,
                      size: 14, color: Colors.blue.shade700),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Bạn đang trên đường đến nhà khách',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color get _appointmentStatusColor {
    switch (item.request.appointmentStatus) {
      case 'CONFIRMED':
        return Colors.green.shade700;
      case 'RESCHEDULED':
        return Colors.orange.shade800;
      default:
        return Colors.blue.shade700;
    }
  }

  Future<void> _confirmAppointment(BuildContext context) async {
    final token = context.read<AuthProvider>().token ?? '';
    if (token.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đồng ý giờ hẹn?'),
        content: Text(
          item.request.preferredTime != null
              ? 'Bạn xác nhận sẽ đến nhà khách vào ${_formatDateTime(item.request.preferredTime!)}?'
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
    if (confirmed != true || !context.mounted) return;

    final provider = context.read<QuotationProvider>();
    final ok = await provider.confirmAppointment(
      token: token,
      requestId: item.request.id,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (provider.successMessage ?? 'Xác nhận lịch hẹn thành công')
              : (provider.errorMessage ?? 'Xác nhận lịch hẹn thất bại'),
        ),
        backgroundColor: ok ? Colors.green.shade700 : Colors.red.shade600,
      ),
    );
  }

  Future<void> _markOnTheWay(BuildContext context) async {
    final token = context.read<AuthProvider>().token ?? '';
    if (token.isEmpty) return;

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
    if (confirmed != true || !context.mounted) return;

    final provider = context.read<QuotationProvider>();
    final ok = await provider.markOnTheWay(
      token: token,
      requestId: item.request.id,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (provider.successMessage ?? 'Đã cập nhật trạng thái di chuyển')
              : (provider.errorMessage ?? 'Cập nhật trạng thái di chuyển thất bại'),
        ),
        backgroundColor: ok ? Colors.blue.shade700 : Colors.red.shade600,
      ),
    );
  }

  Future<void> _showRescheduleSheet(BuildContext context) async {
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
                      item.request.preferredTime != null
                          ? 'Khách đề xuất: ${_formatDateTime(item.request.preferredTime!)}'
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
                        hintText: 'VD: Tôi bận khung giờ đó, đề xuất 14h cùng ngày',
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
                              fontSize: 14, fontWeight: FontWeight.bold),
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

    if (proposed == null || !context.mounted) return;

    final provider = context.read<QuotationProvider>();
    final ok = await provider.proposeAppointment(
      token: token,
      requestId: item.request.id,
      proposedTime: proposed,
      note: noteController.text.trim(),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (provider.successMessage ?? 'Đề xuất khung giờ mới thành công')
              : (provider.errorMessage ?? 'Đề xuất khung giờ mới thất bại'),
        ),
        backgroundColor: ok ? Colors.green.shade700 : Colors.red.shade600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = item.request;
    final quote = item.quote;
    final isWon = quote.status == 'ACCEPTED';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: urgencyColor(request.urgency).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    urgencyLabel(request.urgency),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: urgencyColor(request.urgency),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    request.statusDisplay,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  timeAgo(quote.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              request.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              request.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text(
                  'Báo giá của bạn:',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  formatVnd(quote.total),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _quoteStatusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    quote.statusDisplay,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _quoteStatusColor,
                    ),
                  ),
                ),
              ],
            ),
            if (isWon) _buildAppointmentSection(context),
          ],
        ),
      ),
    );
  }
}

class _MyQuotesEmptyState extends StatelessWidget {
  const _MyQuotesEmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        SizedBox(height: 80),
        Icon(Icons.request_quote_outlined,
            size: 64, color: AppTheme.textSecondaryColor),
        SizedBox(height: 12),
        Center(
          child: Text(
            'Bạn chưa gửi báo giá nào',
            style: TextStyle(fontSize: 15, color: AppTheme.textSecondaryColor),
          ),
        ),
        SizedBox(height: 6),
        Center(
          child: Text(
            'Chọn một yêu cầu trong tab "Công khai" để gửi báo giá',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        SizedBox(height: 80),
        Icon(Icons.inbox_outlined, size: 64, color: AppTheme.textSecondaryColor),
        SizedBox(height: 12),
        Center(
          child: Text(
            'Chưa có yêu cầu nào phù hợp',
            style: TextStyle(fontSize: 15, color: AppTheme.textSecondaryColor),
          ),
        ),
        SizedBox(height: 6),
        Center(
          child: Text(
            'Hãy quay lại sau hoặc bỏ bớt bộ lọc',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 56, color: AppTheme.textSecondaryColor),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondaryColor),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}
