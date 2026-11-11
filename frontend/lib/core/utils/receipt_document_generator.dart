import 'package:intl/intl.dart';

import '../../features/payment/data/models/electronic_receipt_model.dart';
import '../../features/payment/data/models/invoice_model.dart' as pay_models;
import '../../features/invoice/data/models/invoice_model.dart' as inv_models;

/// Bộ tiện ích sinh mã HTML định dạng hóa đơn & biên nhận điện tử kiêm bảo hành
class ReceiptDocumentGenerator {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  /// Tạo tài liệu HTML hoàn chỉnh cho Biên nhận & Bảo hành điện tử (UC-PAY-05)
  static String generateReceiptHtml(ElectronicReceiptModel receipt) {
    final issuedDateStr = _dateFormat.format(receipt.issuedAt);
    final paidDateStr = receipt.financial.paidAt != null
        ? _dateFormat.format(receipt.financial.paidAt!)
        : issuedDateStr;
    final warrantyUntilStr = DateFormat('dd/MM/yyyy').format(receipt.warranty.endDate);
    final termsHtml = receipt.warranty.terms
        .map((t) => '<p style="margin-bottom: 4px;">• $t</p>')
        .join('\n');

    return '''<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Biên nhận & Bảo hành điện tử - ${receipt.receiptCode}</title>
  <style>
    :root {
      --primary: #0F766E;
      --primary-light: #F0FDFA;
      --text: #1F2937;
      --text-muted: #6B7280;
      --border: #E5E7EB;
      --success: #059669;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      background-color: #F3F4F6;
      color: var(--text);
      line-height: 1.5;
      padding: 24px;
    }
    .container {
      max-width: 750px;
      margin: 0 auto;
      background: #FFFFFF;
      border-radius: 16px;
      box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.08);
      overflow: hidden;
      border: 1px solid var(--border);
    }
    .header {
      background: linear-gradient(135deg, #0F766E 0%, #115E59 100%);
      color: white;
      padding: 32px;
      position: relative;
    }
    .header-top {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      margin-bottom: 20px;
    }
    .logo {
      font-size: 26px;
      font-weight: 800;
      letter-spacing: -0.5px;
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .badge-paid {
      background: #10B981;
      color: white;
      font-size: 12px;
      font-weight: 700;
      padding: 6px 14px;
      border-radius: 9999px;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    .title {
      font-size: 22px;
      font-weight: 700;
      margin-bottom: 6px;
    }
    .subtitle {
      font-size: 13px;
      opacity: 0.9;
    }
    .code-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 16px;
      margin-top: 24px;
      background: rgba(255, 255, 255, 0.12);
      padding: 16px;
      border-radius: 12px;
      backdrop-filter: blur(4px);
    }
    .code-label { font-size: 11px; text-transform: uppercase; opacity: 0.8; font-weight: 600; }
    .code-val { font-size: 16px; font-weight: 700; letter-spacing: 0.5px; font-family: monospace; }
    
    .body { padding: 32px; }
    .section-title {
      font-size: 14px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.8px;
      color: var(--primary);
      margin-bottom: 12px;
      border-bottom: 2px solid var(--primary-light);
      padding-bottom: 6px;
    }
    .info-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 20px;
      margin-bottom: 28px;
    }
    .info-card {
      background: #F9FAFB;
      border: 1px solid var(--border);
      border-radius: 12px;
      padding: 16px;
    }
    .info-row {
      display: flex;
      justify-content: space-between;
      margin-bottom: 8px;
      font-size: 13px;
    }
    .info-row:last-child { margin-bottom: 0; }
    .info-k { color: var(--text-muted); }
    .info-v { font-weight: 600; text-align: right; }

    .cost-table {
      width: 100%;
      border-collapse: collapse;
      margin-bottom: 28px;
    }
    .cost-table th {
      text-align: left;
      font-size: 12px;
      text-transform: uppercase;
      color: var(--text-muted);
      padding: 10px 14px;
      background: #F9FAFB;
      border-bottom: 1px solid var(--border);
    }
    .cost-table td {
      padding: 12px 14px;
      border-bottom: 1px solid var(--border);
      font-size: 14px;
    }
    .cost-table .num { text-align: right; font-weight: 600; }
    .total-row td {
      font-size: 16px;
      font-weight: 800;
      color: var(--primary);
      background: var(--primary-light);
      border-bottom: none;
    }

    .warranty-box {
      background: #F0FDF4;
      border: 1.5px dashed #86EFAC;
      border-radius: 12px;
      padding: 18px;
      margin-bottom: 28px;
    }
    .warranty-header {
      display: flex;
      align-items: center;
      gap: 10px;
      font-weight: 700;
      color: #166534;
      margin-bottom: 8px;
      font-size: 15px;
    }
    .warranty-policy {
      font-size: 13px;
      color: #15803D;
      line-height: 1.6;
    }

    .footer {
      border-top: 1px solid var(--border);
      padding: 24px 32px;
      background: #F9FAFB;
      display: flex;
      justify-content: space-between;
      align-items: center;
      font-size: 12px;
      color: var(--text-muted);
    }
    .actions-bar {
      display: flex;
      justify-content: center;
      gap: 12px;
      margin-bottom: 20px;
    }
    .btn {
      background: var(--primary);
      color: white;
      border: none;
      padding: 10px 20px;
      border-radius: 8px;
      font-weight: 600;
      font-size: 14px;
      cursor: pointer;
      display: inline-flex;
      align-items: center;
      gap: 8px;
      text-decoration: none;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    .btn:hover { background: #115E59; }

    @media print {
      body { background: white; padding: 0; }
      .container { box-shadow: none; border: none; max-width: 100%; }
      .actions-bar { display: none !important; }
      .header { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
    }
  </style>
</head>
<body>
  <div class="actions-bar">
    <button onclick="window.print()" class="btn">🖨️ In chứng từ / Lưu dưới dạng PDF</button>
  </div>

  <div class="container">
    <div class="header">
      <div class="header-top">
        <div class="logo">⚡ HomeFix Service</div>
        <div class="badge-paid">✓ ĐÃ THANH TOÁN</div>
      </div>
      <div class="title">BIÊN NHẬN ĐIỆN TỬ & BẢO HÀNH DỊCH VỤ</div>
      <div class="subtitle">${receipt.serviceTitle} (${receipt.serviceCategoryName})</div>

      <div class="code-grid">
        <div>
          <div class="code-label">Số biên nhận</div>
          <div class="code-val">${receipt.receiptCode}</div>
        </div>
        <div>
          <div class="code-label">Mã tra cứu bảo hành</div>
          <div class="code-val">${receipt.warrantyCode}</div>
        </div>
      </div>
    </div>

    <div class="body">
      <div class="info-grid">
        <div class="info-card">
          <div class="section-title">Khách hàng</div>
          <div class="info-row"><span class="info-k">Họ và tên:</span><span class="info-v">${receipt.customer.fullName}</span></div>
          <div class="info-row"><span class="info-k">Số điện thoại:</span><span class="info-v">${receipt.customer.phoneNumber}</span></div>
          <div class="info-row"><span class="info-k">Địa chỉ thực hiện:</span><span class="info-v">${receipt.customer.address}</span></div>
        </div>
        <div class="info-card">
          <div class="section-title">Thợ phụ trách & Nghiệm thu</div>
          <div class="info-row"><span class="info-k">Thợ kỹ thuật:</span><span class="info-v">${receipt.technician.fullName}</span></div>
          <div class="info-row"><span class="info-k">Số điện thoại thợ:</span><span class="info-v">${receipt.technician.phoneNumber}</span></div>
          <div class="info-row"><span class="info-k">Thời điểm thanh toán:</span><span class="info-v">$paidDateStr</span></div>
        </div>
      </div>

      <div class="section-title">Chi tiết quyết toán tài chính</div>
      <table class="cost-table">
        <thead>
          <tr>
            <th>Hạng mục</th>
            <th>Ghi chú</th>
            <th class="num">Thành tiền</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>Tiền công sửa chữa (Labour Cost)</td>
            <td>Chi phí nhân công kỹ thuật viên tại chỗ</td>
            <td class="num">${_currencyFormat.format(receipt.financial.labourCost)}</td>
          </tr>
          <tr>
            <td>Vật tư & Linh kiện (Parts Cost)</td>
            <td>Linh kiện thay thế có hóa đơn chứng từ</td>
            <td class="num">${_currencyFormat.format(receipt.financial.partsCost)}</td>
          </tr>
          <tr class="total-row">
            <td colspan="2">TỔNG CỘNG THANH TOÁN (TIỀN MẶT - CASH)</td>
            <td class="num">${_currencyFormat.format(receipt.financial.totalAmount)}</td>
          </tr>
        </tbody>
      </table>

      <div class="warranty-box">
        <div class="warranty-header">
          <span>🛡️ CHÍNH SÁCH BẢO HÀNH CHÍNH HÃNG HOMEFIX (${receipt.warranty.durationDays} NGÀY)</span>
        </div>
        <div class="warranty-policy">
          <p>• <strong>Hiệu lực bảo hành:</strong> Từ ngày hoàn tất đến hết ngày <strong>$warrantyUntilStr</strong>.</p>
          <div style="margin-top: 6px;">$termsHtml</div>
        </div>
      </div>
    </div>

    <div class="footer">
      <div>Hệ thống kết nối và quản lý dịch vụ sửa chữa gia dụng HomeFix</div>
      <div>Ngày phát hành: $issuedDateStr</div>
    </div>
  </div>
</body>
</html>''';
  }

