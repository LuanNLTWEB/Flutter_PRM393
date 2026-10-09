import 'package:flutter/material.dart';
import '../../data/datasources/review_remote_datasource.dart';
import '../../data/models/review_model.dart';

class ReviewProvider extends ChangeNotifier {
  final ReviewRemoteDataSource _dataSource;

  ReviewProvider({ReviewRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? ReviewRemoteDataSource();

  List<String> _tags = [];
  ReviewSummaryModel? _summary;
  List<ReviewModel> _reviews = [];
  bool _isLoading = false;
  List<Map<String, dynamic>> _technicians = [];
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _successMessage;
  int? _selectedStarFilter;

  List<String> get tags => _tags;
  List<Map<String, dynamic>> get technicians => _technicians;
  ReviewSummaryModel? get summary => _summary;
  List<ReviewModel> get reviews => _reviews;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  int? get selectedStarFilter => _selectedStarFilter;

  /// Tải danh sách thợ kỹ thuật
  Future<void> loadTechnicians() async {
    try {
      _technicians = await _dataSource.getTechnicians();
      notifyListeners();
    } catch (_) {}
  }

  /// Tải danh sách tag gợi ý
  Future<void> loadTags() async {
    try {
      _tags = await _dataSource.getReviewTags();
      notifyListeners();
    } catch (_) {}
  }

  /// Tải danh sách đánh giá của thợ
  Future<void> fetchTechnicianReviews(String technicianId, {int? star}) async {
    _isLoading = true;
    _errorMessage = null;
    _selectedStarFilter = star;
    notifyListeners();

    try {
      final result = await _dataSource.getTechnicianReviews(
        technicianId: technicianId,
        star: star,
      );

      _summary = result['summary'] as ReviewSummaryModel?;
      _reviews = result['reviews'] as List<ReviewModel>? ?? [];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  /// Gửi đánh giá cho thợ (UC-RAT-01 - Bắt buộc gắn với đơn hàng COMPLETED)
  Future<bool> submitReview({
    required String token,
    required String technicianId,
    required double rating,
    required List<String> tags,
    required String comment,
    required String bookingId,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final newReview = await _dataSource.createReview(
        token: token,
        technicianId: technicianId,
        rating: rating,
        tags: tags,
        comment: comment,
        bookingId: bookingId,
      );

      // Cập nhật danh sách hiển thị
      _reviews.insert(0, newReview);
      _isSubmitting = false;
      _successMessage = 'Gửi đánh giá thành công! Cảm ơn bạn đã phản hồi.';
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void clearMessage() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
