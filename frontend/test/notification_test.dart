import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/notification/data/models/notification_model.dart';
import 'package:frontend/features/notification/presentation/providers/notification_provider.dart';

void main() {
  group('UC-NOT-02: Notification Center Tests', () {
    test('NotificationModel fromJson & toJson serialize correctly', () {
      final json = {
        '_id': 'notif_001',
        'title': 'Thợ đang trên đường đến',
        'message': 'Thợ Nguyễn Văn A đang di chuyển đến nhà bạn.',
        'type': 'ORDER_STATUS',
        'data': {'requestId': 'req_123', 'status': 'ON_THE_WAY'},
        'isRead': false,
        'readAt': null,
        'createdAt': '2026-10-19T10:00:00.000Z',
      };

      final notif = NotificationModel.fromJson(json);

      expect(notif.id, 'notif_001');
      expect(notif.title, 'Thợ đang trên đường đến');
      expect(notif.type, 'ORDER_STATUS');
      expect(notif.typeDisplay, 'Trạng thái đơn');
      expect(notif.iconData, Icons.local_shipping_outlined);
      expect(notif.isRead, isFalse);
      expect(notif.data['requestId'], 'req_123');

      final serialized = notif.toJson();
      expect(serialized['_id'], 'notif_001');
      expect(serialized['type'], 'ORDER_STATUS');
    });

    test('NotificationModel localizes types properly', () {
      final orderNotif = NotificationModel(
        id: '1',
        title: 'Order',
        message: 'Order msg',
        type: 'ORDER_STATUS',
        createdAt: DateTime.now(),
      );
      expect(orderNotif.typeDisplay, 'Trạng thái đơn');
      expect(orderNotif.typeColor, Colors.blue);

      final quoteNotif = orderNotif.copyWith(type: 'QUOTATION');
      expect(quoteNotif.typeDisplay, 'Báo giá');
      expect(quoteNotif.typeColor, Colors.green);

      final kycNotif = orderNotif.copyWith(type: 'KYC');
      expect(kycNotif.typeDisplay, 'Hồ sơ xét duyệt');

      final apptNotif = orderNotif.copyWith(type: 'APPOINTMENT');
      expect(apptNotif.typeDisplay, 'Lịch hẹn');

      final sysNotif = orderNotif.copyWith(type: 'SYSTEM');
      expect(sysNotif.typeDisplay, 'Hệ thống');
    });

    test('NotificationModel timeAgo formats relative time', () {
      final justNow = NotificationModel(
        id: '1',
        title: 'Test',
        message: 'Msg',
        createdAt: DateTime.now().subtract(const Duration(seconds: 20)),
      );
      expect(justNow.timeAgo, 'Vừa xong');

      final minutesAgo = NotificationModel(
        id: '2',
        title: 'Test',
        message: 'Msg',
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      );
      expect(minutesAgo.timeAgo, '15 phút trước');

      final hoursAgo = NotificationModel(
        id: '3',
        title: 'Test',
        message: 'Msg',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      );
      expect(hoursAgo.timeAgo, '3 giờ trước');
    });

    test('NotificationProvider initial state and filters work correctly', () {
      final provider = NotificationProvider();

      expect(provider.notifications, isEmpty);
      expect(provider.unreadCount, 0);
      expect(provider.isLoading, isFalse);
      expect(provider.filterType, isNull);
      expect(provider.filterUnreadOnly, isFalse);

      provider.setFilterUnreadOnly(true);
      expect(provider.filterUnreadOnly, isTrue);

      provider.setFilterType('QUOTATION');
      expect(provider.filterType, 'QUOTATION');

      provider.clearErrorMessage();
      expect(provider.errorMessage, isNull);
    });
  });
}
