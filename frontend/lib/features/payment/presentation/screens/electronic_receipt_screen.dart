// Author: Lam Hoang Phuc (CE191132)
// Use Case: #UC-PAY-05
// Description: Màn hình hiển thị và lưu phiếu biên nhận thanh toán kiêm phiếu bảo hành dịch vụ điện tử
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/file_download_helper.dart';
import '../../../../core/utils/receipt_document_generator.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/electronic_receipt_model.dart';
import '../providers/payment_provider.dart';

class ElectronicReceiptScreen extends StatefulWidget {
  final String requestId;

  const ElectronicReceiptScreen({
    super.key,
    required this.requestId,
  });

  @override
  State<ElectronicReceiptScreen> createState() => _ElectronicReceiptScreenState();
}

class _ElectronicReceiptScreenState extends State<ElectronicReceiptScreen> {
  final _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );
  final _dateFormat = DateFormat('HH:mm - dd/MM/yyyy');
  final _dateOnlyFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReceipt());
  }

  Future<void> _loadReceipt() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    await context.read<PaymentProvider>().fetchElectronicReceipt(
          token: token,
          requestId: widget.requestId,
        );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép $label: $text'),
        backgroundColor: Colors.teal.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _saveReceipt(ElectronicReceiptModel receipt) {
    try {
      final htmlContent = ReceiptDocumentGenerator.generateReceiptHtml(receipt);
      final fileName = 'Bien_nhan_dien_tu_${receipt.receiptCode}.html';
      downloadFile(content: htmlContent, fileName: fileName);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Đã tải biên nhận điện tử ($fileName) về thiết bị thành công!',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi tải biên nhận: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _printReceipt() {
    printPage();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaymentProvider>();
    final receipt = provider.receipt;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Biên nhận & Bảo hành điện tử'),
        actions: [
          if (receipt != null) ...[
            IconButton(
              icon: const Icon(Icons.print_outlined),
              tooltip: 'In / Lưu PDF',
              onPressed: _printReceipt,
            ),
            IconButton(
              icon: const Icon(Icons.download_rounded),
              tooltip: 'Tải biên nhận về máy',
              onPressed: () => _saveReceipt(receipt),
            ),
          ],
        ],
      ),
      body: provider.isLoadingReceipt
          ? const Center(child: CircularProgressIndicator())
          : provider.receiptError != null && receipt == null
              ? _buildErrorView(provider.receiptError!)
              : receipt == null
                  ? _buildErrorView('Không tìm thấy thông tin biên nhận')
                  : RefreshIndicator(
                      onRefresh: _loadReceipt,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        child: Column(
                          children: [
                            _buildReceiptCard(receipt),
                            const SizedBox(height: 20),
                            _buildActionButtons(receipt),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 56,
              color: Colors.grey,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              onPressed: _loadReceipt,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptCard(ElectronicReceiptModel receipt) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header biên nhận
          _buildReceiptHeader(receipt),

          // Đường xé vé răng cưa trang trí
          _buildDottedDivider(),

          // Thông tin bảo hành điện tử
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWarrantyBadge(receipt),
                const SizedBox(height: 18),

                // Thông tin dịch vụ
                _buildSectionTitle('Dịch vụ đã hoàn tất'),
                const SizedBox(height: 6),
                Text(
                  receipt.serviceTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Danh mục: ${receipt.serviceCategoryName}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Thông tin Khách hàng & Thợ
                _buildParticipantsInfo(receipt),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Bảng kê tài chính
                _buildFinancialBreakdown(receipt),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Cam kết & Điều khoản bảo hành
                _buildWarrantyTerms(receipt),

                // Ảnh nghiệm thu & linh kiện đính kèm
                if (receipt.completionImages.isNotEmpty ||
                    receipt.partsInvoiceImages.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  _buildEvidencePreview(receipt),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptHeader(ElectronicReceiptModel receipt) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified_user_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HOMEFIX E-RECEIPT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      Text(
                        'Biên nhận & Bảo hành chính hãng',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      receipt.financial.isPaid
                          ? Icons.check_circle
                          : Icons.access_time_filled,
                      size: 14,
                      color: receipt.financial.isPaid
                          ? Colors.green.shade700
                          : Colors.orange.shade800,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      receipt.financial.isPaid
                          ? 'ĐÃ THANH TOÁN'
                          : 'CHỜ THU TIỀN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: receipt.financial.isPaid
                          ? Colors.green.shade700
                          : Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SỐ BIÊN NHẬN',
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                    Text(
                      receipt.receiptCode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'NGÀY PHÁT HÀNH',
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                    Text(
                      _dateFormat.format(receipt.issuedAt),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDottedDivider() {
    return Row(
      children: List.generate(
        35,
        (index) => Expanded(
          child: Container(
            color: index % 2 == 0 ? Colors.transparent : Colors.grey.shade300,
            height: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildWarrantyBadge(ElectronicReceiptModel receipt) {
    final warranty = receipt.warranty;
    final isStillActive = warranty.isActive;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isStillActive ? Colors.teal.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isStillActive ? Colors.teal.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                color: isStillActive ? Colors.teal.shade800 : Colors.grey.shade700,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cam kết bảo hành dịch vụ (${warranty.durationDays} ngày)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isStillActive
                        ? Colors.teal.shade900
                        : Colors.grey.shade800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isStillActive ? Colors.teal.shade700 : Colors.grey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  warranty.statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mã tra cứu bảo hành: ${receipt.warrantyCode}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              InkWell(
                onTap: () => _copyToClipboard(receipt.warrantyCode, 'mã bảo hành'),
                child: const Row(
                  children: [
                    Icon(Icons.copy_rounded, size: 14, color: AppTheme.primaryColor),
                    SizedBox(width: 3),
                    Text(
                      'Sao chép',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Thời hạn: ${_dateOnlyFormat.format(warranty.startDate)} đến ${_dateOnlyFormat.format(warranty.endDate)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsInfo(ElectronicReceiptModel receipt) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Khách hàng
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Khách hàng'),
              const SizedBox(height: 4),
              Text(
                receipt.customer.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              if (receipt.customer.phoneNumber.isNotEmpty)
                Text(
                  receipt.customer.phoneNumber,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              if (receipt.customer.address.isNotEmpty)
                Text(
                  receipt.customer.address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Thợ kỹ thuật
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Thợ phụ trách'),
              const SizedBox(height: 4),
              Text(
                receipt.technician.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              if (receipt.technician.phoneNumber.isNotEmpty)
                Text(
                  receipt.technician.phoneNumber,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              const Text(
                'Kỹ thuật viên đối tác HomeFix',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialBreakdown(ElectronicReceiptModel receipt) {
    final fin = receipt.financial;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Quyết toán tài chính'),
        const SizedBox(height: 8),
        _buildRowValue('Tiền công thợ:', _currencyFormat.format(fin.labourCost)),
        const SizedBox(height: 4),
        _buildRowValue('Chi phí linh kiện / vật tư:', _currencyFormat.format(fin.partsCost)),
        const SizedBox(height: 8),
        const Divider(height: 1),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TỔNG TIỀN ĐÃ THANH TOÁN:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            Text(
              _currencyFormat.format(fin.totalAmount),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Hình thức:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              fin.paymentMethod == 'CASH'
                  ? 'Tiền mặt trực tiếp tại chỗ (CASH)'
                  : fin.paymentMethod,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRowValue(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildWarrantyTerms(ElectronicReceiptModel receipt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Điều khoản & Chính sách bảo hành điện tử'),
        const SizedBox(height: 8),
        ...receipt.warranty.terms.map(
          (term) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 15,
                  color: Colors.teal,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    term,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF4A5568),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEvidencePreview(ElectronicReceiptModel receipt) {
    final images = [
      ...receipt.completionImages,
      ...receipt.partsInvoiceImages,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Ảnh nghiệm thu & Hóa đơn chứng từ đính kèm'),
        const SizedBox(height: 10),
        SizedBox(
          height: 70,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            separatorBuilder: (_, index) => const SizedBox(width: 8),
            itemBuilder: (ctx, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  images[index],
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, error, stackTrace) => Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image, size: 20),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ElectronicReceiptModel receipt) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.download_rounded),
            label: const Text(
              'Lưu biên nhận điện tử về máy',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            onPressed: () => _saveReceipt(receipt),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Sao chép mã tra cứu bảo hành'),
            onPressed: () =>
                _copyToClipboard(receipt.warrantyCode, 'mã bảo hành'),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.bold,
        color: AppTheme.textSecondaryColor,
        letterSpacing: 0.3,
      ),
    );
  }
}
