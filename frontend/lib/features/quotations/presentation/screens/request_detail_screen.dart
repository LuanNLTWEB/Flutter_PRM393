import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../repair_request/data/models/repair_request_model.dart';
import '../../data/models/quotation_model.dart';
import '../providers/quotation_provider.dart';
import '../widgets/quotation_format.dart';
import '../widgets/send_quotation_sheet.dart';
import 'request_quotations_screen.dart';

/// Chi tiết 1 phiếu yêu cầu (UC-QUO-03)
/// Thợ: xem mô tả + ảnh phóng to, gửi báo giá (UC-QUO-04)
/// Khách: xem chi tiết, chuyển sang màn hình báo giá (UC-QUO-06)
class RequestDetailScreen extends StatefulWidget {
  final String requestId;
  final RepairRequestModel? request;

  const RequestDetailScreen({
    super.key,
    required this.requestId,
    this.request,
  });

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  RepairRequestModel? _request;
  QuotationModel? _myQuote;

  @override
  void initState() {
    super.initState();
    _request = widget.request;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token ?? '';
    if (token.isEmpty) return;

    final provider = context.read<QuotationProvider>();
    await provider.fetchRequestDetail(token: token, id: widget.requestId);
    if (!mounted) return;
    setState(() {
      _request = provider.selectedRequest ?? _request;
    });

    // Thợ lấy báo giá của chính mình để hiển thị trạng thái
    if (auth.currentUser?.role == 'technician') {
      await provider.fetchQuotations(token: token, requestId: widget.requestId);
      if (!mounted) return;
      final userId = auth.currentUser?.id ?? '';
      setState(() {
        _myQuote = provider.quotations
            .cast<QuotationModel?>()
            .firstWhere((q) => q?.technicianId == userId,
                orElse: () => null);
      });
    }
  }

  Future<void> _sendQuotation() async {
    final success = await SendQuotationSheet.show(
      context,
      requestId: widget.requestId,
      existingQuote: _myQuote != null && _myQuote!.canEdit ? _myQuote : null,
    );
    if (success == true) {
      await _load();
    }
  }

