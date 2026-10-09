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
    _titleController.text = 'Sửa chữa ${widget.preselectedCategory.name.toLowerCase()}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

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
                decoration: _inputDecoration(
                  hint: 'VD: Sửa chập điện aptomat phòng khách...',
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'Vui lòng nhập tiêu đề yêu cầu'
                    : null,
              ),
              const SizedBox(height: 20),

              // Mô tả triệu chứng hỏng hóc
              _buildSectionLabel('Mô tả triệu chứng hỏng hóc *', Icons.description_outlined),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('create_request_problem_field'),
                controller: _descriptionController,
                maxLines: 5,
                maxLength: 1000,
                decoration: _inputDecoration(
                  hint: 'Mô tả chi tiết sự cố bạn đang gặp phải (triệu chứng, hiện tượng bất thường, thời điểm xuất hiện sự cố)...',
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 10) {
                    return 'Mô tả phải có ít nhất 10 ký tự';
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

              // Nút Gửi yêu cầu
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
