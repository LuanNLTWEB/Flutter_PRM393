import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/invoice_model.dart';
import '../providers/invoice_provider.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInvoices());
  }

  Future<void> _loadInvoices() async {
    final auth = context.read<AuthProvider>();
    final userId = auth.currentUser?.id;
    final token = auth.token;
    if (userId == null || token == null || token.isEmpty) return;
    await context.read<InvoiceProvider>().fetchInvoices(
      token: token,
      userId: userId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvoiceProvider>();
    final cachedAt = provider.cachedAt;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        title: const Text('Hóa đơn đã lưu'),
        actions: [
          IconButton(
            tooltip: 'Đồng bộ lại',
            onPressed: provider.isLoading ? null : _loadInvoices,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: provider.isLoading && provider.invoices.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadInvoices,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (provider.isShowingOfflineData)
                    _OfflineNotice(cachedAt: cachedAt),
                  if (provider.errorMessage != null)
                    _ErrorNotice(message: provider.errorMessage!),
                  if (provider.invoices.isEmpty &&
                      provider.errorMessage == null)
                    const _EmptyInvoices()
                  else ...[
                    Text(
                      '${provider.invoices.length} hóa đơn',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...provider.invoices.map(
                      (invoice) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _InvoiceCard(
                          invoice: invoice,
                          onTap: () => _showInvoiceDetail(
                            context,
                            invoice,
                            isOffline: provider.isShowingOfflineData,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  void _showInvoiceDetail(
    BuildContext context,
    InvoiceModel invoice, {
    required bool isOffline,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _InvoiceDetailSheet(invoice: invoice, isOffline: isOffline),
    );
  }
}

class _OfflineNotice extends StatelessWidget {
  final DateTime? cachedAt;

  const _OfflineNotice({this.cachedAt});

  @override
  Widget build(BuildContext context) {
    final updated = cachedAt == null
        ? ''
        : ' • Đồng bộ ${DateFormat('HH:mm, dd/MM/yyyy').format(cachedAt!)}';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, color: Colors.amber.shade900),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Bạn đang xem hóa đơn đã lưu trên thiết bị$updated',
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.amber.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  final String message;

  const _ErrorNotice({required this.message});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.red.shade200),
    ),
    child: Column(
      children: [
        Icon(Icons.receipt_long_outlined, size: 52, color: Colors.red.shade300),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.red.shade900),
        ),
      ],
    ),
  );
}

class _EmptyInvoices extends StatelessWidget {
  const _EmptyInvoices();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(top: 72),
    child: Column(
      children: [
        Icon(
          Icons.receipt_long_outlined,
          size: 64,
          color: AppTheme.textSecondaryColor,
        ),
        SizedBox(height: 14),
        Text(
          'Chưa có hóa đơn hoàn tất',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 6),
        Text(
          'Hóa đơn sẽ được lưu tự động sau khi dịch vụ hoàn tất.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondaryColor),
        ),
      ],
    ),
  );
}

class _InvoiceCard extends StatelessWidget {
  final InvoiceModel invoice;
  final VoidCallback onTap;

  const _InvoiceCard({required this.invoice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final date = invoice.completedAt ?? invoice.issuedAt;
    final currency = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.serviceCategoryName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      invoice.invoiceNumber,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    if (date != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        DateFormat('dd/MM/yyyy').format(date),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currency.format(invoice.total),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.textSecondaryColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvoiceDetailSheet extends StatelessWidget {
  final InvoiceModel invoice;
  final bool isOffline;

  const _InvoiceDetailSheet({required this.invoice, required this.isOffline});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    final date = invoice.completedAt ?? invoice.issuedAt;

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .88,
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    color: Colors.green,
                    size: 25,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Hóa đơn dịch vụ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isOffline)
                    const Chip(
                      avatar: Icon(Icons.cloud_off_outlined, size: 16),
                      label: Text('Đã lưu', style: TextStyle(fontSize: 11)),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                invoice.invoiceNumber,
                style: const TextStyle(color: AppTheme.textSecondaryColor),
              ),
              const SizedBox(height: 18),
              _DetailRow(label: 'Dịch vụ', value: invoice.serviceCategoryName),
              _DetailRow(label: 'Yêu cầu', value: invoice.requestTitle),
              _DetailRow(label: 'Thợ phụ trách', value: invoice.technicianName),
              if (invoice.technicianPhone.isNotEmpty)
                _DetailRow(
                  label: 'Số điện thoại thợ',
                  value: invoice.technicianPhone,
                ),
              _DetailRow(label: 'Địa chỉ', value: invoice.address),
              if (date != null)
                _DetailRow(
                  label: 'Hoàn tất lúc',
                  value: DateFormat('HH:mm, dd/MM/yyyy').format(date),
                ),
              const SizedBox(height: 18),
              const Text(
                'Chi tiết thanh toán',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _CostRow(
                label: 'Tiền công',
                amount: currency.format(invoice.labourCost),
              ),
              _CostRow(
                label: 'Linh kiện',
                amount: currency.format(invoice.partsCost),
              ),
              if (invoice.additionalCostTotal > 0)
                _CostRow(
                  label: 'Chi phí phát sinh (đã duyệt)',
                  amount: currency.format(invoice.additionalCostTotal),
                ),
              const Divider(height: 24),
              _CostRow(
                label: 'Tổng thanh toán',
                amount: currency.format(invoice.total),
                emphasized: true,
              ),
              if (invoice.quotationNote.isNotEmpty) ...[
                const SizedBox(height: 18),
                const Text(
                  'Ghi chú báo giá',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  invoice.quotationNote,
                  style: const TextStyle(color: AppTheme.textSecondaryColor),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
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
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _CostRow extends StatelessWidget {
  final String label;
  final String amount;
  final bool emphasized;

  const _CostRow({
    required this.label,
    required this.amount,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: emphasized
                ? AppTheme.textPrimaryColor
                : AppTheme.textSecondaryColor,
            fontWeight: emphasized ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            color: emphasized
                ? AppTheme.primaryColor
                : AppTheme.textPrimaryColor,
            fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
            fontSize: emphasized ? 17 : 14,
          ),
        ),
      ],
    ),
  );
}
