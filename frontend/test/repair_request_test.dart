import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/repair_request/data/models/repair_request_model.dart';
import 'package:frontend/features/repair_request/presentation/providers/repair_request_provider.dart';
import 'package:frontend/features/repair_request/presentation/widgets/image_picker_box_widget.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  group('Repair Request Tests', () {
    test('RepairRequestModel parses images correctly from JSON', () {
      final json = {
        '_id': 'req_123',
        'customerId': 'user_123',
        'serviceCategoryId': 'cat_123',
        'title': 'Sửa máy giặt kêu to rung lắc',
        'description': 'Máy giặt cửa trước kêu rất to khi vắt',
        'images': [
          'https://res.cloudinary.com/homefix/image/upload/v1/repair1.jpg',
          'https://res.cloudinary.com/homefix/image/upload/v1/repair2.jpg',
        ],
        'urgency': 'high',
        'status': 'OPEN',
        'contactPhone': '0901234567',
        'createdAt': '2026-10-18T10:00:00.000Z',
        'updatedAt': '2026-10-18T10:00:00.000Z',
      };

      final model = RepairRequestModel.fromJson(json);

      expect(model.id, 'req_123');
      expect(model.images.length, 2);
      expect(model.images.first, contains('repair1.jpg'));
      expect(model.urgency, 'high');
      expect(model.status, 'OPEN');
    });

    test('RepairRequestProvider initializes with empty states', () {
      final provider = RepairRequestProvider();

      expect(provider.categories, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.isSubmitting, isFalse);
      expect(provider.submitError, isNull);
      expect(provider.lastCreatedRequest, isNull);
    });

    testWidgets('ImagePickerBoxWidget renders title, counter badge and add button', (tester) async {
      final List<XFile> images = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImagePickerBoxWidget(
              selectedImages: images,
              onImagesChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Ảnh hiện trường sự cố'), findsOneWidget);
      expect(find.text('0/5 ảnh'), findsOneWidget);
      expect(find.text('Thêm ảnh'), findsOneWidget);
      expect(find.byIcon(Icons.add_photo_alternate_outlined), findsOneWidget);
    });
  });
}
