import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/repair_request_model.dart';
import '../../../home/presentation/home_screen.dart';
import '../../../quotations/presentation/screens/request_quotations_screen.dart';

/// Màn hình thông báo gửi yêu cầu thành công
class RequestSuccessScreen extends StatelessWidget {
  final RepairRequestModel request;

  const RequestSuccessScreen({super.key, required this.request});

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} lúc ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              // ── Icon thành công ──
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 56,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Yêu cầu đã được gửi!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Chúng tôi đã nhận được yêu cầu sửa chữa của bạn.\nĐội ngũ sẽ liên hệ xác nhận trong thời gian sớm nhất.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // ── Card tóm tắt yêu cầu ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
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
                    _buildInfoRow(
                      icon: Icons.home_repair_service_rounded,
                      label: 'Dịch vụ',
                      value: request.serviceCategory?.name ?? 'Dịch vụ sửa chữa',
                      color: AppTheme.primaryColor,
                    ),
                    _buildInfoRow(
                      icon: Icons.title_rounded,
                      label: 'Tiêu đề',
                      value: request.title,
                    ),
                    const Divider(height: 20),
                    _buildInfoRow(
                      icon: Icons.speed_rounded,
                      label: 'Mức độ',
                      value: request.urgencyDisplay,
                    ),
                    if (request.location.address.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        icon: Icons.location_on_outlined,
                        label: 'Địa chỉ',
                        value: request.location.address,
                      ),
                    ],
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.event_available_rounded,
                      label: 'Thời gian hẹn',
                      value: request.preferredTime != null
                          ? _formatDateTime(request.preferredTime!)
                          : 'Sớm nhất có thể',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.info_outline_rounded,
                      label: 'Trạng thái',
                      value: request.statusDisplay,
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // ── Nút theo dõi báo giá (UC-QUO-06) ──
              OutlinedButton.icon(
                key: const Key('request_success_quotes_btn'),
                icon: const Icon(Icons.request_quote_outlined),
                label: const Text(
                  'Theo dõi báo giá',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
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
              const SizedBox(height: 12),

              // ── Nút Về trang chủ ──
              ElevatedButton.icon(
                key: const Key('request_success_home_btn'),
                icon: const Icon(Icons.home_rounded),
                label: const Text(
                  'Về trang chủ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color ?? Colors.grey.shade500),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
            ),
            const SizedBox(height: 2),
            SizedBox(
              width: 260,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color ?? AppTheme.textPrimaryColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
