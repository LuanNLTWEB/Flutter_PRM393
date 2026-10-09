import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../repair_request/data/models/repair_request_model.dart';
import '../../data/models/quotation_model.dart';
import '../../domain/quotation_comparator.dart';
import '../providers/quotation_provider.dart';
import '../widgets/quotation_format.dart';
import '../widgets/send_quotation_sheet.dart';

/// Danh sách báo giá của 1 yêu cầu (UC-QUO-06)
/// Bảng so sánh & chọn thợ (UC-QUO-07, UC-QUO-08, UC-QUO-09)
class RequestQuotationsScreen extends StatefulWidget {
  final String requestId;
  final RepairRequestModel? request;

  const RequestQuotationsScreen({
    super.key,
    required this.requestId,
    this.request,
  });

  @override
  State<RequestQuotationsScreen> createState() =>
      _RequestQuotationsScreenState();
}

class _RequestQuotationsScreenState extends State<RequestQuotationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().token ?? '';
    if (token.isEmpty) return;
    await context
        .read<QuotationProvider>()
        .fetchQuotations(token: token, requestId: widget.requestId);
  }

  Future<void> _accept(QuotationModel quote) async {
    final confirmed = await _confirm(
      title: 'Chọn thợ này?',
      message:
          'Bạn đang chốt với ${quote.technicianName.isEmpty ? 'thợ' : quote.technicianName} '
          'với tổng ${formatVnd(quote.total)}. Các báo giá khác sẽ tự động bị từ chối.',
      confirmLabel: 'Chốt thợ',
    );
    if (confirmed != true || !mounted) return;

    final token = context.read<AuthProvider>().token ?? '';
    await context
        .read<QuotationProvider>()
        .acceptQuotation(token: token, id: quote.id);
    if (mounted) await _load();
  }

  Future<void> _reject(QuotationModel quote) async {
    final confirmed = await _confirm(
      title: 'Từ chối báo giá?',
      message: 'Bạn có chắc muốn từ chối báo giá của '
          '${quote.technicianName.isEmpty ? 'thợ này' : quote.technicianName}?',
      confirmLabel: 'Từ chối',
    );
    if (confirmed != true || !mounted) return;

    final token = context.read<AuthProvider>().token ?? '';
    await context
        .read<QuotationProvider>()
        .rejectQuotation(token: token, id: quote.id);
    if (mounted) await _load();
  }

  Future<void> _retract(QuotationModel quote) async {
    final confirmed = await _confirm(
      title: 'Thu hồi báo giá?',
      message: 'Khách hàng sẽ không còn thấy báo giá này. Bạn có thể gửi lại sau.',
      confirmLabel: 'Thu hồi',
    );
    if (confirmed != true || !mounted) return;

    final token = context.read<AuthProvider>().token ?? '';
    await context
        .read<QuotationProvider>()
        .retractQuotation(token: token, id: quote.id);
    if (mounted) await _load();
  }

  Future<void> _edit(QuotationModel quote) async {
    final success = await SendQuotationSheet.show(
      context,
      requestId: widget.requestId,
      existingQuote: quote,
    );
    if (success == true) await _load();
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final role = auth.currentUser?.role ?? '';
    final userId = auth.currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo giá nhận được'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: Consumer<QuotationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.quotations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && provider.quotations.isEmpty) {
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
                      provider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.textSecondaryColor),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(onPressed: _load, child: const Text('Thử lại')),
                  ],
                ),
              ),
            );
          }

          final quotes = provider.sortedQuotations;
          final best = QuotationComparator.bestValue(quotes);

          return RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _StatusBanner(
                  status: provider.requestStatus,
                  total: quotes.where((q) => q.status == 'SENT').length,
                ),
                if (quotes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SortBar(selected: provider.sortKey),
                ],
                const SizedBox(height: 12),
                if (quotes.isEmpty)
                  _buildEmpty(role)
                else
                  ...quotes.map(
                    (quote) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _QuotationCard(
                        quote: quote,
                        isBest: best != null && best.id == quote.id,
                        isOwnerTech:
                            role == 'technician' && quote.technicianId == userId,
                        canDecide:
                            role == 'user' && quote.status == 'SENT',
                        onAccept: () => _accept(quote),
                        onReject: () => _reject(quote),
                        onEdit: () => _edit(quote),
                        onRetract: () => _retract(quote),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty(String role) {
    final isTech = role == 'technician';
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(
            isTech ? Icons.request_quote_outlined : Icons.hourglass_empty,
            size: 64,
            color: AppTheme.textSecondaryColor,
          ),
          const SizedBox(height: 12),
          Text(
            isTech ? 'Bạn chưa gửi báo giá cho yêu cầu này' : 'Chưa có thợ nào báo giá',
            style: const TextStyle(fontSize: 15, color: AppTheme.textSecondaryColor),
          ),
          if (!isTech) ...[
            const SizedBox(height: 6),
            const Text(
              'Các thợ sẽ nhìn thấy yêu cầu của bạn và gửi báo giá',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String status;
  final int total;

  const _StatusBanner({required this.status, required this.total});

  @override
  Widget build(BuildContext context) {
    String text;
    Color color;
    switch (status) {
      case 'ACCEPTED':
        text = 'Đã chốt thợ — yêu cầu hoàn tất bước báo giá';
        color = Colors.green;
        break;
      case 'QUOTED':
        text = '$total báo giá đang chờ bạn xem xét';
        color = AppTheme.primaryColor;
        break;
      case 'CANCELLED':
        text = 'Yêu cầu đã bị hủy';
        color = Colors.red;
        break;
      default:
        text = 'Chưa có báo giá nào — chờ thợ phản hồi';
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _SortBar extends StatelessWidget {
  final QuotationSortKey selected;

  const _SortBar({required this.selected});

  String _label(QuotationSortKey key) {
    switch (key) {
      case QuotationSortKey.totalAsc:
        return 'Tổng thấp nhất';
      case QuotationSortKey.ratingDesc:
        return 'Đánh giá cao nhất';
      case QuotationSortKey.completedJobsDesc:
        return 'Nhiều kinh nghiệm';
      case QuotationSortKey.distanceAsc:
        return 'Gần nhất';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.sort, size: 18, color: AppTheme.textSecondaryColor),
        const SizedBox(width: 6),
        const Text(
          'So sánh theo:',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
        ),
        const SizedBox(width: 8),
        DropdownButton<QuotationSortKey>(
          value: selected,
          underline: const SizedBox.shrink(),
          isDense: true,
          items: QuotationSortKey.values
              .map(
                (key) => DropdownMenuItem(
                  value: key,
                  child: Text(
                    _label(key),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              )
              .toList(),
          onChanged: (key) {
            if (key != null) {
              context.read<QuotationProvider>().setSortKey(key);
            }
          },
        ),
      ],
    );
  }
}

class _QuotationCard extends StatelessWidget {
  final QuotationModel quote;
  final bool isBest;
  final bool isOwnerTech;
  final bool canDecide;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onEdit;
  final VoidCallback onRetract;

  const _QuotationCard({
    required this.quote,
    required this.isBest,
    required this.isOwnerTech,
    required this.canDecide,
    required this.onAccept,
    required this.onReject,
    required this.onEdit,
    required this.onRetract,
  });

  Widget _stars() {
    return Row(
      children: List.generate(5, (index) {
        final filled = index < quote.starRating;
        return Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 15,
          color: filled ? Colors.amber.shade700 : Colors.grey.shade400,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isBest
            ? Border.all(color: AppTheme.secondaryColor, width: 1.5)
            : null,
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
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    AppTheme.primaryColor.withValues(alpha: 0.1),
                backgroundImage: quote.technicianAvatar.isNotEmpty
                    ? NetworkImage(quote.technicianAvatar)
                    : null,
                child: quote.technicianAvatar.isEmpty
                    ? Text(
                        quote.technicianName.trim().isNotEmpty
                            ? quote.technicianName.trim()[0].toUpperCase()
                            : 'T',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            quote.technicianName.isEmpty
                                ? 'Thợ sửa'
                                : quote.technicianName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isBest) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Giá tốt nhất',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        _stars(),
                        const SizedBox(width: 6),
                        Text(
                          '${quote.rating.toStringAsFixed(1)} (${quote.reviewCount} đánh giá)',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _StatusChip(status: quote.status),
            ],
          ),
          if (quote.skills.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: quote.skills
                  .map(
                    (skill) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        skill,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const Divider(height: 20),
          _PriceRow(
            label: 'Tiền công',
            value: formatVnd(quote.labourCost),
          ),
          _PriceRow(
            label: 'Linh kiện',
            value: formatVnd(quote.partsCost),
          ),
          _PriceRow(
            label: 'Tổng cộng',
            value: formatVnd(quote.total),
            bold: true,
          ),
          _PriceRow(
            label: 'Kinh nghiệm',
            value: '${quote.completedJobsCount} đơn đã hoàn tất',
          ),
          if (quote.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                quote.note,
                style: const TextStyle(fontSize: 13, height: 1.45),
              ),
            ),
          ],
          if (canDecide || isOwnerTech) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (canDecide) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      child: const Text('Từ chối'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onAccept,
                      child: const Text('Chọn thợ này'),
                    ),
                  ),
                ],
                if (isOwnerTech && quote.canEdit) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onRetract,
                      child: const Text('Thu hồi'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onEdit,
                      child: const Text('Sửa báo giá'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _PriceRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: bold ? 14 : 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              color: bold ? AppTheme.textPrimaryColor : AppTheme.textSecondaryColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 15 : 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: bold ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    switch (status) {
      case 'ACCEPTED':
        color = Colors.green;
        text = 'Đã chốt';
        break;
      case 'REJECTED':
        color = Colors.red;
        text = 'Từ chối';
        break;
      case 'RETRACTED':
        color = Colors.grey;
        text = 'Thu hồi';
        break;
      case 'SENT':
      default:
        color = AppTheme.primaryColor;
        text = 'Chờ chốt';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
