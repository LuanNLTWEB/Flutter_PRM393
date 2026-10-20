import 'package:flutter/material.dart';
import '../../data/datasources/nearby_request_remote_datasource.dart';
import '../../data/datasources/quotation_remote_datasource.dart';
import '../../data/models/quotation_model.dart';
import '../../domain/quotation_comparator.dart';
import '../../../repair_request/data/models/repair_request_model.dart';

/// State quản lý toàn bộ tính năng Báo giá & Khớp lệnh (Epic UC-QUO)
class QuotationProvider extends ChangeNotifier {
  final QuotationRemoteDataSource _quotationDataSource;
  final NearbyRequestRemoteDataSource _requestDataSource;

  QuotationProvider({
    QuotationRemoteDataSource? quotationDataSource,
    NearbyRequestRemoteDataSource? requestDataSource,
  })  : _quotationDataSource =
            quotationDataSource ?? QuotationRemoteDataSource(),
        _requestDataSource = requestDataSource ?? NearbyRequestRemoteDataSource();

  // Feed yêu cầu cho Thợ (UC-QUO-01 / UC-QUO-02)
  List<RepairRequestModel> _nearbyRequests = [];
  bool _hasLocation = false;

  // Chi tiết yêu cầu (UC-QUO-03)
  RepairRequestModel? _selectedRequest;

  // Báo giá của 1 yêu cầu (UC-QUO-06 / UC-QUO-07)
  List<QuotationModel> _quotations = [];
  String _requestStatus = 'OPEN';
  QuotationSortKey _sortKey = QuotationSortKey.totalAsc;

  // "Yêu cầu đã báo giá" của Thợ (UC-QUO-05)
  List<MyQuotationItem> _myQuotes = [];

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _successMessage;

  List<RepairRequestModel> get nearbyRequests => _nearbyRequests;
  bool get hasLocation => _hasLocation;
  RepairRequestModel? get selectedRequest => _selectedRequest;
  List<QuotationModel> get quotations => _quotations;
  String get requestStatus => _requestStatus;
  QuotationSortKey get sortKey => _sortKey;
  List<MyQuotationItem> get myQuotes => _myQuotes;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  /// Danh sách báo giá đã sắp xếp theo khóa đang chọn (UC-QUO-07)
  List<QuotationModel> get sortedQuotations =>
      QuotationComparator.sort(_quotations, key: _sortKey);

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void setSortKey(QuotationSortKey key) {
    _sortKey = key;
    notifyListeners();
  }

