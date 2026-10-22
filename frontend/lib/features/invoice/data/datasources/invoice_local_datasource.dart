import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/invoice_model.dart';

class CachedInvoices {
  final List<InvoiceModel> invoices;
  final DateTime cachedAt;

  const CachedInvoices({required this.invoices, required this.cachedAt});
}

/// Lưu bản chụp JSON để không cần Hive adapter/code generation cho dữ liệu hóa đơn.
class InvoiceLocalDataSource {
  static const _boxName = 'homefix_offline_invoices';
  static Future<void>? _initialization;

  Future<Box<String>> _openBox() async {
    _initialization ??= Hive.initFlutter();
    await _initialization;

    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<String>(_boxName);
    }
    return Hive.openBox<String>(_boxName);
  }

  String _cacheKey(String userId) => 'invoices_$userId';

  Future<void> cacheInvoices({
    required String userId,
    required List<InvoiceModel> invoices,
  }) async {
    final box = await _openBox();
    await box.put(
      _cacheKey(userId),
      jsonEncode({
        'cachedAt': DateTime.now().toUtc().toIso8601String(),
        'invoices': invoices.map((invoice) => invoice.toJson()).toList(),
      }),
    );
  }

  Future<CachedInvoices?> getCachedInvoices(String userId) async {
    final box = await _openBox();
    final raw = box.get(_cacheKey(userId));
    if (raw == null || raw.isEmpty) return null;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final rawInvoices = data['invoices'] as List? ?? [];
      final cachedAt =
          DateTime.tryParse((data['cachedAt'] ?? '').toString())?.toLocal() ??
          DateTime.now();
      return CachedInvoices(
        invoices: rawInvoices
            .map(
              (item) =>
                  InvoiceModel.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList(),
        cachedAt: cachedAt,
      );
    } catch (_) {
      await box.delete(_cacheKey(userId));
      return null;
    }
  }
}
