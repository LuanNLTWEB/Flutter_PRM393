const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middlewares/auth');
const upload = require('../middlewares/upload');
const {
  getInvoice,
  selectPaymentMethod,
  uploadPartsInvoiceImages,
  confirmPaymentReceived,
} = require('../controllers/paymentController');

// Tất cả API thanh toán yêu cầu đăng nhập
router.use(protect);

// Xem hóa đơn chi tiết (UC-PAY-01): Khách hàng, Thợ, Staff/Admin
router.get(
  '/requests/:id/invoice',
  authorize('user', 'technician', 'staff', 'admin'),
  getInvoice
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
