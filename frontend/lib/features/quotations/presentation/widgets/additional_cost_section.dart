import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../repair_request/data/models/repair_request_model.dart';
import '../providers/quotation_provider.dart';
import 'quotation_format.dart';

/// Danh sách chi phí phát sinh + nút Đồng ý / Từ chối dành cho Khách hàng
/// (UC-WRK-05 Thợ khai báo / UC-WRK-06 Khách phê duyệt)
class AdditionalCostsSection extends StatefulWidget {
  final String requestId;
  final List<AdditionalCostModel> costs;

  const AdditionalCostsSection({
    super.key,
    required this.requestId,
    required this.costs,
  });

  @override
  State<AdditionalCostsSection> createState() =>
      _AdditionalCostsSectionState();
}

class _AdditionalCostsSectionState extends State<AdditionalCostsSection> {
  late List<AdditionalCostModel> _costs = widget.costs;
  bool _busy = false;

  /// Khách đồng ý / từ chối 1 chi phí phát sinh (UC-WRK-06)
  Future<void> _respondToCost(
    AdditionalCostModel cost, {
    required bool approve,
  }) async {
    if (_busy) return;
    final token = context.read<AuthProvider>().token ?? '';
    if (token.isEmpty) return;

    var note = '';
    if (!approve) {
      final noteCtrl = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Từ chối chi phí phát sinh?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${cost.name}: ${formatVnd(cost.unitPrice)}/cái x${cost.quantity} = ${formatVnd(cost.total)}',
                style: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                maxLength: 300,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Lý do từ chối (tùy chọn)',
                  border: OutlineInputBorder(),
                  isDense: true,
                  counterText: '',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Quay lại'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Từ chối'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      note = noteCtrl.text.trim();
      noteCtrl.dispose();
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Đồng ý chi phí phát sinh?'),
          content: Text(
            'Bạn đồng ý trả ${formatVnd(cost.unitPrice)}/cái x${cost.quantity} '
            '= ${formatVnd(cost.total)} cho "${cost.name}"?',
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
              child: const Text('Đồng ý'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    if (!mounted) return;
    setState(() => _busy = true);
    final provider = context.read<QuotationProvider>();
    final ok = await provider.respondAdditionalCost(
      token: token,
      requestId: widget.requestId,
      costId: cost.id,
      action: approve ? 'APPROVE' : 'REJECT',
      note: note,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) {
        // Cập nhật local theo kết quả server đã lưu
        _costs = _costs
            .map((c) => c.id == cost.id
                ? c.copyWith(
                    status: approve ? 'APPROVED' : 'REJECTED',
                    customerNote: note,
                  )
                : c)
            .toList();
      }
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (provider.successMessage ?? 'Đã cập nhật chi phí phát sinh')
              : (provider.errorMessage ?? 'Phê duyệt chi phí thất bại'),
        ),
        backgroundColor: ok ? Colors.green.shade700 : Colors.red.shade600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chi phí phát sinh:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 8),
        ..._costs.map((cost) {
          final Color statusColor;
          switch (cost.status) {
            case 'APPROVED':
              statusColor = Colors.green.shade700;
              break;
            case 'REJECTED':
              statusColor = Colors.red.shade700;
              break;
            case 'PENDING':
            default:
              statusColor = Colors.orange.shade800;
              break;
          }

          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${cost.name} x${cost.quantity}',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${formatVnd(cost.unitPrice)}/cái',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Thành tiền: ${formatVnd(cost.total)}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (cost.note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Ghi chú thợ: ${cost.note}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: statusColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        cost.statusDisplay,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (cost.status == 'REJECTED' &&
                    cost.customerNote.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Lý do từ chối: ${cost.customerNote}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
                if (!_busy && cost.isPending) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            side: BorderSide(color: Colors.red.shade300),
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () =>
                              _respondToCost(cost, approve: false),
                          child: const Text(
                            'Từ chối',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () =>
                              _respondToCost(cost, approve: true),
                          child: const Text(
                            'Đồng ý',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}
