import '../data/models/quotation_model.dart';

/// Thứ tự sắp xếp bảng so sánh báo giá (UC-QUO-07)
enum QuotationSortKey { totalAsc, ratingDesc, completedJobsDesc, distanceAsc }

/// Logic so sánh báo giá thuần (không phụ thuộc UI) -> dễ unit test
class QuotationComparator {
  QuotationComparator._();

  /// Tổng chi phí = tiền công + giá linh kiện
  static double computeTotal(num labourCost, num partsCost) {
    return labourCost.toDouble() + partsCost.toDouble();
  }

  /// Kiểm tra số tiền hợp lệ (không âm, là số)
  static bool isValidAmount(num? value) {
    if (value == null) return false;
    if (value.isNaN || value.isInfinite) return false;
    return value >= 0;
  }

  /// Sắp xếp danh sách báo giá theo khóa đã chọn.
  /// [distances]: khoảng cách km theo quotationId (chưa có dữ liệu thì bỏ qua).
  /// Bản ghi không có khoảng cách luôn nằm cuối danh sách.
  static List<QuotationModel> sort(
    List<QuotationModel> quotes, {
    required QuotationSortKey key,
    Map<String, double> distances = const {},
  }) {
    final sorted = List<QuotationModel>.from(quotes);

    sorted.sort((a, b) {
      switch (key) {
        case QuotationSortKey.totalAsc:
          final diff = a.total.compareTo(b.total);
          if (diff != 0) return diff;
          return b.rating.compareTo(a.rating);
        case QuotationSortKey.ratingDesc:
          final diff = b.rating.compareTo(a.rating);
          if (diff != 0) return diff;
          return a.total.compareTo(b.total);
        case QuotationSortKey.completedJobsDesc:
          final diff = b.completedJobsCount.compareTo(a.completedJobsCount);
          if (diff != 0) return diff;
          return a.total.compareTo(b.total);
        case QuotationSortKey.distanceAsc:
          final da = distances[a.id];
          final db = distances[b.id];
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
      }
    });

    return sorted;
  }

  /// Chọn báo giá tốt nhất: giá thấp nhất, sau đó đánh giá cao nhất
  static QuotationModel? bestValue(List<QuotationModel> quotes) {
    final candidates =
        quotes.where((q) => q.status == 'SENT').toList(growable: false);
    if (candidates.isEmpty) return null;
    return sort(candidates, key: QuotationSortKey.totalAsc).first;
  }
}
