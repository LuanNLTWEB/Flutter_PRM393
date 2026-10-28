import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/invoice_model.dart';
import '../providers/payment_provider.dart';
import '../../../quotations/presentation/widgets/quotation_format.dart';
import 'upload_parts_invoice_screen.dart';

class InvoiceScreen extends StatefulWidget {
  final String requestId;

  const InvoiceScreen({super.key, required this.requestId});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  final _dateFormat = DateFormat('HH:mm - dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInvoice());
  }

  Future<void> _loadInvoice() async {
    final token = context.read<AuthProvider>().token ?? '';
    await context.read<PaymentProvider>().fetchInvoice(
          token: token,
          requestId: widget.requestId,
        );
  }

  Future<void> _confirmCashPayment() async {
    final token = context.read<AuthProvider>().token ?? '';
    final success = await context.read<PaymentProvider>().selectPaymentMethod(
          token: token,
          requestId: widget.requestId,
          paymentMethod: 'CASH',
        );

    if (!mounted) return;
    final provider = context.read<PaymentProvider>();
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xác nhận thanh toán tiền mặt tại chỗ'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Không thể lưu lựa chọn'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _technicianConfirmPaymentReceived(InvoiceModel invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đã nhận tiền'),
        content: Text(
          'Bạn xác nhận đã nhận đủ ${formatVnd(invoice.total)} tiền mặt trực tiếp từ khách hàng?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Chưa nhận'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đã nhận đủ tiền'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final token = context.read<AuthProvider>().token ?? '';
    final success = await context.read<PaymentProvider>().confirmPaymentReceived(
          token: token,
          requestId: widget.requestId,
        );

    if (!mounted) return;
    final provider = context.read<PaymentProvider>();
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xác nhận thu tiền mặt thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Không thể xác nhận thanh toán',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaymentProvider>();
    final auth = context.watch<AuthProvider>();
    final invoice = provider.invoice;
    final isTech = auth.currentUser?.role == 'technician';

    return Scaffold(
      appBar: AppBar(title: const Text('Bảng kê & Quyết toán')),
      body: provider.isLoading && invoice == null
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null && invoice == null
              ? _buildError(provider.errorMessage!)
              : invoice == null
                  ? const Center(child: Text('Chưa có dữ liệu quyết toán'))
                  : RefreshIndicator(
                      onRefresh: _loadInvoice,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildPaidBanner(invoice),
                          _buildInvoiceHeader(invoice),
                          const SizedBox(height: 12),
                          _buildPriceCard(invoice),
                          const SizedBox(height: 12),
                          if (invoice.completionImages.isNotEmpty) ...[
                            _buildCompletionImages(invoice),
                            const SizedBox(height: 12),
                          ],
                          _buildPartsInvoiceSection(invoice, isTech),
                          const SizedBox(height: 12),
                          _buildPaymentCashSection(
                            invoice: invoice,
                            isSubmitting: provider.isSubmitting,
                            isTech: isTech,
                          ),
                          if (isTech && !invoice.isPaid) ...[
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text(
                                'Xác nhận đã nhận đủ tiền mặt (UC-PAY-04)',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: provider.isSubmitting
                                  ? null
                                  : () => _technicianConfirmPaymentReceived(invoice),
                            ),
                          ],
                        ],
                      ),
                    ),
    );
  }

  Widget _buildPaidBanner(InvoiceModel invoice) {
    if (!invoice.isPaid) return const SizedBox.shrink();

    final paidTimeStr = invoice.paidAt != null
        ? _dateFormat.format(invoice.paidAt!)
        : 'Đã hoàn tất';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: Colors.green.shade700, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ĐÃ THANH TOÁN TIỀN MẶT',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Thợ đã xác nhận thu tiền lúc $paidTimeStr',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
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
            const Icon(Icons.error_outline, color: Colors.red, size: 42),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _loadInvoice, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceHeader(InvoiceModel invoice) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            invoice.serviceCategoryName,
            style: const TextStyle(color: AppTheme.primaryColor, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            invoice.serviceTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                backgroundImage: invoice.technicianAvatar.isNotEmpty
                    ? NetworkImage(invoice.technicianAvatar)
                    : null,
                child: invoice.technicianAvatar.isEmpty
                    ? const Icon(Icons.engineering_outlined,
                        color: AppTheme.primaryColor)
                    : null,
              ),
              const SizedBox(width: 10),
              Text(
                invoice.technicianName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(InvoiceModel invoice) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _priceRow('Tiền công thợ', invoice.labourCost),
          const SizedBox(height: 10),
          _priceRow('Tiền linh kiện / phụ tùng', invoice.partsCost),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng quyết toán',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                formatVnd(invoice.total),
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondaryColor)),
        Text(formatVnd(value),
            style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildCompletionImages(InvoiceModel invoice) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ảnh nghiệm thu sau khi sửa',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: invoice.completionImages
                .map(
                  (url) => ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      url,
                      width: 92,
                      height: 92,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPartsInvoiceSection(InvoiceModel invoice, bool isTech) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 20, color: AppTheme.primaryColor),
                  SizedBox(width: 8),
                  Text(
                    'Hóa đơn / Chứng từ linh kiện (UC-PAY-03)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              if (isTech && invoice.partsInvoiceImages.length < 5)
                TextButton.icon(
                  icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                  label: const Text('Thêm ảnh', style: TextStyle(fontSize: 12)),
                  onPressed: () async {
                    final updated = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UploadPartsInvoiceScreen(
                          requestId: invoice.requestId,
                          title: invoice.serviceTitle,
                          existingImageCount: invoice.partsInvoiceImages.length,
                        ),
                      ),
                    );
                    if (updated == true) _loadInvoice();
                  },
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (invoice.partsInvoiceImages.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Text(
                'Thợ chưa đính kèm ảnh hóa đơn mua linh kiện thay thế.',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: invoice.partsInvoiceImages
                  .map(
                    (url) => ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        url,
                        width: 92,
                        height: 92,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentCashSection({
    required InvoiceModel invoice,
    required bool isSubmitting,
    required bool isTech,
  }) {
    final isCashConfirmed = invoice.paymentMethod == 'CASH';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hình thức thanh toán (UC-PAY-02)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.payments_outlined,
                    color: AppTheme.primaryColor, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tiền mặt trực tiếp tại chỗ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Khách trả tiền mặt trực tiếp cho thợ sau khi đối soát xong.',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondaryColor),
                      ),
                    ],
                  ),
                ),
                if (isCashConfirmed)
                  const Icon(Icons.check_circle, color: Colors.green, size: 22),
              ],
            ),
          ),
          if (!isTech && !isCashConfirmed && !invoice.isPaid) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_outlined),
                label: const Text('Xác nhận thanh toán tiền mặt tại chỗ'),
                onPressed: isSubmitting ? null : _confirmCashPayment,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
