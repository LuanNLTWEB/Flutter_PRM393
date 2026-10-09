import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/quotation_model.dart';
import '../../domain/quotation_comparator.dart';
import '../providers/quotation_provider.dart';
import 'quotation_format.dart';

/// Bottom sheet gửi / chỉnh sửa báo giá (UC-QUO-04, UC-QUO-05)
class SendQuotationSheet extends StatefulWidget {
  final String requestId;
  final QuotationModel? existingQuote;

  const SendQuotationSheet({
    super.key,
    required this.requestId,
    this.existingQuote,
  });

  /// Trả về true nếu gửi/ cập nhật báo giá thành công
  static Future<bool?> show(
    BuildContext context, {
    required String requestId,
    QuotationModel? existingQuote,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SendQuotationSheet(
        requestId: requestId,
        existingQuote: existingQuote,
      ),
    );
  }

  @override
  State<SendQuotationSheet> createState() => _SendQuotationSheetState();
}

class _SendQuotationSheetState extends State<SendQuotationSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labourController;
  late final TextEditingController _partsController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    final quote = widget.existingQuote;
    _labourController = TextEditingController(
      text: quote != null && quote.labourCost > 0
          ? quote.labourCost.toStringAsFixed(0)
          : '',
    );
    _partsController = TextEditingController(
      text: quote != null && quote.partsCost > 0
          ? quote.partsCost.toStringAsFixed(0)
          : '',
    );
    _noteController = TextEditingController(text: quote?.note ?? '');
  }

  @override
  void dispose() {
    _labourController.dispose();
    _partsController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _labour => double.tryParse(_labourController.text.trim()) ?? 0;
  double get _parts => double.tryParse(_partsController.text.trim()) ?? 0;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final provider = context.read<QuotationProvider>();
    final token = auth.token ?? '';
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập lại')),
      );
      return;
    }

    final success = widget.existingQuote == null
        ? await provider.sendQuotation(
            token: token,
            requestId: widget.requestId,
            labourCost: _labour,
            partsCost: _parts,
            note: _noteController.text.trim(),
          )
        : await provider.updateQuotation(
            token: token,
            id: widget.existingQuote!.id,
            labourCost: _labour,
            partsCost: _parts,
            note: _noteController.text.trim(),
          );

    if (!mounted) return;
    if (success) {
      Navigator.pop(context, true);
    } else {
      final error = provider.errorMessage ?? 'Có lỗi xảy ra';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  String? _validateAmount(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return 'Nhập $label';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null || !QuotationComparator.isValidAmount(parsed)) {
      return '$label phải là số không âm';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingQuote != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 16 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isEditing ? 'Chỉnh sửa báo giá' : 'Gửi báo giá',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _labourController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Tiền công ước tính (đ)',
                border: OutlineInputBorder(),
              ),
              validator: (v) => _validateAmount(v, 'tiền công'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _partsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Giá linh kiện (đ)',
                hintText: 'Không có linh kiện thì nhập 0',
                border: OutlineInputBorder(),
              ),
              validator: (v) => _validateAmount(v, 'giá linh kiện'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Ghi chú gửi khách',
                hintText: 'Thời gian đến, tiền hẹn, lưu ý...',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tổng cộng',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    formatVnd(QuotationComparator.computeTotal(_labour, _parts)),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Consumer<QuotationProvider>(
              builder: (context, provider, _) {
                return ElevatedButton(
                  onPressed: provider.isSubmitting ? null : _submit,
                  child: provider.isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(isEditing ? 'Cập nhật báo giá' : 'Gửi báo giá'),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
