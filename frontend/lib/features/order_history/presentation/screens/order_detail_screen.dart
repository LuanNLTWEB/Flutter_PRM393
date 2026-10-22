import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../quotations/presentation/widgets/additional_cost_section.dart';
import '../../data/models/order_history_model.dart';
import '../providers/order_history_provider.dart';

/// Chi tiết 1 đơn trong "Lịch sử đơn" của Khách hàng.
/// Hiển thị thông tin đơn + phần phê duyệt chi phí phát sinh
/// (UC-WRK-05 Thợ khai báo / UC-WRK-06 Khách Đồng ý hoặc Từ chối).
class OrderDetailScreen extends StatelessWidget {
  final OrderHistoryModel order;

  const OrderDetailScreen({super.key, required this.order});

  Color _statusColor(String status) {
    switch (status) {
      case 'OPEN':
      case 'QUOTED':
        return Colors.orange.shade800;
      case 'ACCEPTED':
        return Colors.blue.shade700;
      case 'ON_THE_WAY':
        return Colors.indigo.shade600;
      case 'ARRIVED':
        return Colors.teal.shade700;
      case 'IN_PROGRESS':
        return Colors.deepOrange.shade700;
      case 'COMPLETED':
        return Colors.green.shade700;
      case 'CANCELLED':
        return Colors.red.shade700;
      default:
        return AppTheme.textSecondaryColor;
    }
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondaryColor,
      ),
    ),
  );

  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
  }) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 10),
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
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('HH:mm, dd/MM/yyyy').format(dt);
  }

  Future<void> _cancelOnsite(BuildContext context) async {
    final token = context.read<AuthProvider>().token ?? '';
    if (token.isEmpty) return;

    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Báo hủy tại chỗ?'),
        content: TextField(
          controller: reasonController,
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

    final provider = context.read<OrderHistoryProvider>();
    final ok = await provider.cancelOnsite(token, order.id, reason: reason);
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
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Chi tiết đơn hàng'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimaryColor,
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trạng thái & Danh mục
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                  const SizedBox(height: 10),
                  Text(
                    order.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Mô tả sự cố
            if (order.description.isNotEmpty) ...[
              _sectionTitle('Mô tả sự cố:'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  order.description,
                  style: const TextStyle(fontSize: 14, height: 1.45),
                ),
              ),
              const SizedBox(height: 14),
            ],

            _sectionTitle('Thông tin yêu cầu:'),
            _infoCard(
              icon: Icons.speed_rounded,
              label: 'Mức độ khẩn cấp',
              value: order.urgencyDisplay,
            ),
            _infoCard(
              icon: Icons.location_on_rounded,
              label: 'Địa chỉ sửa chữa',
              value: order.locationAddress,
            ),
            _infoCard(
              icon: Icons.event_available_rounded,
              label: 'Lịch hẹn mong muốn',
              value: order.preferredTime != null
                  ? _formatDate(order.preferredTime)
                  : 'Sớm nhất có thể',
            ),
            if (order.createdAt != null)
              _infoCard(
                icon: Icons.schedule,
                label: 'Ngày tạo đơn',
                value: dateFormat.format(order.createdAt!),
              ),

            // Thợ phụ trách
            if (order.assignedTechnicianName != null &&
                order.assignedTechnicianName!.isNotEmpty) ...[
              const SizedBox(height: 4),
              _sectionTitle('Thợ kỹ thuật:'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(0x1A2563EB),
                      child: Icon(
                        Icons.engineering_rounded,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        order.assignedTechnicianName!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (order.assignedTechnicianRating != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            order.assignedTechnicianRating!.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],

            // Đề xuất lịch mới của thợ
            if (order.proposedTime != null) ...[
              const SizedBox(height: 4),
              _sectionTitle('Lịch hẹn mới được đề xuất:'),
              _infoCard(
                icon: Icons.schedule,
                label: 'Thời gian đề xuất',
                value: _formatDate(order.proposedTime),
              ),
              if (order.rescheduleNote.isNotEmpty)
                _infoCard(
                  icon: Icons.notes_rounded,
                  label: 'Ghi chú của thợ',
                  value: order.rescheduleNote,
                ),
            ],

            if (order.status == 'ARRIVED' || order.status == 'IN_PROGRESS') ...[
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade300),
                  ),
                  child: const Text('Báo hủy tại chỗ'),
                  onPressed: () => _cancelOnsite(context),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Chi phí phát sinh — Khách Đồng ý / Từ chối (UC-WRK-06)
            if (order.additionalCosts.isNotEmpty ||
                order.status == 'IN_PROGRESS') ...[
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: AdditionalCostsSection(
                  requestId: order.id,
                  costs: order.additionalCosts,
                ),
              ),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}
