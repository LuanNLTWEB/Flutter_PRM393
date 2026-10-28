import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/invoice/data/models/invoice_model.dart';
import 'package:frontend/features/invoice/presentation/providers/invoice_provider.dart';

void main() {
  group('UC-OFF-01: Offline invoice tests', () {
    test(
      'InvoiceModel parses cost breakdown and serializes for local cache',
      () {
        final invoice = InvoiceModel.fromJson({
          'id': 'request_01',
          'invoiceNumber': 'HF-REQUEST1',
          'requestTitle': 'Máy lạnh không mát',
          'serviceCategoryName': 'Điện lạnh',
          'technicianName': 'Nguyễn Văn A',
          'technicianPhone': '0901000000',
          'address': 'Quận 1, TP.HCM',
          'costs': {'labourCost': 250000, 'partsCost': 150000, 'total': 400000},
          'quotationNote': 'Đã thay tụ lạnh',
          'completedAt': '2026-10-20T08:30:00.000Z',
        });

        expect(invoice.id, 'request_01');
        expect(invoice.labourCost, 250000);
        expect(invoice.partsCost, 150000);
        expect(invoice.total, 400000);
        expect(invoice.quotationNote, 'Đã thay tụ lạnh');
        expect(invoice.completedAt, isNotNull);

        final cached = invoice.toJson();
        expect(cached['invoiceNumber'], 'HF-REQUEST1');
        expect((cached['costs'] as Map)['total'], 400000);
      },
    );

    test('InvoiceProvider starts with an empty online state', () {
      final provider = InvoiceProvider();

      expect(provider.invoices, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.isShowingOfflineData, isFalse);
      expect(provider.cachedAt, isNull);
      expect(provider.errorMessage, isNull);
    });
  });
}
