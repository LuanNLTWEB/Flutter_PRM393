import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/repair_request_model.dart';
import '../../../quotations/presentation/screens/request_quotations_screen.dart';

/// Card hiển thị thông tin và trạng thái một phiếu yêu cầu sửa chữa (UC-REQ-07, 08, 09)
class RequestItemCardWidget extends StatelessWidget {
  final RepairRequestModel request;
  final VoidCallback? onDetailPressed;

  const RequestItemCardWidget({
    super.key,
    required this.request,
    this.onDetailPressed,
  });

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year lúc $hour:$minute';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'OPEN':
        return Colors.orange.shade700;
      case 'QUOTED':
        return Colors.blue.shade700;
      case 'ACCEPTED':
        return Colors.green.shade700;
      case 'ON_THE_WAY':
        return Colors.indigo.shade600;
      case 'ARRIVED':
        return Colors.amber.shade800;
      case 'IN_PROGRESS':
        return Colors.teal.shade700;
      case 'COMPLETED':
        return Colors.green.shade800;
      case 'CANCELLED':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'OPEN':
        return Colors.orange.shade50;
      case 'QUOTED':
        return Colors.blue.shade50;
      case 'ACCEPTED':
        return Colors.green.shade50;
      case 'ON_THE_WAY':
        return Colors.indigo.shade50;
      case 'ARRIVED':
        return Colors.amber.shade50;
      case 'IN_PROGRESS':
        return Colors.teal.shade50;
      case 'COMPLETED':
        return Colors.green.shade50;
      case 'CANCELLED':
        return Colors.red.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency) {
      case 'low':
        return Colors.green.shade600;
      case 'medium':
        return Colors.blue.shade600;
      case 'high':
        return Colors.orange.shade700;
      case 'emergency':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  bool get _canViewQuotes =>
      request.status == 'OPEN' ||
      request.status == 'QUOTED' ||
      request.quotesCount > 0;

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(request.status);
    final statusBgColor = _getStatusBgColor(request.status);
    final urgencyColor = _getUrgencyColor(request.urgency);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onDetailPressed,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header: Tên danh mục dịch vụ & Badge Trạng thái ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.handyman_rounded,
                        color: AppTheme.primaryColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.serviceCategory?.name ?? 'Dịch vụ sửa chữa',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDateTime(request.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Badge trạng thái
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            request.statusDisplay,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Tiêu đề sự cố ──
                Text(
                  request.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // ── Mô tả sự cố tóm tắt ──
                Text(
                  request.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

                // ── Hàng ảnh thumbnail đính kèm (nếu có) ──
                if (request.images.isNotEmpty) ...[
                  SizedBox(
                    height: 52,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: request.images.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (ctx, idx) {
                        final imgUrl = request.images[idx];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imgUrl,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 52,
                              height: 52,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image, size: 20, color: Colors.grey),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // ── Thông tin địa chỉ & lịch hẹn ──
                if (request.location.address.isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_outlined, size: 15, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          request.location.address,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],

                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      request.preferredTime != null
                          ? 'Hẹn: ${_formatDateTime(request.preferredTime!)}'
                          : 'Hẹn: Sớm nhất có thể',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                    const Spacer(),
                    // Badge mức độ khẩn cấp
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: urgencyColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        request.urgencyDisplay,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: urgencyColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Thanh thông báo báo giá (UC-REQ-07 & UC-QUO-06) ──
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: request.quotesCount > 0
                        ? Colors.blue.shade50
                        : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: request.quotesCount > 0
                          ? Colors.blue.shade200
                          : Colors.amber.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        request.quotesCount > 0
                            ? Icons.local_offer_rounded
                            : Icons.hourglass_top_rounded,
                        size: 16,
                        color: request.quotesCount > 0
                            ? Colors.blue.shade700
                            : Colors.amber.shade800,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          request.quotesCount > 0
                              ? 'Đã có ${request.quotesCount} báo giá từ thợ'
                              : 'Đang mở - Chờ thợ gửi báo giá...',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: request.quotesCount > 0
                                ? Colors.blue.shade900
                                : Colors.amber.shade900,
                          ),
                        ),
                      ),
                      if (_canViewQuotes)
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(0, 28),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: Colors.blue.shade800,
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
                          child: const Row(
                            children: [
                              Text(
                                'Xem báo giá',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              Icon(Icons.chevron_right, size: 16),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // ── Nút Thao tác ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: const Size(0, 34),
                      ),
                      icon: const Icon(Icons.visibility_outlined, size: 15),
                      label: const Text('Xem chi tiết', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      onPressed: onDetailPressed,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
