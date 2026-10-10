import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/service_category_model.dart';
import '../providers/repair_request_provider.dart';
import '../widgets/schedule_time_slot_picker.dart';
import 'request_success_screen.dart';

/// Màn hình tạo yêu cầu sửa chữa (Mô tả triệu chứng & Mức độ khẩn cấp)
class CreateRepairRequestScreen extends StatefulWidget {
  final ServiceCategoryModel preselectedCategory;

  const CreateRepairRequestScreen({
    super.key,
    required this.preselectedCategory,
  });

  @override
  State<CreateRepairRequestScreen> createState() => _CreateRepairRequestScreenState();
}

class _CreateRepairRequestScreenState extends State<CreateRepairRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _urgency = 'medium'; // low, medium, high, emergency
  DateTime? _preferredTime; // Khung giờ hẹn thợ đến nhà

  static const List<Map<String, dynamic>> _urgencyOptions = [
    {
      'value': 'low',
      'label': 'Thấp',
      'icon': Icons.schedule_outlined,
      'color': Color(0xFF10B981),
      'desc': 'Không gấp, xử lý khi thuận tiện',
    },
    {
      'value': 'medium',
      'label': 'Bình thường',
      'icon': Icons.info_outline,
      'color': Color(0xFF2563EB),
      'desc': 'Cần sửa trong 1-2 ngày tới',
    },
    {
      'value': 'high',
      'label': 'Khẩn cấp',
      'icon': Icons.priority_high_rounded,
      'color': Color(0xFFF59E0B),
      'desc': 'Cần thợ đến kiểm tra ngay trong ngày',
    },
    {
      'value': 'emergency',
      'label': 'Cấp cứu',
      'icon': Icons.warning_amber_rounded,
      'color': Color(0xFFDC2626),
      'desc': 'Nguy hiểm, chập cháy, cần xử lý tức thì',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Để trống ô tiêu đề để người dùng tự nhập sự cố cụ thể của mình
    _titleController.text = '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Kiểm tra chuỗi spam, lặp ký tự liên tiếp hoặc quá ít ký tự phân biệt
  bool _isSpamContent(String text) {
    final clean = text.replaceAll(RegExp(r'\s+'), '');
    if (clean.isEmpty) return true;

    // Ký tự lặp lại liên tiếp từ 4 lần trở lên (vd: aaaa, 1111)
    if (RegExp(r'(.)\1{3,}').hasMatch(clean)) return true;

    // Chuỗi dài từ 6 ký tự trở lên nhưng chỉ có dưới 3 ký tự khác nhau
    final uniqueLetters = clean.toLowerCase().split('').toSet();
    if (clean.length >= 6 && uniqueLetters.length < 3) return true;

    return false;
  }

  /// Gửi trực tiếp yêu cầu sửa chữa lên hệ thống
  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_preferredTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ngày và giờ hẹn thợ đến nhà'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final token = auth.token ?? '';
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để tạo yêu cầu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final provider = context.read<RepairRequestProvider>();
    final result = await provider.createRepairRequest(
      token: token,
      serviceCategoryId: widget.preselectedCategory.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      urgency: _urgency,
      preferredTime: _preferredTime,
    );

    if (!mounted) return;

    if (result != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RequestSuccessScreen(request: result),
        ),
      );
    } else {
      final error = provider.submitError ?? 'Không thể gửi yêu cầu. Vui lòng thử lại.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultIssueHint = widget.preselectedCategory.commonIssues.isNotEmpty
        ? widget.preselectedCategory.commonIssues.first
        : 'Mô tả ngắn sự cố cần sửa chữa';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tạo yêu cầu sửa chữa',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Thông tin dịch vụ đã chọn
              _buildSelectedServiceCard(),
              const SizedBox(height: 24),

              // Tiêu đề yêu cầu
              _buildSectionLabel('Tiêu đề yêu cầu *', Icons.title_outlined),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('create_request_title_field'),
                controller: _titleController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: _inputDecoration(
                  hint: 'VD: $defaultIssueHint...',
                ),
                validator: (val) {
                  final text = val?.trim() ?? '';
                  if (text.isEmpty) {
                    return 'Vui lòng nhập tiêu đề sự cố cần sửa chữa';
                  }
                  if (text.length < 6) {
                    return 'Tiêu đề quá ngắn (tối thiểu 6 ký tự)';
                  }
                  if (text.length > 150) {
                    return 'Tiêu đề không được vượt quá 150 ký tự';
                  }
                  if (_isSpamContent(text)) {
                    return 'Tiêu đề không hợp lệ, vui lòng không nhập ký tự lặp hoặc từ vô nghĩa';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Mô tả triệu chứng hỏng hóc
              _buildSectionLabel('Mô tả triệu chứng hỏng hóc *', Icons.description_outlined),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('create_request_problem_field'),
                controller: _descriptionController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                maxLines: 5,
                maxLength: 1000,
                decoration: _inputDecoration(
                  hint: 'Mô tả chi tiết sự cố bạn đang gặp phải (triệu chứng, hiện tượng bất thường, thời điểm xuất hiện sự cố)...',
                ),
                validator: (val) {
                  final text = val?.trim() ?? '';
                  if (text.isEmpty) {
                    return 'Vui lòng mô tả chi tiết sự cố hỏng hóc';
                  }
                  if (text.length < 15) {
                    return 'Mô tả sự cố quá ngắn. Vui lòng nhập tối thiểu 15 ký tự để thợ hiểu rõ vấn đề';
                  }
                  if (text.length > 1000) {
                    return 'Mô tả không được vượt quá 1000 ký tự';
                  }
                  final wordCount = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
                  if (wordCount < 3) {
                    return 'Vui lòng mô tả rõ ràng hơn (tối thiểu 3 từ) để thợ có thể hình dung sự cố';
                  }
                  if (_isSpamContent(text)) {
                    return 'Mô tả chứa ký tự lặp hoặc chuỗi vô nghĩa. Vui lòng mô tả sự cố thực tế';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Chọn mức độ khẩn cấp
              _buildSectionLabel('Mức độ khẩn cấp *', Icons.speed_outlined),
              const SizedBox(height: 12),
              Column(
                children: _urgencyOptions.map((opt) {
                  final isSelected = _urgency == opt['value'];
                  final color = opt['color'] as Color;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () => setState(() => _urgency = opt['value'] as String),
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected ? color.withValues(alpha: 0.08) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? color : Colors.grey.shade300,
                            width: isSelected ? 1.8 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(opt['icon'] as IconData, color: color, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    opt['label'] as String,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      color: isSelected ? color : const Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    opt['desc'] as String,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                              color: isSelected ? color : Colors.grey.shade400,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Chọn lịch hẹn: ngày & khung giờ thợ đến nhà
              _buildSectionLabel('Lịch hẹn thợ đến nhà *', Icons.event_available_outlined),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'Chọn ngày và giờ thuận tiện để thợ đến kiểm tra, sửa chữa',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
              ScheduleTimeSlotPicker(
                onScheduleChanged: (schedule) => _preferredTime = schedule,
              ),
              const SizedBox(height: 28),

              // Nút Gửi yêu cầu sửa chữa
              Consumer<RepairRequestProvider>(
                builder: (context, provider, child) {
                  return SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      key: const Key('create_request_submit_button'),
                      onPressed: provider.isSubmitting ? null : _submitRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: provider.isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.send_rounded, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Gửi phiếu yêu cầu sửa chữa',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedServiceCard() {
    final cat = widget.preselectedCategory;
    final color = AppTheme.primaryColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.handyman_rounded, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dịch vụ đã chọn',
                  style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
                Text(
                  cat.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                if (cat.basePrice > 0)
                  Text(
                    'Giá tham khảo: ${cat.basePriceFormatted}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
}
