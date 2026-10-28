import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/complaint/data/models/complaint_model.dart';
import 'package:frontend/features/complaint/presentation/providers/complaint_provider.dart';

void main() {
  group('UC-STF-03: Complaint management tests', () {
    test('ComplaintModel parses populated parties and displays status', () {
      final complaint = ComplaintModel.fromJson({
        '_id': 'complaint_01',
        'requestId': {
          '_id': 'request_01',
          'title': 'Máy lạnh không mát',
          'status': 'COMPLETED',
        },
        'reporterId': {'fullName': 'Nguyễn Khách', 'role': 'user'},
        'respondentId': {'fullName': 'Trần Thợ', 'role': 'technician'},
        'category': 'PRICING',
        'subject': 'Chi phí linh kiện chưa rõ ràng',
        'description': 'Khách hàng cần Staff đối chiếu lại chi phí linh kiện.',
        'staffNote': '',
        'status': 'IN_REVIEW',
        'createdAt': '2026-10-20T08:30:00.000Z',
      });

      expect(complaint.requestTitle, 'Máy lạnh không mát');
      expect(complaint.reporterName, 'Nguyễn Khách');
      expect(complaint.respondentName, 'Trần Thợ');
      expect(complaint.categoryDisplay, 'Chi phí / báo giá');
      expect(complaint.statusDisplay, 'Đang xử lý');
      expect(complaint.isFinal, isFalse);
    });

    test('ComplaintModel marks final resolution statuses correctly', () {
      final complaint = ComplaintModel.fromJson({
        '_id': 'complaint_02',
        'status': 'RESOLVED',
      });

      expect(complaint.isFinal, isTrue);
      expect(complaint.statusDisplay, 'Đã giải quyết');
    });

    test('ComplaintProvider starts with an empty management queue', () {
      final provider = ComplaintProvider();

      expect(provider.complaints, isEmpty);
      expect(provider.countOf('RECEIVED'), 0);
      expect(provider.statusFilter, 'ALL');
      expect(provider.isLoading, isFalse);
      expect(provider.isActionLoading, isFalse);
    });
  });
}