  /// Tạo tài liệu HTML cho Hóa đơn / Bảng kê chi phí (UC-PAY-01/02)
  static String generatePaymentInvoiceHtml(pay_models.InvoiceModel invoice) {
    final paidDateStr = invoice.paidAt != null
        ? _dateFormat.format(invoice.paidAt!)
        : 'Chưa thanh toán';

    return '''<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <title>Bảng kê chi phí - ${invoice.requestId}</title>
  <style>
    body { font-family: -apple-system, sans-serif; background: #f4f6f8; padding: 24px; color: #1F2937; }
    .card { max-width: 650px; margin: 0 auto; background: white; padding: 32px; border-radius: 12px; border: 1px solid #E5E7EB; }
    .header { text-align: center; border-bottom: 2px solid #0F766E; padding-bottom: 16px; margin-bottom: 20px; }
    .header h2 { color: #0F766E; margin-bottom: 4px; }
    .row { display: flex; justify-content: space-between; margin-bottom: 8px; font-size: 14px; }
    .row.bold { font-weight: bold; }
    .row.total { font-size: 18px; color: #0F766E; font-weight: 800; border-top: 1px dashed #ccc; padding-top: 10px; margin-top: 12px; }
    .btn { background: #0F766E; color: white; border: none; padding: 8px 16px; border-radius: 6px; cursor: pointer; font-weight: 600; margin-bottom: 16px; }
    @media print { .no-print { display: none; } body { background: white; padding: 0; } }
  </style>
</head>
<body>
  <div style="text-align: center;" class="no-print">
    <button onclick="window.print()" class="btn">🖨️ In hóa đơn / Lưu PDF</button>
  </div>
  <div class="card">
    <div class="header">
      <h2>BẢNG KÊ CHI PHÍ DỊCH VỤ HOMEFIX</h2>
      <div>Mã yêu cầu: ${invoice.requestId}</div>
    </div>
    <div class="row"><span style="color: #6B7280;">Dịch vụ:</span><span>${invoice.serviceTitle}</span></div>
    <div class="row"><span style="color: #6B7280;">Danh mục:</span><span>${invoice.serviceCategoryName}</span></div>
    <div class="row"><span style="color: #6B7280;">Thợ kỹ thuật:</span><span>${invoice.technicianName}</span></div>
    <div class="row"><span style="color: #6B7280;">Trạng thái thanh toán:</span><span>${invoice.paymentStatus == 'PAID' ? 'ĐÃ THANH TOÁN (TIỀN MẶT)' : 'CHƯA THANH TOÁN'}</span></div>
    <div class="row"><span style="color: #6B7280;">Thời gian:</span><span>$paidDateStr</span></div>
    <hr style="margin: 16px 0; border: none; border-top: 1px solid #E5E7EB;" />
    <div class="row"><span>Tiền công:</span><span>${_currencyFormat.format(invoice.labourCost)}</span></div>
    <div class="row"><span>Vật tư linh kiện:</span><span>${_currencyFormat.format(invoice.partsCost)}</span></div>
    <div class="row total"><span>TỔNG CỘNG:</span><span>${_currencyFormat.format(invoice.total)}</span></div>
  </div>
</body>
</html>''';
  }