  /// Tải feed yêu cầu đang mở (UC-QUO-01)
  Future<void> fetchNearbyRequests({
    required String token,
    String? categorySlug,
    String? urgency,
    double? latitude,
    double? longitude,
    double? radiusKm,
    bool refresh = false,
  }) async {
    if (!refresh && _nearbyRequests.isNotEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _requestDataSource.fetchNearbyRequests(
        token: token,
        categorySlug: categorySlug,
        urgency: urgency,
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
      _nearbyRequests = result.requests;
      _hasLocation = result.hasLocation;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
// END UC-QUO-01

  // START UC-QUO-03: Tải chi tiết sự cố
  /// Tải chi tiết phiếu yêu cầu (UC-QUO-03)
  Future<void> fetchRequestDetail({
    required String token,
    required String id,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedRequest =
          await _requestDataSource.fetchRequestDetail(token: token, id: id);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  // END UC-QUO-03

  // START UC-QUO-06: Tải danh sách báo giá nhận được
  /// Tải danh sách báo giá của 1 yêu cầu (UC-QUO-06)
  Future<void> fetchQuotations({
    required String token,
    required String requestId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result =
          await _quotationDataSource.fetchQuotations(token: token, requestId: requestId);
      _quotations = result.quotations;
      _requestStatus = result.requestStatus;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  // END UC-QUO-06

  // START UC-QUO-05: Danh sách báo giá Thợ đã gửi
  /// Tải danh sách "Yêu cầu đã báo giá" của Thợ (UC-QUO-05)
  Future<void> fetchMyQuotations({
    required String token,
    bool refresh = false,
  }) async {
    if (!refresh && _myQuotes.isNotEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _myQuotes = await _quotationDataSource.fetchMyQuotations(token: token);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  // END UC-QUO-05

  // START UC-QUO-04: Thợ gửi báo giá
  /// Thợ gửi báo giá (UC-QUO-04)
  Future<bool> sendQuotation({
    required String token,
    required String requestId,
    required double labourCost,
    double partsCost = 0,
    String note = '',
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final quotation = await _quotationDataSource.sendQuotation(
        token: token,
        requestId: requestId,
        labourCost: labourCost,
        partsCost: partsCost,
        note: note,
      );

      _quotations = [
        quotation,
        ..._quotations.where((q) => q.id != quotation.id),
      ];
      if (_requestStatus == 'OPEN') _requestStatus = 'QUOTED';

      _successMessage = 'Gửi báo giá thành công';
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }
  // END UC-QUO-04

  // START UC-QUO-05: Cập nhật báo giá
  /// Thợ sửa báo giá (UC-QUO-05)
  Future<bool> updateQuotation({
    required String token,
    required String id,
    required double labourCost,
    double partsCost = 0,
    String note = '',
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final updated = await _quotationDataSource.updateQuotation(
        token: token,
        id: id,
        labourCost: labourCost,
        partsCost: partsCost,
        note: note,
      );

      _quotations = _quotations
          .map((q) => q.id == updated.id ? updated : q)
          .toList();
      _myQuotes = _myQuotes
          .map((item) => item.quote.id == updated.id
              ? MyQuotationItem(quote: updated, request: item.request)
              : item)
          .toList();

      _successMessage = 'Cập nhật báo giá thành công';
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }
  // END UC-QUO-05

  // START UC-QUO-05: Thu hồi báo giá
  /// Thợ thu hồi báo giá (UC-QUO-05)
  Future<bool> retractQuotation({
    required String token,
    required String id,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _quotationDataSource.retractQuotation(token: token, id: id);

      _quotations = _quotations
          .map((q) => q.id == id ? _copyWithStatus(q, 'RETRACTED') : q)
          .toList();
      _myQuotes = _myQuotes
          .map((item) => item.quote.id == id
              ? MyQuotationItem(
                  quote: _copyWithStatus(item.quote, 'RETRACTED'),
                  request: item.request,
                )
              : item)
          .toList();

      // Hết báo giá đang mở thì yêu cầu quay lại trạng thái OPEN
      if (_quotations.isNotEmpty && _quotations.every((q) => q.status != 'SENT')) {
        _requestStatus = 'OPEN';
      }

      _successMessage = 'Đã thu hồi báo giá';
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }
  // END UC-QUO-05

  // START UC-QUO-08: Khách chấp nhận báo giá (Accept)
  /// Khách chấp nhận báo giá - chốt thợ (UC-QUO-08)
  Future<bool> acceptQuotation({
    required String token,
    required String id,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _quotationDataSource.acceptQuotation(token: token, id: id);

      // Báo giá được chọn thành ACCEPTED, các báo giá còn lại bị REJECTED
      _quotations = _quotations
          .map((q) => _copyWithStatus(q, q.id == id ? 'ACCEPTED' : 'REJECTED'))
          .toList();
      _requestStatus = 'ACCEPTED';

      _successMessage = 'Đã chốt thợ thành công';
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }
  // END UC-QUO-08

  // START UC-QUO-09: Khách từ chối báo giá
  /// Khách từ chối 1 báo giá (UC-QUO-09)
  Future<bool> rejectQuotation({
    required String token,
    required String id,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _quotationDataSource.rejectQuotation(token: token, id: id);

      _quotations = _quotations
          .map((q) => q.id == id ? _copyWithStatus(q, 'REJECTED') : q)
          .toList();

      // Không còn báo giá nào đang mở thì yêu cầu quay lại OPEN
      if (_quotations.isNotEmpty &&
          _quotations.every((q) => q.status != 'SENT') &&
          _requestStatus == 'QUOTED') {
        _requestStatus = 'OPEN';
      }

      _successMessage = 'Đã từ chối báo giá';
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }
  // END UC-QUO-09

  // UC-LIC-01 / UC-DI-01: Lịch hẹn & đang trên đường (ngoài epic Báo giá)

  /// Thợ xác nhận giờ hẹn (UC-LIC-01)
  Future<bool> confirmAppointment({
    required String token,
    required String requestId,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _requestDataSource.confirmAppointment(
        token: token,
        requestId: requestId,
      );
      _updateMyQuoteRequest(requestId, (request) => request.copyWith(
            appointmentStatus: 'CONFIRMED',
            proposedTime: null,
            rescheduleNote: '',
            rescheduleRejectNote: '',
          ));
      _successMessage = 'Xác nhận lịch hẹn thành công';
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  /// Thợ đề xuất khung giờ mới (UC-LIC-01)
  Future<bool> proposeAppointment({
    required String token,
    required String requestId,
    required DateTime proposedTime,
    String note = '',
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _requestDataSource.proposeAppointment(
        token: token,
        requestId: requestId,
        proposedTime: proposedTime,
        note: note,
      );
      _updateMyQuoteRequest(requestId, (request) => request.copyWith(
            appointmentStatus: 'RESCHEDULED',
            proposedTime: proposedTime,
            rescheduleNote: note,
            rescheduleRejectNote: '',
          ));
      _successMessage = 'Đề xuất khung giờ mới thành công';
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  /// Thợ bấm "Đang trên đường đến nhà khách" (UC-DI-01)
  Future<bool> markOnTheWay({
    required String token,
    required String requestId,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _requestDataSource.markOnTheWay(
        token: token,
        requestId: requestId,
      );
      _updateMyQuoteRequest(requestId, (request) => request.copyWith(
            status: 'ON_THE_WAY',
          ));
      _successMessage = 'Đã cập nhật: đang trên đường đến nhà khách';
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  /// Thợ bấm "Đã có mặt tại hiện trường" (UC-ARR-01)
  Future<bool> markArrived({
    required String token,
    required String requestId,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _requestDataSource.markArrived(
        token: token,
        requestId: requestId,
      );
      _updateMyQuoteRequest(requestId, (request) => request.copyWith(
            status: 'IN_PROGRESS',
          ));
      _successMessage = 'Đã cập nhật: đã có mặt tại hiện trường';
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  void _updateMyQuoteRequest(
    String requestId,
    RepairRequestModel Function(RepairRequestModel) update,
  ) {
    _myQuotes = _myQuotes
        .map((item) => item.request.id == requestId
            ? MyQuotationItem(quote: item.quote, request: update(item.request))
            : item)
        .toList();
  }

  QuotationModel _copyWithStatus(QuotationModel q, String status) {
    return QuotationModel(
      id: q.id,
      requestId: q.requestId,
      technicianId: q.technicianId,
      labourCost: q.labourCost,
      partsCost: q.partsCost,
      total: q.total,
      note: q.note,
      status: status,
      createdAt: q.createdAt,
      resolvedAt: DateTime.now(),
      technicianName: q.technicianName,
      technicianAvatar: q.technicianAvatar,
      rating: q.rating,
      reviewCount: q.reviewCount,
      completedJobsCount: q.completedJobsCount,
      technicianIsAvailable: q.technicianIsAvailable,
      skills: q.skills,
    );
  }
}
