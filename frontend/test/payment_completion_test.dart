import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:frontend/features/completion/data/datasources/completion_remote_datasource.dart';
import 'package:frontend/features/completion/data/models/completion_qr_model.dart';
import 'package:frontend/features/completion/presentation/providers/completion_provider.dart';
import 'package:frontend/features/payment/data/datasources/payment_remote_datasource.dart';
import 'package:frontend/features/payment/data/models/invoice_model.dart';
import 'package:frontend/features/payment/presentation/providers/payment_provider.dart';
import 'package:frontend/features/order_history/data/models/order_history_model.dart';
import 'package:frontend/features/repair_request/data/models/repair_request_model.dart';

InvoiceModel _invoice({
  String? paymentMethod,
  String paymentStatus = 'UNPAID',
  List<String> partsInvoiceImages = const [],
}) {
  return InvoiceModel(
    requestId: 'request-1',
    quotationId: 'quotation-1',
    serviceTitle: 'Sửa máy lạnh',
    serviceCategoryName: 'Điện lạnh',
    technicianName: 'Thợ A',
    technicianAvatar: '',
    labourCost: 300000,
    partsCost: 150000,
    total: 450000,
    requestStatus: 'IN_PROGRESS',
    completionImages: const ['https://example.com/completion.jpg'],
    partsInvoiceImages: partsInvoiceImages,
    paymentMethod: paymentMethod,
    paymentStatus: paymentStatus,
  );
}

class _FakePaymentDataSource extends PaymentRemoteDataSource {
  InvoiceModel invoice = _invoice();
  bool failFetch = false;
  bool failSelect = false;
  bool failUploadParts = false;
  bool failConfirmPayment = false;

  @override
  Future<InvoiceModel> getInvoice({
    required String token,
    required String requestId,
  }) async {
    if (failFetch) throw Exception('Không có quyền xem hóa đơn');
    return invoice;
  }

  @override
  Future<InvoiceModel> selectPaymentMethod({
    required String token,
    required String requestId,
    required String paymentMethod,
  }) async {
    if (failSelect) throw Exception('Không thể lưu phương thức');
    invoice = _invoice(paymentMethod: paymentMethod);
    return invoice;
  }

  @override
  Future<InvoiceModel> uploadPartsInvoiceImages({
    required String token,
    required String requestId,
    required List<XFile> images,
  }) async {
    if (failUploadParts) throw Exception('Không thể tải ảnh hóa đơn linh kiện');
    invoice = InvoiceModel(
      requestId: invoice.requestId,
      quotationId: invoice.quotationId,
      serviceTitle: invoice.serviceTitle,
      serviceCategoryName: invoice.serviceCategoryName,
      technicianName: invoice.technicianName,
      technicianAvatar: invoice.technicianAvatar,
      labourCost: invoice.labourCost,
      partsCost: invoice.partsCost,
      total: invoice.total,
      requestStatus: invoice.requestStatus,
      completionImages: invoice.completionImages,
      partsInvoiceImages:
          images.map((img) => 'https://example.com/${img.name}').toList(),
      paymentMethod: invoice.paymentMethod,
      paymentStatus: invoice.paymentStatus,
    );
    return invoice;
  }

  @override
  Future<InvoiceModel> confirmPaymentReceived({
    required String token,
    required String requestId,
  }) async {
    if (failConfirmPayment) throw Exception('Không thể xác nhận thanh toán');
    invoice = InvoiceModel(
      requestId: invoice.requestId,
      quotationId: invoice.quotationId,
      serviceTitle: invoice.serviceTitle,
      serviceCategoryName: invoice.serviceCategoryName,
      technicianName: invoice.technicianName,
      technicianAvatar: invoice.technicianAvatar,
      labourCost: invoice.labourCost,
      partsCost: invoice.partsCost,
      total: invoice.total,
      requestStatus: invoice.requestStatus,
      completionImages: invoice.completionImages,
      partsInvoiceImages: invoice.partsInvoiceImages,
      paymentMethod: 'CASH',
      paymentStatus: 'PAID',
      paidAt: DateTime(2026, 10, 28, 17, 0),
    );
    return invoice;
  }
}

class _FakeCompletionDataSource extends CompletionRemoteDataSource {
  bool fail = false;
  bool failGenerateQr = false;
  bool failConfirm = false;
  CompletionQrPayload? confirmedPayload;

  RepairRequestModel _request() => RepairRequestModel(
        id: 'request-1',
        customerId: 'customer-1',
        serviceCategoryId: 'category-1',
        title: 'Sửa máy lạnh',
        description: 'Máy lạnh không mát',
        location: const RepairLocationModel(address: 'Hà Nội'),
        contactPhone: '0900000000',
        createdAt: DateTime(2026, 10, 1),
        updatedAt: DateTime(2026, 10, 1),
        status: 'IN_PROGRESS',
        completionImages: const ['https://example.com/image.jpg'],
      );