  /// Tạo tài liệu HTML cho Hóa đơn lưu trữ ngoại tuyến (UC-INV-01/02)
  static String generateOfflineInvoiceHtml(inv_models.InvoiceModel invoice) {
    final date = invoice.completedAt ?? invoice.issuedAt;
    final dateStr = date != null ? _dateFormat.format(date) : 'Chưa cập nhật';

    return '''<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <title>Hóa đơn dịch vụ - ${invoice.invoiceNumber}</title>
  <style>
    body { font-family: -apple-system, sans-serif; background: #f4f6f8; padding: 24px; color: #1F2937; }
    .card { max-width: 650px; margin: 0 auto; background: white; padding: 32px; border-radius: 12px; border: 1px solid #E5E7EB; }
    .header { text-align: center; border-bottom: 2px solid #0F766E; padding-bottom: 16px; margin-bottom: 20px; }
    .header h2 { color: #0F766E; margin-bottom: 4px; }
    .row { display: flex; justify-content: space-between; margin-bottom: 8px; font-size: 14px; }
    .row.bold { font-weight: bold; }
    .row.total { font-size: 18px; color: #0F766E; font-weight: 800; border-top: 1px dashed #ccc; padding-top: 10px; margin-top: 12px; }
    .btn { background: #0F766E; color: white; border: none; padding: 8px 16px; border-radius: 6px; cursor: pointer; font-weight: 600; margin-bottom: 16px; }
    @media print { .no-print { display: none; } body { background: white; padding: 0; } }
  </style>
</head>
<body>
  <div style="text-align: center;" class="no-print">
    <button onclick="window.print()" class="btn">🖨️ In hóa đơn / Lưu PDF</button>
  </div>
  <div class="card">
    <div class="header">
      <h2>HÓA ĐƠN DỊCH VỤ HOMEFIX</h2>
      <div>Số hóa đơn: ${invoice.invoiceNumber}</div>
    </div>
    <div class="row"><span style="color: #6B7280;">Dịch vụ:</span><span>${invoice.serviceCategoryName}</span></div>
    <div class="row"><span style="color: #6B7280;">Yêu cầu:</span><span>${invoice.requestTitle}</span></div>
    <div class="row"><span style="color: #6B7280;">Thợ phụ trách:</span><span>${invoice.technicianName}</span></div>
    <div class="row"><span style="color: #6B7280;">Địa chỉ:</span><span>${invoice.address}</span></div>
    <div class="row"><span style="color: #6B7280;">Thời gian hoàn tất:</span><span>$dateStr</span></div>
    <hr style="margin: 16px 0; border: none; border-top: 1px solid #E5E7EB;" />
    <div class="row"><span>Tiền công:</span><span>${_currencyFormat.format(invoice.labourCost)}</span></div>
    <div class="row"><span>Linh kiện:</span><span>${_currencyFormat.format(invoice.partsCost)}</span></div>
    ${invoice.additionalCostTotal > 0 ? '<div class="row"><span>Chi phí phát sinh:</span><span>${_currencyFormat.format(invoice.additionalCostTotal)}</span></div>' : ''}
    <div class="row total"><span>TỔNG THANH TOÁN:</span><span>${_currencyFormat.format(invoice.total)}</span></div>
  </div>
</body>
</html>''';
  }
}
