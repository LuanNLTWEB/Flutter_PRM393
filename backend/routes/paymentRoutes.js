/**
 * Author: Lam Hoang Phuc (CE191132)
 * Use Cases: #UC-PAY-01, #UC-PAY-02, #UC-PAY-03, #UC-PAY-04, #UC-PAY-05
 * Description: Định tuyến API thanh toán tiền mặt, chứng từ linh kiện và biên nhận điện tử
 */
const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middlewares/auth');
const upload = require('../middlewares/upload');
const {
  getInvoice,
  selectPaymentMethod,
  uploadPartsInvoiceImages,
  confirmPaymentReceived,
  getReceipt,
} = require('../controllers/paymentController');

// Tất cả API thanh toán yêu cầu đăng nhập
router.use(protect);

// Xem hóa đơn chi tiết (UC-PAY-01): Khách hàng, Thợ, Staff/Admin
router.get(
  '/requests/:id/invoice',
  authorize('user', 'technician', 'staff', 'admin'),
  getInvoice
);

// Xuất biên nhận thanh toán kiêm phiếu bảo hành điện tử (UC-PAY-05): Khách hàng, Thợ, Staff/Admin
router.get(
  '/requests/:id/receipt',
  authorize('user', 'technician', 'staff', 'admin'),
  getReceipt
);

// Khách hàng xác nhận thanh toán tiền mặt tại chỗ (UC-PAY-02)
router.put('/requests/:id/method', authorize('user'), selectPaymentMethod);

// Thợ đính kèm ảnh chứng từ / hóa đơn mua linh kiện thay thế (UC-PAY-03)
router.post(
  '/requests/:id/parts-invoices',
  authorize('technician'),
  upload.array('images', 5),
  uploadPartsInvoiceImages
);

// Thợ xác nhận đã nhận đủ tiền mặt từ khách hàng (UC-PAY-04)
router.patch(
  '/requests/:id/confirm-payment',
  authorize('technician'),
  confirmPaymentReceived
);

module.exports = router;