  @override
  Future<RepairRequestModel> uploadImages({
    required String token,
    required String requestId,
    required List<XFile> images,
  }) async {
    if (fail) throw Exception('Đơn không thuộc thợ này');
    return _request();
  }

  @override
  Future<CompletionQrModel> generateCompletionQr({
    required String token,
    required String requestId,
  }) async {
    if (failGenerateQr) throw Exception('Chưa có ảnh sau sửa');
    return CompletionQrModel(
      requestId: requestId,
      amount: 450000,
      payload:
          'homefix://completion?requestId=$requestId&amount=450000&token=qr-token',
      expiresAt: DateTime(2026, 10, 20, 15, 30),
    );
  }

  @override
  Future<void> confirmCompletion({
    required String token,
    required String requestId,
    required String qrToken,
    required int amount,
  }) async {
    if (failConfirm) throw Exception('QR nghiệm thu đã hết hạn');
    confirmedPayload = CompletionQrPayload(
      requestId: requestId,
      amount: amount,
      token: qrToken,
    );
  }
}

void main() {
  group('InvoiceModel', () {
    test('parse đúng hóa đơn, hóa đơn linh kiện và tiền mặt', () {
      final invoice = InvoiceModel.fromJson({
        'requestId': 'r1',
        'quotationId': 'q1',
        'serviceTitle': 'Sửa điện',
        'serviceCategoryName': 'Điện',
        'technicianName': 'Thợ B',
        'labourCost': 100000,
        'partsCost': 50000,
        'total': 150000,
        'requestStatus': 'IN_PROGRESS',
        'completionImages': ['image-1'],
        'partsInvoiceImages': ['invoice-parts-1.jpg'],
        'paymentMethod': 'CASH',
        'paymentStatus': 'PAID',
        'paidAt': '2026-10-28T10:00:00.000Z',
      });

      expect(invoice.total, 150000);
      expect(invoice.completionImages, ['image-1']);
      expect(invoice.partsInvoiceImages, ['invoice-parts-1.jpg']);
      expect(invoice.paymentMethodLabel, 'Tiền mặt tại chỗ');
      expect(invoice.isPaid, isTrue);
      expect(invoice.paidAt, isNotNull);
    });

    test('phương thức chưa chọn có nhãn mặc định', () {
      expect(_invoice().paymentMethodLabel, 'Chưa xác nhận');
      expect(_invoice().isPaid, isFalse);
    });
  });

  group('OrderHistoryModel', () {
    test('parse ảnh sau sửa, phương thức và trạng thái IN_PROGRESS', () {
      final order = OrderHistoryModel.fromJson({
        '_id': 'r1',
        'title': 'Sửa máy bơm',
        'description': 'Máy bơm không chạy',
        'status': 'IN_PROGRESS',
        'serviceCategoryId': {'name': 'Sửa nước', 'icon': 'water'},
        'assignedTechnicianId': {'_id': 't1', 'fullName': 'Thợ A'},
        'completionImages': ['image-1', 'image-2'],
        'paymentMethod': 'CASH',
        'location': {'address': 'Hà Nội'},
      });

      expect(order.statusDisplay, 'Đang sửa chữa');
      expect(order.assignedTechnicianId, 't1');
      expect(order.completionImages, hasLength(2));
      expect(order.paymentMethod, 'CASH');
    });
  });

  group('PaymentProvider', () {
    test('load hóa đơn thành công và lưu phương thức tiền mặt (UC-PAY-02)',
        () async {
      final dataSource = _FakePaymentDataSource();
      final provider = PaymentProvider(dataSource: dataSource);

      await provider.fetchInvoice(token: 'token', requestId: 'request-1');
      expect(provider.invoice?.total, 450000);
      expect(provider.errorMessage, isNull);

      final success = await provider.selectPaymentMethod(
        token: 'token',
        requestId: 'request-1',
        paymentMethod: 'CASH',
      );

      expect(success, isTrue);
      expect(provider.invoice?.paymentMethod, 'CASH');
      expect(provider.isSubmitting, isFalse);
    });

    test('request mới bị lỗi không giữ hóa đơn của request trước', () async {
      final dataSource = _FakePaymentDataSource();
      final provider = PaymentProvider(dataSource: dataSource);

      await provider.fetchInvoice(token: 'token', requestId: 'request-1');
      dataSource.failFetch = true;
      await provider.fetchInvoice(token: 'token', requestId: 'request-2');

      expect(provider.invoice, isNull);
      expect(provider.errorMessage, 'Không có quyền xem hóa đơn');
      expect(provider.isLoading, isFalse);
    });

    test('thợ tải ảnh hóa đơn linh kiện thành công (UC-PAY-03)', () async {
      final dataSource = _FakePaymentDataSource();
      final provider = PaymentProvider(dataSource: dataSource);

      final success = await provider.uploadPartsInvoices(
        token: 'token',
        requestId: 'request-1',
        images: [XFile('bill_linh_kien.jpg')],
      );

      expect(success, isTrue);
      expect(provider.invoice?.partsInvoiceImages, hasLength(1));
      expect(provider.errorMessage, isNull);
      expect(provider.isSubmitting, isFalse);
    });

    test('thợ xác nhận đã nhận tiền mặt thành công (UC-PAY-04)', () async {
      final dataSource = _FakePaymentDataSource();
      final provider = PaymentProvider(dataSource: dataSource);

      final success = await provider.confirmPaymentReceived(
        token: 'token',
        requestId: 'request-1',
      );

      expect(success, isTrue);
      expect(provider.invoice?.isPaid, isTrue);
      expect(provider.invoice?.paymentMethod, 'CASH');
      expect(provider.isSubmitting, isFalse);
    });

    test('lỗi khi chọn phương thức trả false', () async {
      final dataSource = _FakePaymentDataSource()..failSelect = true;
      final provider = PaymentProvider(dataSource: dataSource);

      final success = await provider.selectPaymentMethod(
        token: 'token',
        requestId: 'request-1',
        paymentMethod: 'CASH',
      );

      expect(success, isFalse);
      expect(provider.errorMessage, 'Không thể lưu phương thức');
      expect(provider.isSubmitting, isFalse);
    });
  });

  group('CompletionProvider', () {
    test('upload thành công trả về request đã cập nhật', () async {
      final provider = CompletionProvider(
        dataSource: _FakeCompletionDataSource(),
      );

      final success = await provider.uploadImages(
        token: 'token',
        requestId: 'request-1',
        images: [XFile('test.jpg')],
      );

      expect(success, isTrue);
      expect(provider.updatedRequest?.completionImages, hasLength(1));
      expect(provider.errorMessage, isNull);
      expect(provider.isUploading, isFalse);
    });

    test('lỗi upload được đưa ra cho UI', () async {
      final dataSource = _FakeCompletionDataSource()..fail = true;
      final provider = CompletionProvider(dataSource: dataSource);

      final success = await provider.uploadImages(
        token: 'token',
        requestId: 'request-1',
        images: [XFile('test.jpg')],
      );

      expect(success, isFalse);
      expect(provider.errorMessage, 'Đơn không thuộc thợ này');
      expect(provider.isUploading, isFalse);
    });

    test('tạo QR nghiệm thu thành công', () async {
      final provider = CompletionProvider(
        dataSource: _FakeCompletionDataSource(),
      );

      final success = await provider.generateCompletionQr(
        token: 'token',
        requestId: 'request-1',
      );

      expect(success, isTrue);
      expect(provider.confirmationQr?.amount, 450000);
      expect(provider.isGeneratingQr, isFalse);
      expect(provider.errorMessage, isNull);
    });

    test('quét QR và gọi xác nhận nghiệm thu thành công', () async {
      final dataSource = _FakeCompletionDataSource();
      final provider = CompletionProvider(dataSource: dataSource);
      final payload = CompletionQrPayload.tryParse(
        'homefix://completion?requestId=request-1&amount=450000&token=qr-token',
      );

      expect(payload, isNotNull);
      final success = await provider.confirmCompletion(
        token: 'token',
        payload: payload!,
      );

      expect(success, isTrue);
      expect(dataSource.confirmedPayload?.requestId, 'request-1');
      expect(dataSource.confirmedPayload?.amount, 450000);
      expect(provider.isConfirming, isFalse);
    });

    test('QR sai định dạng bị từ chối trước khi gọi API', () {
      expect(CompletionQrPayload.tryParse('https://example.com'), isNull);
      expect(
        CompletionQrPayload.tryParse(
          'homefix://completion?requestId=request-1&amount=sai&token=abc',
        ),
        isNull,
      );
    });

    test('lỗi xác nhận QR được đưa ra cho UI', () async {
      final dataSource = _FakeCompletionDataSource()..failConfirm = true;
      final provider = CompletionProvider(dataSource: dataSource);
      const payload = CompletionQrPayload(
        requestId: 'request-1',
        amount: 450000,
        token: 'expired-token',
      );

      final success = await provider.confirmCompletion(
        token: 'token',
        payload: payload,
      );

      expect(success, isFalse);
      expect(provider.errorMessage, 'QR nghiệm thu đã hết hạn');
      expect(provider.isConfirming, isFalse);
    });
  });
}
