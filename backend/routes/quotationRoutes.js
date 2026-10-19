const express = require('express');
const router = express.Router();
const {
  sendQuotation,
  getQuotationsByRequest,
  getMyQuotations,
  updateQuotation,
  retractQuotation,
  acceptQuotation,
  rejectQuotation,
} = require('../controllers/quotationController');
const { protect, authorize } = require('../middlewares/auth');

// Toàn bộ API báo giá đều yêu cầu đăng nhập
router.use(protect);

// ============================================================================
// UC-QUO-04: Gửi báo giá (Quotation)
//   START UC-QUO-04 — Thợ gửi báo giá cho 1 phiếu yêu cầu
// ============================================================================
router.post('/', authorize('technician'), sendQuotation);
//   END UC-QUO-04

// ============================================================================
// UC-QUO-05: Cập nhật / Hủy báo giá
//   START UC-QUO-05.a — Thợ chỉnh sửa báo giá đã gửi
// ============================================================================
router.put('/:id', authorize('technician'), updateQuotation);
//   END UC-QUO-05.a

// ============================================================================
// UC-QUO-05: Cập nhật / Hủy báo giá
//   START UC-QUO-05.b — Thợ thu hồi (hủy) báo giá đã gửi
// ============================================================================
router.patch('/:id/retract', authorize('technician'), retractQuotation);
//   END UC-QUO-05.b

// ============================================================================
// UC-QUO-05: Cập nhật / Hủy báo giá
//   START UC-QUO-05.c — Thợ xem lại các báo giá mình đã gửi
// ============================================================================
router.get('/my-quotes', authorize('technician'), getMyQuotations);
//   END UC-QUO-05.c

// ============================================================================
// UC-QUO-06: Xem danh sách báo giá nhận được
//   START UC-QUO-06 — Khách hàng xem các thợ đã báo giá cho yêu cầu của mình
// ============================================================================
router.get('/', authorize('user', 'technician'), getQuotationsByRequest);
//   END UC-QUO-06

// ============================================================================
// UC-QUO-08: Chấp nhận báo giá (Accept)
//   START UC-QUO-08 — Khách chốt 1 thợ, tự động từ chối các báo giá còn lại
// ============================================================================
router.post('/:id/accept', authorize('user'), acceptQuotation);
//   END UC-QUO-08

// ============================================================================
// UC-QUO-09: Từ chối báo giá
//   START UC-QUO-09 — Khách từ chối báo giá của 1 thợ
// ============================================================================
router.post('/:id/reject', authorize('user'), rejectQuotation);
//   END UC-QUO-09

module.exports = router;
