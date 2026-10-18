import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';

/// Widget chọn và xem trước ảnh hiện trường từ thư viện ảnh
class ImagePickerBoxWidget extends StatelessWidget {
  final List<XFile> selectedImages;
  final ValueChanged<List<XFile>> onImagesChanged;
  final int maxImages;

  const ImagePickerBoxWidget({
    super.key,
    required this.selectedImages,
    required this.onImagesChanged,
    this.maxImages = 5,
  });

  /// Chọn ảnh từ thư viện
  Future<void> _pickImages(BuildContext context) async {
    final remainingSlots = maxImages - selectedImages.length;
    if (remainingSlots <= 0) return;

    try {
      final picker = ImagePicker();
      final pickedList = await picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (pickedList.isNotEmpty) {
        final toAdd = pickedList.take(remainingSlots).toList();
        final updated = List<XFile>.from(selectedImages)..addAll(toAdd);
        onImagesChanged(updated);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể chọn ảnh từ thư viện: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Xóa ảnh tại chỉ số cụ thể
  void _removeImage(int index) {
    final updated = List<XFile>.from(selectedImages)..removeAt(index);
    onImagesChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.photo_library_outlined, size: 18, color: AppTheme.primaryColor),
                const SizedBox(width: 6),
                const Text(
                  'Ảnh hiện trường sự cố',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                '${selectedImages.length}/$maxImages ảnh',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selectedImages.length >= maxImages
                      ? Colors.orange.shade800
                      : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Chọn ảnh từ thư viện để thợ có thể nắm rõ tình trạng hư hỏng của thiết bị',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...List.generate(selectedImages.length, (index) {
                final file = selectedImages[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: kIsWeb
                              ? Image.network(file.path, fit: BoxFit.cover)
                              : Image.file(File(file.path), fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: InkWell(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (selectedImages.length < maxImages)
                InkWell(
                  onTap: () => _pickImages(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.5),
                        style: BorderStyle.solid,
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 26,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Thêm ảnh',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
