import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/invoice_model.dart';
import '../providers/payment_provider.dart';
import '../../../quotations/presentation/widgets/quotation_format.dart';

class InvoiceScreen extends StatefulWidget {
  final String requestId;

  const InvoiceScreen({super.key, required this.requestId});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
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

  Future<void> _selectMethod(String method) async {
    final token = context.read<AuthProvider>().token ?? '';
    final success = await context.read<PaymentProvider>().selectPaymentMethod(
          token: token,
          requestId: widget.requestId,
          paymentMethod: method,
        );

    if (!mounted) return;
    final provider = context.read<PaymentProvider>();
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Không thể lưu lựa chọn')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaymentProvider>();
    final invoice = provider.invoice;

    return Scaffold(
      appBar: AppBar(title: const Text('Hóa đơn & thanh toán')),
      body: provider.isLoading && invoice == null
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null && invoice == null
              ? _buildError(provider.errorMessage!)
              : invoice == null
                  ? const Center(child: Text('Chưa có dữ liệu hóa đơn'))
                  : RefreshIndicator(
                      onRefresh: _loadInvoice,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildInvoiceHeader(invoice),
                          const SizedBox(height: 12),
                          _buildPriceCard(invoice),
                          if (invoice.completionImages.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildCompletionImages(invoice),
                          ],
                          const SizedBox(height: 12),
                          _buildPaymentMethods(invoice, provider.isSubmitting),
                        ],
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
                    ? const Icon(Icons.engineering_outlined, color: AppTheme.primaryColor)
                    : null,
              ),
              const SizedBox(width: 10),
              Text(invoice.technicianName, style: const TextStyle(fontWeight: FontWeight.w600)),
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
          _priceRow('Tiền công', invoice.labourCost),
          const SizedBox(height: 10),
          _priceRow('Tiền đồ thay thế', invoice.partsCost),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng thanh toán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(
                formatVnd(invoice.total),
                style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 18),
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
        Text(formatVnd(value), style: const TextStyle(fontWeight: FontWeight.w600)),
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
          const Text('Ảnh sau khi sửa', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: invoice.completionImages
                .map(
                  (url) => ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(url, width: 92, height: 92, fit: BoxFit.cover),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods(InvoiceModel invoice, bool isSubmitting) {
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
          const Text('Chọn phương thức thanh toán', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _methodCard(
            invoice: invoice,
            method: 'CASH',
            icon: Icons.payments_outlined,
            title: 'Tiền mặt',
            subtitle: 'Thanh toán trực tiếp cho thợ',
            isSubmitting: isSubmitting,
          ),
          const SizedBox(height: 8),
          _methodCard(
            invoice: invoice,
            method: 'BANK_TRANSFER',
            icon: Icons.qr_code_2,
            title: 'Chuyển khoản QR',
            subtitle: 'Mã VietQR sẽ được hiển thị ở bước tiếp theo',
            isSubmitting: isSubmitting,
          ),
          if (invoice.paymentMethod != null) ...[
            const SizedBox(height: 10),
            Text(
              'Đã chọn: ${invoice.paymentMethodLabel}',
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _methodCard({
    required InvoiceModel invoice,
    required String method,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSubmitting,
  }) {
    final selected = invoice.paymentMethod == method;
    return InkWell(
      onTap: isSubmitting ? null : () => _selectMethod(method),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? AppTheme.primaryColor : AppTheme.textSecondaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
