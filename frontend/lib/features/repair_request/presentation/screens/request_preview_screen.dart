import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/service_category_model.dart';
import '../providers/repair_request_provider.dart';
import 'request_success_screen.dart';

/// UC-REQ-06: Màn hình xem lại tóm tắt phiếu yêu cầu trước khi đăng
class RequestPreviewScreen extends StatelessWidget {
  final ServiceCategoryModel category;
  final String title;
  final String description;
  final String urgency;
  final DateTime preferredTime;
  final List<XFile> images;
  final String address;
  final double? latitude;
  final double? longitude;

  const RequestPreviewScreen({
    super.key,
    required this.category,
    required this.title,
    required this.description,
    required this.urgency,
    required this.preferredTime,
    this.images = const [],
    required this.address,
    this.latitude,
    this.longitude,
  });

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year lúc $hour:$minute';
  }

  String get _urgencyLabel {
    switch (urgency) {
      case 'low':
        return 'Thấp';
      case 'medium':
        return 'Bình thường';
      case 'high':
        return 'Khẩn cấp';
      case 'emergency':
        return 'Cực kỳ khẩn cấp';
      default:
        return 'Bình thường';
    }
  }

  Color get _urgencyColor {
    switch (urgency) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.blue;
      case 'high':
        return Colors.orange;
      case 'emergency':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Future<void> _handleConfirmSubmit(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final token = auth.token ?? '';
    final messenger = ScaffoldMessenger.of(context);

    if (token.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để đăng yêu cầu sửa chữa'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final provider = context.read<RepairRequestProvider>();
    final result = await provider.createRepairRequest(
      token: token,
      serviceCategoryId: category.id,
      title: title,
      description: description,
      urgency: urgency,
      preferredTime: preferredTime,
      images: images,
      address: address,
      latitude: latitude,
      longitude: longitude,
    );

    if (!context.mounted) return;

    if (result != null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => RequestSuccessScreen(request: result),
        ),
        (route) => route.isFirst,
      );
    } else {
      final error = provider.submitError ?? 'Không thể đăng yêu cầu sửa chữa. Vui lòng thử lại.';
      messenger.showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  void _showZoomImage(BuildContext context, XFile file) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: kIsWeb
              ? Image.network(file.path, fit: BoxFit.contain)
              : Image.file(File(file.path), fit: BoxFit.contain),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RepairRequestProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xem lại phiếu yêu cầu'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Thông báo lưu ý
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vui lòng kiểm tra lại thông tin trước khi đăng yêu cầu tìm thợ.',
                      style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card 1: Dịch vụ sửa chữa
            _buildSectionCard(
              title: 'Dịch vụ sửa chữa',
              icon: Icons.handyman,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.home_repair_service, color: AppTheme.primaryColor),
                ),
                title: Text(
                  category.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: category.basePrice > 0
                    ? Text(
                        'Giá sàn tham khảo: ${category.basePriceFormatted}',
                        style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w500),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 14),

            // Card 2: Nội dung sự cố
            _buildSectionCard(
              title: 'Chi tiết sự cố',
              icon: Icons.description_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Tiêu đề:', title, isBold: true),
                  const Divider(height: 16),
                  _buildDetailRow('Mô tả:', description),
                  const Divider(height: 16),
                  Row(
                    children: [
                      const Text('Mức độ khẩn cấp: ', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _urgencyColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _urgencyColor),
                        ),
                        child: Text(
                          _urgencyLabel,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _urgencyColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Card 3: Ảnh hiện trường
            _buildSectionCard(
              title: 'Ảnh hiện trường (${images.length})',
              icon: Icons.photo_library_outlined,
              child: images.isNotEmpty
                  ? SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (ctx, idx) {
                          final file = images[idx];
                          return GestureDetector(
                            onTap: () => _showZoomImage(context, file),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: kIsWeb
                                  ? Image.network(file.path, width: 80, height: 80, fit: BoxFit.cover)
                                  : Image.file(File(file.path), width: 80, height: 80, fit: BoxFit.cover),
                            ),
                          );
                        },
                      ),
                    )
                  : const Text(
                      'Không có ảnh hiện trường đính kèm',
                      style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 13),
                    ),
            ),
            const SizedBox(height: 14),

            // Card 4: Địa chỉ & Thời gian hẹn
            _buildSectionCard(
              title: 'Địa chỉ & Thời gian',
              icon: Icons.place_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Địa chỉ sửa chữa:', address),
                  const Divider(height: 16),
                  _buildDetailRow('Thời gian hẹn:', _formatDateTime(preferredTime)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Hai nút: Chỉnh sửa & Đăng yêu cầu
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    key: const Key('preview_request_edit_button'),
                    onPressed: provider.isSubmitting ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Chỉnh sửa'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    key: const Key('preview_request_confirm_button'),
                    onPressed: provider.isSubmitting ? null : () => _handleConfirmSubmit(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: provider.isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Đăng yêu cầu',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.primaryColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: AppTheme.textPrimaryColor,
          ),
        ),
      ],
    );
  }
}
