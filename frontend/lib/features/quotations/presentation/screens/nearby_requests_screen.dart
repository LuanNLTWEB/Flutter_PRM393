import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/directions.dart';
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
class NearbyRequestsScreen extends StatefulWidget {
  const NearbyRequestsScreen({super.key});

  @override
  State<NearbyRequestsScreen> createState() => _NearbyRequestsScreenState();
}

class _NearbyRequestsScreenState extends State<NearbyRequestsScreen> {
  String? _selectedSlug;

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

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<RepairRequestProvider>().rawCategories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yêu cầu quanh đây'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh),
            onPressed: () => _load(refresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(categories),
          Expanded(
            child: Consumer<QuotationProvider>(
              builder: (context, provider, _) {
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
                        // Gửi/thu hồi báo giá ở màn chi tiết sẽ đổi trạng thái
                        // phiếu, nên phải tải lại feed khi quay lại.
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RequestDetailScreen(
                                requestId: request.id,
                                request: request,
                              ),
                            ),
                          );
                          if (context.mounted) _load(refresh: true);
                        },
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
                        setState(
                          () => _selectedSlug = _selectedSlug == category.slug
                              ? null
                              : category.slug,
                        );
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
        color: (hasLocation ? Colors.green : Colors.orange).withValues(
          alpha: 0.08,
        ),
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

  /// Mở Google Maps chỉ đường tới nhà khách (UC-MAP-01)
  Future<void> _openDirections(BuildContext context) async {
    final loc = request.location;
    final ok = await openGoogleMapsDirections(
      latitude: loc.latitude,
      longitude: loc.longitude,
      address: loc.address,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không mở được Google Maps — chưa có địa chỉ khách'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: urgencyColor(request.urgency)
                        .withValues(alpha: 0.12),
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
            if (request.hasQuoted || request.quotesCount > 0) ...[
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (request.hasQuoted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 12,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Đã báo giá của bạn',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (request.quotesCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${request.quotesCount} thợ đã báo giá',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                if (request.location.address.isNotEmpty) ...[
                  // Đã được chốt — thấy địa chỉ + nút mở Google Maps (UC-MAP-01)
                  const Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      request.location.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.navigation_outlined, size: 15),
                    label: const Text(
                      'Chỉ đường',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: () => _openDirections(context),
                  ),
                ] else ...[
                  const Icon(
                    Icons.lock_outline,
                    size: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Địa chỉ & SĐT ẩn đến khi được chốt',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
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

// Kept for the quotation-card UI shared by the technician workflow.
// ignore: unused_element
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
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : AppTheme.primaryColor,
            ),
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

// The quotation-card UI remains available for the technician workflow,
// while its former standalone tab is no longer shown.
// ignore: unused_element
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _appointmentStatusColor.withValues(alpha: 0.1),
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
                const Icon(
                  Icons.schedule,
                  size: 14,
                  color: AppTheme.textSecondaryColor,
                ),
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
                Icon(Icons.swap_horiz, size: 14, color: Colors.orange.shade700),
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
                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.cancel_outlined,
                    size: 14,
                    color: Colors.red.shade700,
                  ),
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
            // Giờ hẹn đã qua — không thể xác nhận, cần đề xuất khung giờ mới
            if (_isPreferredTimePast) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: Colors.red.shade700,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Giờ hẹn đã qua — hãy bấm "Đổi lịch hẹn" để đề xuất khung giờ mới.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.red.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
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
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
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
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed:
                          (provider.isSubmitting ||
                              request.preferredTime == null ||
                              _isPreferredTimePast)
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
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
                onPressed: provider.isSubmitting
                    ? null
                    : () => _markOnTheWay(context),
              ),
            ),
          ] else if (request.status == 'ON_THE_WAY') ...[
            // Đã bấm di chuyển — hiển thị trạng thái + nút báo đã đến (UC-ARR-01)
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
                  Icon(Icons.navigation, size: 14, color: Colors.blue.shade700),
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
            const SizedBox(height: 8),
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
                onPressed: provider.isSubmitting
                    ? null
                    : () => _markArrived(context),
              ),
            ),
          ] else if (request.status == 'ARRIVED') ...[
            // Đã có mặt — thợ bấm bắt đầu sửa chữa (UC-WRK-02)
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade400),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.place_outlined,
                    size: 14,
                    color: Colors.amber.shade800,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Bạn đã có mặt tại hiện trường',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
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
                onPressed: provider.isSubmitting
                    ? null
                    : () => _markWorking(context),
              ),
            ),
          ] else if (request.status == 'IN_PROGRESS') ...[
            // Đã có mặt — đang sửa chữa
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.indigo.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.home_repair_service_outlined,
                    size: 14,
                    color: Colors.indigo.shade700,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Bạn đang sửa chữa tại hiện trường',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Chi phí phát sinh đã khai báo (UC-WRK-05)
            if (request.additionalCosts.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...request.additionalCosts.map(_buildCostTile),
            ],
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
                icon: const Icon(Icons.add_card_outlined, size: 16),
                label: const Text(
                  'Khai báo chi phí phát sinh',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
                onPressed: provider.isSubmitting
                    ? null
                    : () => _declareAdditionalCost(context),
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
                onPressed: provider.isSubmitting
                    ? null
                    : () => _cancelOnsite(context),
                child: const Text(
                  'Báo hủy tại chỗ',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
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

  /// Giờ hẹn khách đề xuất đã qua — không thể xác nhận nữa
  bool get _isPreferredTimePast {
    final t = item.request.preferredTime;
    return t != null && t.isBefore(DateTime.now());
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
              : (provider.errorMessage ??
                    'Cập nhật trạng thái di chuyển thất bại'),
        ),
        backgroundColor: ok ? Colors.blue.shade700 : Colors.red.shade600,
      ),
    );
  }

  /// Thợ bấm "Đã có mặt tại hiện trường" (UC-ARR-01)
  Future<void> _markArrived(BuildContext context) async {
    final token = context.read<AuthProvider>().token ?? '';
    if (token.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đã có mặt?'),
        content: const Text(
          'Bạn xác nhận đã có mặt tại nhà khách? Đơn sẽ chuyển sang trạng thái Đang sửa chữa và khách sẽ được thông báo.',
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
    if (confirmed != true || !context.mounted) return;

    final provider = context.read<QuotationProvider>();
    final ok = await provider.markArrived(
      token: token,
      requestId: item.request.id,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (provider.successMessage ?? 'Đã cập nhật trạng thái đã có mặt')
              : (provider.errorMessage ??
                    'Cập nhật trạng thái đã có mặt thất bại'),
        ),
        backgroundColor: ok ? Colors.indigo.shade700 : Colors.red.shade600,
      ),
    );
  }

  /// Thợ bấm "Bắt đầu sửa chữa" (UC-WRK-02)
  Future<void> _markWorking(BuildContext context) async {
    final token = context.read<AuthProvider>().token ?? '';
    if (token.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Bắt đầu sửa chữa?'),
        content: const Text(
          'Bạn xác nhận bắt đầu sửa chữa? Đơn sẽ chuyển sang trạng thái Đang sửa chữa và khách sẽ được thông báo.',
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
    if (confirmed != true || !context.mounted) return;

    final provider = context.read<QuotationProvider>();
    final ok = await provider.markWorking(
      token: token,
      requestId: item.request.id,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (provider.successMessage ?? 'Đã cập nhật: đang sửa chữa')
              : (provider.errorMessage ?? 'Cập nhật trạng thái thất bại'),
        ),
        backgroundColor: ok ? Colors.teal.shade700 : Colors.red.shade600,
      ),
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
                  '${formatVnd(cost.unitPrice)}/cái',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Thành tiền: ${formatVnd(cost.total)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
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

  /// Thợ khai báo chi phí phát sinh — nhiều mục trong 1 lần (UC-WRK-05)
  Future<void> _declareAdditionalCost(BuildContext context) async {
    final token = context.read<AuthProvider>().token ?? '';
    if (token.isEmpty) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _DeclareCostDialog(),
    );
    if (result == null || !context.mounted) return;

    final items = (result['items'] as List).cast<Map<String, dynamic>>();
    final note = result['note'] as String? ?? '';
    final provider = context.read<QuotationProvider>();
    final ok = await provider.declareAdditionalCost(
      token: token,
      requestId: item.request.id,
      items: items,
      note: note,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (provider.successMessage ?? 'Đã khai báo chi phí phát sinh')
              : (provider.errorMessage ?? 'Khai báo chi phí thất bại'),
        ),
        backgroundColor: ok ? Colors.orange.shade700 : Colors.red.shade600,
      ),
    );
  }

  Future<void> _cancelOnsite(BuildContext context) async {
    final token = context.read<AuthProvider>().token ?? '';
    if (token.isEmpty) return;

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
    if (reason == null || !context.mounted) return;

    final provider = context.read<QuotationProvider>();
    final ok = await provider.cancelOnsite(
      token: token,
      requestId: item.request.id,
      reason: reason,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (provider.successMessage ?? 'Đã báo hủy tại chỗ')
              : (provider.errorMessage ?? 'Báo hủy tại chỗ thất bại'),
        ),
        backgroundColor: ok ? Colors.green.shade700 : Colors.red.shade600,
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

    if (proposed == null || !context.mounted) return;

    // Mirror validate backend: ≥15 phút, ≤14 ngày
    final now = DateTime.now();
    if (!proposed.isAfter(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Khung giờ đề xuất phải ở tương lai'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (proposed.isBefore(now.add(const Duration(minutes: 15)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Khung giờ đề xuất cần cách hiện tại ít nhất 15 phút'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (proposed.isAfter(now.add(const Duration(days: 14)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Khung giờ đề xuất không được vượt quá 14 ngày'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: urgencyColor(request.urgency)
                        .withValues(alpha: 0.12),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
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
            // Chỉ hiện khu vực lịch hẹn khi đơn đang trong tiến trình xử lý
            if (isWon &&
                [
                  'ACCEPTED',
                  'ON_THE_WAY',
                  'ARRIVED',
                  'IN_PROGRESS',
                ].contains(request.status))
              _buildAppointmentSection(context),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _MyQuotesEmptyState extends StatelessWidget {
  const _MyQuotesEmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        SizedBox(height: 80),
        Icon(
          Icons.request_quote_outlined,
          size: 64,
          color: AppTheme.textSecondaryColor,
        ),
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
        Icon(
          Icons.inbox_outlined,
          size: 64,
          color: AppTheme.textSecondaryColor,
        ),
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
            const Icon(
              Icons.error_outline,
              size: 56,
              color: AppTheme.textSecondaryColor,
            ),
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
