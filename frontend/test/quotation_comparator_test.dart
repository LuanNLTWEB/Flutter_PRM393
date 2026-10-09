import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/quotations/data/models/quotation_model.dart';
import 'package:frontend/features/quotations/domain/quotation_comparator.dart';

QuotationModel _quote({
  required String id,
  double labour = 100000,
  double parts = 0,
  double rating = 5.0,
  int completedJobs = 0,
  String status = 'SENT',
}) {
  return QuotationModel(
    id: id,
    requestId: 'req1',
    technicianId: 'tech_$id',
    labourCost: labour,
    partsCost: parts,
    total: labour + parts,
    status: status,
    createdAt: DateTime(2026, 10, 9),
    rating: rating,
    completedJobsCount: completedJobs,
  );
}

void main() {
  group('QuotationComparator.computeTotal', () {
    test('Tổng = tiền công + giá linh kiện', () {
      expect(QuotationComparator.computeTotal(150000, 50000), 200000);
      expect(QuotationComparator.computeTotal(0, 0), 0);
      expect(QuotationComparator.computeTotal(120000.5, 0.5), 120001.0);
    });
  });

  group('QuotationComparator.isValidAmount', () {
    test('Chấp nhận số không âm', () {
      expect(QuotationComparator.isValidAmount(0), isTrue);
      expect(QuotationComparator.isValidAmount(150000), isTrue);
    });

    test('Từ chối số âm, null, NaN, vô cực', () {
      expect(QuotationComparator.isValidAmount(-1), isFalse);
      expect(QuotationComparator.isValidAmount(null), isFalse);
      expect(QuotationComparator.isValidAmount(double.nan), isFalse);
      expect(QuotationComparator.isValidAmount(double.infinity), isFalse);
    });
  });

  group('QuotationComparator.sort', () {
    test('totalAsc: báo giá tổng thấp đứng đầu', () {
      final sorted = QuotationComparator.sort(
        [
          _quote(id: 'a', labour: 300000),
          _quote(id: 'b', labour: 100000),
          _quote(id: 'c', labour: 200000),
        ],
        key: QuotationSortKey.totalAsc,
      );

      expect(sorted.map((q) => q.id).toList(), ['b', 'c', 'a']);
    });

    test('totalAsc: bằng giá thì đánh giá cao hơn thắng', () {
      final sorted = QuotationComparator.sort(
        [
          _quote(id: 'low', labour: 200000, rating: 3.0),
          _quote(id: 'high', labour: 200000, rating: 5.0),
        ],
        key: QuotationSortKey.totalAsc,
      );

      expect(sorted.first.id, 'high');
    });

    test('ratingDesc: đánh giá cao đứng đầu', () {
      final sorted = QuotationComparator.sort(
        [
          _quote(id: 'a', rating: 3.5),
          _quote(id: 'b', rating: 4.8),
        ],
        key: QuotationSortKey.ratingDesc,
      );

      expect(sorted.map((q) => q.id).toList(), ['b', 'a']);
    });

    test('completedJobsDesc: thợ nhiều kinh nghiệm hơn đứng đầu', () {
      final sorted = QuotationComparator.sort(
        [
          _quote(id: 'new', completedJobs: 3),
          _quote(id: 'exp', completedJobs: 42),
        ],
        key: QuotationSortKey.completedJobsDesc,
      );

      expect(sorted.first.id, 'exp');
    });

    test('distanceAsc: không có khoảng cách thì xếp cuối', () {
      final sorted = QuotationComparator.sort(
        [
          _quote(id: 'unknown'),
          _quote(id: 'near'),
          _quote(id: 'far'),
        ],
        key: QuotationSortKey.distanceAsc,
        distances: {'near': 1.2, 'far': 9.5},
      );

      expect(sorted.map((q) => q.id).toList(), ['near', 'far', 'unknown']);
    });

    test('Không làm thay đổi danh sách gốc', () {
      final original = [
        _quote(id: 'a', labour: 300000),
        _quote(id: 'b', labour: 100000),
      ];
      QuotationComparator.sort(original, key: QuotationSortKey.totalAsc);

      expect(original.first.id, 'a');
    });
  });

  group('QuotationComparator.bestValue', () {
    test('Chọn báo giá rẻ nhất trong các báo giá còn hiệu lực', () {
      final best = QuotationComparator.bestValue([
        _quote(id: 'a', labour: 300000),
        _quote(id: 'b', labour: 100000),
        _quote(id: 'c', labour: 50000, status: 'RETRACTED'),
      ]);

      expect(best?.id, 'b');
    });

    test('Trả về null khi không có báo giá SENT', () {
      expect(
        QuotationComparator.bestValue([
          _quote(id: 'a', status: 'REJECTED'),
        ]),
        isNull,
      );
    });
  });

  group('QuotationModel', () {
    test('fromJson đọc đúng dữ liệu technician đã populate', () {
      final quote = QuotationModel.fromJson({
        '_id': 'q1',
        'requestId': 'r1',
        'technicianId': {
          '_id': 't1',
          'fullName': 'Nguyễn Văn A',
          'avatar': 'https://example.com/a.jpg',
          'technicianProfile': {
            'rating': 4.6,
            'reviewCount': 12,
            'completedJobsCount': 30,
            'isAvailable': true,
            'skills': ['Điện', 'Nước'],
          },
        },
        'labourCost': 150000,
        'partsCost': 50000,
        'total': 200000,
        'note': 'Đến sau 6h',
        'status': 'SENT',
        'createdAt': '2026-10-09T08:00:00.000Z',
      });

      expect(quote.id, 'q1');
      expect(quote.technicianId, 't1');
      expect(quote.technicianName, 'Nguyễn Văn A');
      expect(quote.rating, 4.6);
      expect(quote.completedJobsCount, 30);
      expect(quote.skills, ['Điện', 'Nước']);
      expect(quote.total, 200000);
      expect(quote.statusDisplay, 'Đã gửi');
      expect(quote.canEdit, isTrue);
      expect(quote.starRating, 5);
    });

    test('technicianId là chuỗi vẫn parse được', () {
      final quote = QuotationModel.fromJson({
        '_id': 'q2',
        'requestId': 'r1',
        'technicianId': 't2',
        'labourCost': 100000,
        'partsCost': 0,
        'total': 100000,
        'status': 'ACCEPTED',
      });

      expect(quote.technicianId, 't2');
      expect(quote.canEdit, isFalse);
      expect(quote.statusDisplay, 'Đã chốt');
    });

    test('requestId đã populate (object) vẫn lấy đúng id', () {
      final quote = QuotationModel.fromJson({
        '_id': 'q9',
        'requestId': {'_id': 'r9', 'title': 'Sửa điện', 'status': 'QUOTED'},
        'technicianId': 't9',
        'labourCost': 100000,
        'partsCost': 0,
        'total': 100000,
        'status': 'SENT',
      });

      expect(quote.requestId, 'r9');
      expect(quote.status, 'SENT');
    });
  });
}
