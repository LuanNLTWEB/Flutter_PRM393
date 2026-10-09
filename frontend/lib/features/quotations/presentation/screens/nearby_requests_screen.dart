import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../repair_request/data/models/repair_request_model.dart';
import '../../../repair_request/data/models/service_category_model.dart';
import '../../../repair_request/presentation/providers/repair_request_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final request = item.request;
    final quote = item.quote;

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
