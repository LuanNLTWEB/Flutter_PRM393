import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/technician_provider.dart';

class TechnicianSkillsScreen extends StatefulWidget {
  const TechnicianSkillsScreen({super.key});

  @override
  State<TechnicianSkillsScreen> createState() => _TechnicianSkillsScreenState();
}

class _TechnicianSkillsScreenState extends State<TechnicianSkillsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late final TextEditingController _expController;
  late final TextEditingController _bioController;
  final TextEditingController _customSkillController = TextEditingController();

  final List<String> _suggestedSkills = [
    'Điện dân dụng',
    'Điện lạnh - Máy lạnh',
    'Đường ống nước',
    'Khóa & Bản lề',
    'Sơn & Thạch cao',
    'Mộc & Nội thất gỗ',
    'Thiết bị gia dụng',
    'Sửa máy tính / Laptop',
    'Camera & An ninh',
    'Hàn & Cơ khí',
  ];

  late Set<String> _selectedSkills;
  late List<String> _existingCertificates;
  final List<XFile> _newCertificates = [];

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final techProfile = auth.currentUser?.technicianProfile;

    _selectedSkills = Set<String>.from(techProfile?.skills ?? []);
    if (_selectedSkills.isEmpty) {
      _selectedSkills.add('Điện dân dụng');
    }

    _existingCertificates = List<String>.from(
      (techProfile?.certificates ?? [])
          .where((c) => c.trim().isNotEmpty && c.startsWith('http')),
    );
    _expController = TextEditingController(
      text: (techProfile?.experienceYears ?? 0).toString(),
    );
    _bioController = TextEditingController(text: techProfile?.bio ?? '');
  }

  @override
  void dispose() {
    _expController.dispose();
    _bioController.dispose();
    _customSkillController.dispose();
    super.dispose();
  }

  void _addCustomSkill() {
    final skill = _customSkillController.text.trim();
    if (skill.isNotEmpty) {
      setState(() {
        _selectedSkills.add(skill);
        _customSkillController.clear();
      });
    }
  }

  void _toggleSuggestedSkill(String skill) {
    setState(() {
      if (_selectedSkills.contains(skill)) {
        if (_selectedSkills.length > 1) {
          _selectedSkills.remove(skill);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vui lòng giữ ít nhất 1 kỹ năng chuyên môn!'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        _selectedSkills.add(skill);
      }
    });
  }

  Future<void> _pickNewCertificate(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final picked = await _picker.pickMultiImage(imageQuality: 85);
        if (picked.isNotEmpty) {
          setState(() {
            _newCertificates.addAll(picked);
          });
        }
      } else {
        final picked = await _picker.pickImage(source: source, imageQuality: 85);
        if (picked != null) {
          setState(() {
            _newCertificates.add(picked);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể chọn ảnh: $e')),
        );
      }
    }
  }

  void _showAddCertificateSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Thêm chứng chỉ / Bằng cấp nghề',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_camera_rounded, color: Colors.blue),
                ),
                title: const Text('Chụp ảnh mới', style: TextStyle(fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickNewCertificate(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Colors.teal),
                ),
                title: const Text('Chọn ảnh từ thư viện', style: TextStyle(fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickNewCertificate(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewFullImage(String url, {bool isNetwork = true, XFile? localFile}) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: isNetwork
                  ? Image.network(url, fit: BoxFit.contain)
                  : (kIsWeb
                      ? Image.network(localFile!.path, fit: BoxFit.contain)
                      : Image.file(File(localFile!.path), fit: BoxFit.contain)),
            ),
            IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất 1 chuyên môn / tay nghề!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    final techProvider = context.read<TechnicianProvider>();
    final token = auth.token ?? '';

    final expYears = int.tryParse(_expController.text.trim()) ?? 0;
    final bio = _bioController.text.trim();

    final updatedUser = await techProvider.updateTechnicianSkills(
      token: token,
      skills: _selectedSkills.toList(),
      experienceYears: expYears,
      bio: bio,
      existingCertificates: _existingCertificates,
      newCertificates: _newCertificates,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (updatedUser != null) {
      await auth.refreshProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật hồ sơ tay nghề và chứng chỉ thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(techProvider.errorMessage ?? 'Cập nhật thất bại'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Hồ sơ tay nghề & Chứng chỉ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitUpdate,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Lưu thay đổi hồ sơ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Chuyên môn & Kỹ năng
              _buildSkillsSection(),
              const SizedBox(height: 18),

              // Card Kinh nghiệm & Bio
              _buildExperienceAndBioSection(),
              const SizedBox(height: 18),

              // Card Chứng chỉ nghề nghiệp
              _buildCertificatesSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkillsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.handyman_rounded, color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Chuyên môn & Kỹ năng sửa chữa *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Chọn các lĩnh vực bạn có thể tiếp nhận và xử lý đơn:',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: 14),

          // Danh sách kỹ năng gợi ý
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestedSkills.map((skill) {
              final isSelected = _selectedSkills.contains(skill);
              return FilterChip(
                label: Text(skill),
                selected: isSelected,
                selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                checkmarkColor: AppTheme.primaryColor,
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
                ),
                side: BorderSide(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                ),
                onSelected: (_) => _toggleSuggestedSkill(skill),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Thêm kỹ năng tùy chỉnh khác
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customSkillController,
                  decoration: InputDecoration(
                    hintText: 'Nhập chuyên môn khác (vd: Sửa khóa cửa cuốn...)',
                    hintStyle: const TextStyle(fontSize: 13),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onSubmitted: (_) => _addCustomSkill(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 42),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Thêm'),
                onPressed: _addCustomSkill,
              ),
            ],
          ),

          if (_selectedSkills.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text(
                  'Kỹ năng đã chọn: ',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryColor),
                ),
                Text(
                  '(${_selectedSkills.length})',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _selectedSkills.map((s) {
                return Chip(
                  label: Text(s, style: const TextStyle(fontSize: 12, color: Colors.white)),
                  backgroundColor: AppTheme.primaryColor,
                  deleteIconColor: Colors.white,
                  onDeleted: _selectedSkills.length > 1
                      ? () {
                          setState(() {
                            _selectedSkills.remove(s);
                          });
                        }
                      : null,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExperienceAndBioSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.work_history_rounded, color: Colors.orange, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Kinh nghiệm & Giới thiệu',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Số năm kinh nghiệm
          TextFormField(
            controller: _expController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Số năm kinh nghiệm làm việc *',
              prefixIcon: Icon(Icons.timer_outlined),
              suffixText: 'năm',
              border: OutlineInputBorder(),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Vui lòng nhập số năm kinh nghiệm';
              }
              final exp = int.tryParse(val.trim());
              if (exp == null || exp < 0) {
                return 'Số năm kinh nghiệm không hợp lệ';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Tiểu sử / Bio
          TextFormField(
            controller: _bioController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Mô tả tay nghề & Giới thiệu bản thân',
              hintText: 'Mô tả chi tiết kỹ năng, các loại thiết bị sở trường, phương châm làm việc...',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificatesSection() {
    final totalCerts = _existingCertificates.length + _newCertificates.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.workspace_premium_rounded, color: Colors.teal, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Chứng chỉ nghề ($totalCerts)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                label: const Text('Thêm ảnh'),
                onPressed: _showAddCertificateSheet,
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Tải lên các bằng nghề, chứng nhận an toàn lao động, giải thưởng để tăng độ tin cậy với khách hàng:',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: 14),

          if (totalCerts == 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
              ),
              child: Column(
                children: [
                  Icon(Icons.badge_outlined, size: 40, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  const Text(
                    'Chưa có chứng chỉ nào được tải lên',
                    style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                    ),
                    icon: const Icon(Icons.upload_file, size: 16),
                    label: const Text('Tải ảnh chứng chỉ'),
                    onPressed: _showAddCertificateSheet,
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                // Danh sách chứng chỉ cũ
                ..._existingCertificates.asMap().entries.map((entry) {
                  final index = entry.key;
                  final url = entry.value;
                  return _buildCertificateThumbnail(
                    imageUrl: url,
                    isNetwork: true,
                    onDelete: () {
                      setState(() {
                        _existingCertificates.removeAt(index);
                      });
                    },
                    onTap: () => _viewFullImage(url, isNetwork: true),
                  );
                }),

                // Danh sách chứng chỉ mới
                ..._newCertificates.asMap().entries.map((entry) {
                  final index = entry.key;
                  final xfile = entry.value;
                  return _buildCertificateThumbnail(
                    isNetwork: false,
                    localFile: xfile,
                    isNew: true,
                    onDelete: () {
                      setState(() {
                        _newCertificates.removeAt(index);
                      });
                    },
                    onTap: () => _viewFullImage('', isNetwork: false, localFile: xfile),
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCertificateThumbnail({
    String? imageUrl,
    bool isNetwork = true,
    XFile? localFile,
    bool isNew = false,
    required VoidCallback onDelete,
    required VoidCallback onTap,
  }) {
    return Stack(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isNew ? Colors.teal : Colors.grey.shade300, width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: isNetwork
                ? ((imageUrl != null && imageUrl.isNotEmpty)
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (ctx, child, progress) {
                          if (progress == null) return child;
                          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                        },
                        errorBuilder: (_, _, _) => const Icon(Icons.broken_image, color: Colors.grey),
                      )
                    : const Icon(Icons.broken_image, color: Colors.grey))
                : (kIsWeb
                    ? Image.network(localFile!.path, fit: BoxFit.cover)
                    : Image.file(File(localFile!.path), fit: BoxFit.cover)),
          ),
        ),
        // Badge "Mới" nếu vừa upload
        if (isNew)
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.teal,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Mới',
                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        // Nút xóa
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 12),
            ),
          ),
        ),
      ],
    );
  }
}
