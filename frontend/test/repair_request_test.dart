import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/repair_request/data/models/repair_request_model.dart';
import 'package:frontend/features/repair_request/data/models/service_category_model.dart';
import 'package:frontend/features/repair_request/presentation/providers/repair_request_provider.dart';

import 'package:frontend/features/repair_request/presentation/widgets/add_address_dialog.dart';
import 'package:frontend/features/repair_request/presentation/widgets/image_picker_box_widget.dart';
import 'package:frontend/features/repair_request/presentation/screens/create_repair_request_screen.dart';
import 'package:frontend/features/repair_request/presentation/widgets/request_item_card_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';


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

    test('RepairRequestModel parses location and coordinates correctly from JSON', () {
      final json = {
        '_id': 'req_456',
        'customerId': 'user_123',
        'serviceCategoryId': 'cat_123',
        'title': 'Sửa máy lạnh chảy nước',
        'description': 'Máy lạnh rỉ nước xuống sàn nhà',
        'location': {
          'address': '227 Nguyễn Văn Cừ, Quận 5, TP.HCM',
          'latitude': 10.762622,
          'longitude': 106.682245,
        },
        'urgency': 'medium',
        'status': 'OPEN',
        'contactPhone': '0901234567',
        'createdAt': '2026-10-18T10:00:00.000Z',
        'updatedAt': '2026-10-18T10:00:00.000Z',
      };

      final model = RepairRequestModel.fromJson(json);

      expect(model.location.address, '227 Nguyễn Văn Cừ, Quận 5, TP.HCM');
      expect(model.location.latitude, 10.762622);
      expect(model.location.longitude, 106.682245);
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

    testWidgets('AddAddressDialog renders full recipient, phone and administrative fields inside showDialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => showDialog(context: ctx, builder: (_) => const AddAddressDialog()),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Thêm địa chỉ mới'), findsOneWidget);
      expect(find.text('Họ và tên người nhận *'), findsOneWidget);
      expect(find.text('Số điện thoại liên hệ *'), findsOneWidget);
      expect(find.text('Tỉnh / Thành phố *'), findsOneWidget);
      expect(find.text('Quận / Huyện *'), findsOneWidget);
      expect(find.text('Phường / Xã (sau sáp nhập) *'), findsOneWidget);
      expect(find.text('Địa chỉ cụ thể (Số nhà, ngõ/ngách, tên đường) *'), findsOneWidget);
      expect(find.text('Lưu & Chọn'), findsOneWidget);
    });

    testWidgets('Tapping Thêm mới from address book opens AddAddressDialog cleanly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: ctx,
                    builder: (modalCtx) => ElevatedButton(
                      key: const Key('modal_add_button'),
                      onPressed: () {
                        Navigator.pop(modalCtx);
                        showDialog(context: ctx, builder: (_) => const AddAddressDialog());
                      },
                      child: const Text('Add in modal'),
                    ),
                  );
                },
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Add in modal'), findsOneWidget);
      await tester.tap(find.byKey(const Key('modal_add_button')));
      await tester.pumpAndSettle();

      expect(find.text('Thêm địa chỉ mới'), findsOneWidget);
    });

    testWidgets('CreateRepairRequestScreen has only pick_address_book_button and no outside add button, and tapping Thêm mới inside modal opens AddAddressDialog cleanly', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({});
      final mockCategory = ServiceCategoryModel(
        id: 'cat_test',
        name: 'Sửa điện tử',
        slug: 'dien-tu',
        description: 'Mô tả test',
        icon: 'devices',
        color: '#2563EB',
        isActive: true,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => RepairRequestProvider()),
          ],
          child: MaterialApp(
            home: CreateRepairRequestScreen(preselectedCategory: mockCategory),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Nút Danh bạ địa chỉ hiển thị trên form
      expect(find.byKey(const Key('pick_address_book_button')), findsOneWidget);
      // Nút Thêm mới ở ngoài ĐÃ ĐƯỢC BỎ
      expect(find.byKey(const Key('direct_add_new_address_button')), findsNothing);

      // Bấm vào Danh bạ địa chỉ để mở bottom sheet
      await tester.tap(find.byKey(const Key('pick_address_book_button')));
      await tester.pumpAndSettle();

      // Nút Thêm mới bên trong danh bạ tồn tại
      expect(find.byKey(const Key('address_picker_add_new_button')), findsOneWidget);

      // Bấm Thêm mới trong danh bạ -> bottom sheet tự đóng và mở AddAddressDialog
      await tester.tap(find.byKey(const Key('address_picker_add_new_button')));
      await tester.pumpAndSettle();

      expect(find.text('Thêm địa chỉ mới'), findsOneWidget);
      expect(find.text('Họ và tên *'), findsOneWidget);
      expect(find.text('Số điện thoại liên hệ *'), findsOneWidget);
      expect(find.text('Tỉnh / Thành phố *'), findsOneWidget);
      expect(find.text('Phường / Xã (sau sáp nhập) *'), findsOneWidget);

      // Thử nhập @@@@ vào ô địa chỉ cụ thể và bấm Lưu -> phải bị chặn lỗi
      await tester.enterText(find.byKey(const Key('add_address_street_field')), '@@@@');
      await tester.tap(find.byKey(const Key('add_address_save_button')));
      await tester.pumpAndSettle();

      expect(find.text('Địa chỉ cụ thể phải bao gồm chữ hoặc số hợp lệ (số nhà, tên đường)'), findsOneWidget);
    });

    test('RepairRequestModel parses cancellationReason and cancelledAt correctly from JSON', () {
      final json = {
        '_id': 'req_cancel_1',
        'customerId': 'user_123',
        'serviceCategoryId': 'cat_123',
        'title': 'Sửa quạt trần rung lắc mạnh',
        'description': 'Quạt trần rung lắc nguy hiểm khi bật số 3',
        'urgency': 'high',
        'status': 'CANCELLED',
        'cancellationReason': 'Đã tự khắc phục được sự cố',
        'cancelledAt': '2026-10-19T14:30:00.000Z',
        'createdAt': '2026-10-19T10:00:00.000Z',
        'updatedAt': '2026-10-19T14:30:00.000Z',
      };

      final model = RepairRequestModel.fromJson(json);

      expect(model.id, 'req_cancel_1');
      expect(model.status, 'CANCELLED');
      expect(model.cancellationReason, 'Đã tự khắc phục được sự cố');
      expect(model.cancelledAt, isNotNull);
      expect(model.statusDisplay, 'Đã hủy');
    });

    testWidgets('RequestItemCardWidget displays cancel button for OPEN request and triggers onCancelPressed', (tester) async {
      bool cancelCalled = false;
      final openRequest = RepairRequestModel(
        id: 'req_open_1',
        customerId: 'user_1',
        serviceCategoryId: 'cat_1',
        title: 'Sửa đường ống nước bồn rửa chén',
        description: 'Ống nước dưới bồn rửa bị rò rỉ nước',
        status: 'OPEN',
        urgency: 'medium',
        contactPhone: '0901234567',
        location: const RepairLocationModel(address: '123 Đường Số 1, Quận 1'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RequestItemCardWidget(
              request: openRequest,
              onCancelPressed: () {
                cancelCalled = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Hủy yêu cầu'), findsOneWidget);
      await tester.tap(find.text('Hủy yêu cầu'));
      await tester.pumpAndSettle();

      expect(cancelCalled, isTrue);
    });

    testWidgets('RequestItemCardWidget hides cancel button when request is ACCEPTED or CANCELLED', (tester) async {
      final acceptedRequest = RepairRequestModel(
        id: 'req_acc_1',
        customerId: 'user_1',
        serviceCategoryId: 'cat_1',
        title: 'Sửa bồn cầu rỉ nước',
        description: 'Bồn cầu bị rỉ nước liên tục',
        status: 'ACCEPTED',
        urgency: 'low',
        contactPhone: '0901234567',
        location: const RepairLocationModel(address: '456 Đường Số 2, Quận 3'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );



      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RequestItemCardWidget(
              request: acceptedRequest,
              onCancelPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Hủy yêu cầu'), findsNothing);
    });
  });
}



