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

// START UC-QUO-04: Gửi báo giá
router.post('/', authorize('technician'), sendQuotation);
// END UC-QUO-04

// START UC-QUO-05.a: Cập nhật báo giá
router.put('/:id', authorize('technician'), updateQuotation);
// END UC-QUO-05.a

// START UC-QUO-05.b: Hủy (thu hồi) báo giá
router.patch('/:id/retract', authorize('technician'), retractQuotation);
// END UC-QUO-05.b

// START UC-QUO-05.c: Xem các báo giá Thợ đã gửi
router.get('/my-quotes', authorize('technician'), getMyQuotations);
// END UC-QUO-05.c

// START UC-QUO-06: Xem danh sách báo giá nhận được
router.get('/', authorize('user', 'technician'), getQuotationsByRequest);
// END UC-QUO-06

// START UC-QUO-08: Chấp nhận báo giá
router.post('/:id/accept', authorize('user'), acceptQuotation);
// END UC-QUO-08

// START UC-QUO-09: Từ chối báo giá
router.post('/:id/reject', authorize('user'), rejectQuotation);
// END UC-QUO-09

module.exports = router;