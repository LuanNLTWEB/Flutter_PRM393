import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/completion_qr_model.dart';
import '../providers/completion_provider.dart';

class ScanCompletionQrScreen extends StatefulWidget {
  final String expectedRequestId;
  final String title;

  const ScanCompletionQrScreen({
    super.key,
    required this.expectedRequestId,
    required this.title,
  });

  @override
  State<ScanCompletionQrScreen> createState() => _ScanCompletionQrScreenState();
}

class _ScanCompletionQrScreenState extends State<ScanCompletionQrScreen> {
  late final MobileScannerController _scannerController;
  bool _handlingScan = false;

  final _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: const [BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleDetection(BarcodeCapture capture) async {
    if (_handlingScan) return;

    String? rawValue;
    for (final barcode in capture.barcodes) {
      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        rawValue = barcode.rawValue;
        break;
      }
    }
    if (rawValue == null) return;

    _handlingScan = true;
    await _scannerController.stop();
    if (!mounted) return;

    final payload = CompletionQrPayload.tryParse(rawValue);
    if (payload == null) {
      _showError('Đây không phải QR nghiệm thu hợp lệ của HomeFix');
      await _resumeScanner();
      return;
    }

    if (payload.requestId != widget.expectedRequestId) {
      _showError('QR này thuộc một đơn hàng khác');
      await _resumeScanner();
      return;
    }

    final shouldConfirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận nghiệm thu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title),
            const SizedBox(height: 12),
            Text('Mã đơn: ${payload.requestId}'),
            const SizedBox(height: 6),
            Text(
              'Số tiền chốt: ${_currencyFormat.format(payload.amount)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Chỉ xác nhận khi thiết bị đã hoạt động bình thường và bạn đồng ý nghiệm thu.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Quét lại'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xác nhận hoàn tất'),
          ),
        ],
      ),
    );

    if (shouldConfirm != true) {
      await _resumeScanner();
      return;
    }

    if (!mounted) return;
    final authToken = context.read<AuthProvider>().token;
    if (authToken == null) {
      _showError('Phiên đăng nhập đã hết hạn');
      await _resumeScanner();
      return;
    }

    final completionProvider = context.read<CompletionProvider>();
    final success = await completionProvider.confirmCompletion(
      token: authToken,
      payload: payload,
    );
    if (!mounted) return;

    if (success) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
          title: const Text('Nghiệm thu thành công'),
          content: const Text(
            'Đơn hàng đã được chuyển sang trạng thái Đã hoàn tất.',
            textAlign: TextAlign.center,
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context, true);
      return;
    }

    final message =
        completionProvider.errorMessage ?? 'Không thể xác nhận nghiệm thu';
    _showError(message);
    await _resumeScanner();
  }

  Future<void> _resumeScanner() async {
    if (!mounted) return;
    _handlingScan = false;
    await _scannerController.start();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isConfirming = context.watch<CompletionProvider>().isConfirming;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét QR nghiệm thu'),
        actions: [
          IconButton(
            tooltip: 'Bật/tắt đèn flash',
            onPressed: () => _scannerController.toggleTorch(),
            icon: const Icon(Icons.flash_on_outlined),
          ),
          IconButton(
            tooltip: 'Đổi camera',
            onPressed: () => _scannerController.switchCamera(),
            icon: const Icon(Icons.cameraswitch_outlined),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleDetection,
            errorBuilder: (context, error) => Container(
              color: Colors.black,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(24),
              child: const Text(
                'Không thể mở camera. Hãy cấp quyền Camera cho HomeFix rồi thử lại.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          IgnorePointer(
            child: Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 3),
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 36,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Đưa QR nghiệm thu của thợ vào giữa khung hình',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          if (isConfirming)
            Container(
              color: Colors.black.withValues(alpha: 0.55),
              alignment: Alignment.center,
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    'Đang xác nhận nghiệm thu...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