  Future<void> _retractQuotation() async {
    final quote = _myQuote;
    if (quote == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thu hồi báo giá'),
        content: const Text(
            'Khách hàng sẽ không còn thấy báo giá này. Bạn có thể gửi lại sau.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Thu hồi'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final token = context.read<AuthProvider>().token ?? '';
    await context
        .read<QuotationProvider>()
        .retractQuotation(token: token, id: quote.id);
    if (mounted) await _load();
  }

  void _openImage(String url) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Icon(Icons.broken_image,
                        color: Colors.white, size: 48),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = _request;
    final auth = context.watch<AuthProvider>();
    final role = auth.currentUser?.role ?? '';
    final isOwner =
        request != null && request.customerId == auth.currentUser?.id;

    if (request == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết yêu cầu')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(request),
          const SizedBox(height: 12),
          _buildSection(
            title: 'Mô tả sự cố',
            child: Text(
              request.description,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
          if (request.images.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSection(title: 'Ảnh hiện trường', child: _buildImages()),
          ],
          const SizedBox(height: 12),
          _buildSection(
            title: 'Địa chỉ sửa chữa',
            child: Text(
              request.location.address.isEmpty
                  ? 'Địa chỉ được bảo vệ đến khi thợ được chốt'
                  : request.location.address,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: request.location.address.isEmpty
                    ? AppTheme.textSecondaryColor
                    : AppTheme.textPrimaryColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildSection(
            title: 'Lịch hẹn',
            child: _buildAppointment(request),
          ),
          const SizedBox(height: 12),
          _buildSection(
            title: 'Liên hệ',
            child: Text(
              request.contactPhone.isEmpty
                  ? 'Số điện thoại được bảo vệ đến khi thợ được chốt'
                  : request.contactPhone,
              style: TextStyle(
                fontSize: 14,
                color: request.contactPhone.isEmpty
                    ? AppTheme.textSecondaryColor
                    : AppTheme.textPrimaryColor,
              ),
            ),
          ),
          if (request.customerNote.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSection(
              title: 'Ghi chú của khách',
              child: Text(request.customerNote,
                  style: const TextStyle(fontSize: 14, height: 1.5)),
            ),
          ],
          const SizedBox(height: 100),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(role, isOwner, request),
    );
  }

  Widget _buildHeader(RepairRequestModel request) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
              Text(
                request.serviceCategory?.name ?? 'Dịch vụ',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const Spacer(),
              Text(
                request.statusDisplay,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            request.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Đăng lúc ${timeAgo(request.createdAt)}',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  /// Lịch hẹn sửa chữa — để thợ biết khách muốn thợ đến lúc nào (UC-LIC-01)
  Widget _buildAppointment(RepairRequestModel request) {
    final t = request.preferredTime;
    final isPast = t != null && t.isBefore(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.schedule,
                size: 16,
                color: t == null
                    ? AppTheme.textSecondaryColor
                    : isPast
                        ? Colors.red.shade700
                        : AppTheme.primaryColor),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                t == null
                    ? 'Khách chưa chọn giờ hẹn'
                    : 'Khách mong muốn thợ đến: ${_formatDateTime(t)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: t == null
                      ? AppTheme.textSecondaryColor
                      : isPast
                          ? Colors.red.shade700
                          : AppTheme.textPrimaryColor,
                ),
              ),
            ),
          ],
        ),
        if (isPast) ...[
          const SizedBox(height: 4),
          Text(
            'Khung giờ này đã qua — lịch hẹn cần được đề xuất lại.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.red.shade700,
            ),
          ),
        ],
        if (request.appointmentStatus == 'CONFIRMED') ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.check_circle_outline,
                  size: 14, color: Colors.green.shade700),
              const SizedBox(width: 6),
              Text(
                'Lịch hẹn đã được xác nhận',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
        ],
        if (request.appointmentStatus == 'RESCHEDULED' &&
            request.proposedTime != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.swap_horiz,
                  size: 14, color: Colors.orange.shade700),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Thợ đề xuất khung giờ mới: '
                  '${_formatDateTime(request.proposedTime!)} (chờ khách phản hồi)',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/${dt.year} $hh:$mm';
  }

  Widget _buildImages() {
    final images = _request?.images ?? const <String>[];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: images
          .map(
            (url) => InkWell(
              onTap: () => _openImage(url),
              borderRadius: BorderRadius.circular(10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  url,
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 96,
                    height: 96,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image,
                        color: AppTheme.textSecondaryColor),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildBottomBar(String role, bool isOwner, RepairRequestModel request) {
    final canQuote = role == 'technician' &&
        (request.status == 'OPEN' || request.status == 'QUOTED');
    final showQuotesButton = isOwner && role == 'user';

    if (!canQuote && !showQuotesButton) return const SizedBox.shrink();

    // Thợ đã có báo giá nhưng không còn sửa được (đã bị khách từ chối) thì không
    // hiện nút "Gửi báo giá" nữa, vì backend sẽ trả 409 khi gửi lại lần hai.
    final myQuoteLive = _myQuote != null && _myQuote!.canEdit;
    final myQuoteClosed = _myQuote != null && !_myQuote!.canEdit;
    final canSubmitQuote = canQuote && !myQuoteClosed;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (canQuote && request.quotesCount > 0) ...[
              Text(
                'Có ${request.quotesCount} thợ đã báo giá cho yêu cầu này.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                if (showQuotesButton) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RequestQuotationsScreen(
                            requestId: request.id,
                            request: request,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.compare_arrows),
                      label: const Text('Xem báo giá'),
                    ),
                  ),
                ],
                if (myQuoteLive) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _retractQuotation,
                      icon: const Icon(Icons.undo),
                      label: const Text('Thu hồi'),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                if (canSubmitQuote)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _sendQuotation,
                      icon: const Icon(Icons.request_quote_outlined),
                      label: Text(myQuoteLive ? 'Sửa báo giá' : 'Gửi báo giá'),
                    ),
                  ),
                if (myQuoteClosed)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        'Báo giá của bạn: ${_myQuote!.statusDisplay.toLowerCase()}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondaryColor,
                        ),
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
