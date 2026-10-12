import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/completion_provider.dart';

class UploadCompletionImagesScreen extends StatefulWidget {
  final String requestId;
  final String title;
  final int existingImageCount;

  const UploadCompletionImagesScreen({
    super.key,
    required this.requestId,
    required this.title,
    this.existingImageCount = 0,
  });

  @override
  State<UploadCompletionImagesScreen> createState() =>
      _UploadCompletionImagesScreenState();
}

class _UploadCompletionImagesScreenState
    extends State<UploadCompletionImagesScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];

  Future<void> _pickFromCamera() async {
    if (_selectedImages.length >= _remainingSlots) return;
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (image != null && mounted) {
      setState(() => _selectedImages.add(image));
    }
  }

  Future<void> _pickFromGallery() async {
    if (_remainingSlots <= 0) return;
    final images = await _picker.pickMultiImage(
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (mounted && images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.take(_remainingSlots));
      });
    }
  }

  int get _remainingSlots =>
      (5 - widget.existingImageCount - _selectedImages.length).clamp(0, 5).toInt();

  Future<void> _submit() async {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất một ảnh')),
      );
      return;
    }

    final token = context.read<AuthProvider>().token ?? '';
    final success = await context.read<CompletionProvider>().uploadImages(
          token: token,
          requestId: widget.requestId,
          images: _selectedImages,
        );

    if (!mounted) return;
    final provider = context.read<CompletionProvider>();
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã tải ảnh sau khi sửa thành công'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Upload ảnh thất bại')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CompletionProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Ảnh sau khi sửa')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Chụp ảnh thiết bị sau khi đã hoạt động bình thường. Mỗi đơn hàng lưu tối đa 5 ảnh.',
            style: TextStyle(color: AppTheme.textSecondaryColor, height: 1.4),
          ),
          if (widget.existingImageCount > 0) ...[
            const SizedBox(height: 6),
            Text(
              'Đơn hàng đã có ${widget.existingImageCount}/5 ảnh. Còn $_remainingSlots ảnh có thể thêm.',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: provider.isUploading || _remainingSlots <= 0
                      ? null
                      : _pickFromCamera,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Chụp ảnh'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: provider.isUploading || _remainingSlots <= 0
                      ? null
                      : _pickFromGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Thư viện'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_selectedImages.isEmpty)
            Container(
              height: 180,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_camera_back_outlined, size: 42, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Chưa có ảnh sau khi sửa', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _selectedImages.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemBuilder: (_, index) {
                final image = _selectedImages[index];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildPreviewImage(image),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: IconButton(
                        onPressed: provider.isUploading
                            ? null
                            : () => setState(() => _selectedImages.removeAt(index)),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    ),
                  ],
                );
              },
            ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: provider.isUploading ? null : _submit,
            icon: provider.isUploading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.cloud_upload_outlined),
            label: Text(provider.isUploading ? 'Đang tải ảnh...' : 'Gửi ảnh nghiệm thu'),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewImage(XFile image) {
    return FutureBuilder<Uint8List>(
      future: image.readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            color: Colors.grey.shade200,
            alignment: Alignment.center,
            child: const Icon(Icons.image_outlined, size: 40),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        return Image.memory(
          snapshot.data!,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            color: Colors.grey.shade200,
            alignment: Alignment.center,
            child: const Icon(Icons.image_outlined, size: 40),
          ),
        );
      },
    );
  }
}
