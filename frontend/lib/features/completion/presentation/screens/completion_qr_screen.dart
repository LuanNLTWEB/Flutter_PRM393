import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/completion_provider.dart';

class CompletionQrScreen extends StatefulWidget {
  final String requestId;
  final String title;

  const CompletionQrScreen({
    super.key,
    required this.requestId,
    required this.title,
  });

  @override
  State<CompletionQrScreen> createState() => _CompletionQrScreenState();
}

class _CompletionQrScreenState extends State<CompletionQrScreen> {
  final _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );
  final _dateFormat = DateFormat('HH:mm dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _generateQr());
  }

  Future<void> _generateQr() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    await context.read<CompletionProvider>().generateCompletionQr(
      token: token,
      requestId: widget.requestId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CompletionProvider>();
    final qr = provider.confirmationQr;

    return Scaffold(
      appBar: AppBar(title: const Text('QR nghiệm thu')),
      body: SafeArea(
        child: provider.isGeneratingQr
            ? const Center(child: CircularProgressIndicator())
            : provider.errorMessage != null && qr == null
            ? _buildError(provider.errorMessage!)
            : qr == null
            ? _buildError('Không nhận được mã QR nghiệm thu')
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mã đơn: ${qr.requestId}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: qr.payload,
                          version: QrVersions.auto,
                          size: 260,
                          errorCorrectionLevel: QrErrorCorrectLevel.M,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 0,
                      color: AppTheme.primaryColor.withValues(alpha: 0.06),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              'Số tiền chốt',
                              style: TextStyle(
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currencyFormat.format(qr.amount),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Hết hạn: ${_dateFormat.format(qr.expiresAt)}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Đưa mã này cho đúng khách hàng quét trong ứng dụng HomeFix. Mỗi lần tạo mã mới, mã cũ sẽ hết hiệu lực.',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: provider.isGeneratingQr ? null : _generateQr,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tạo mã QR mới'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_2, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _generateQr,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
