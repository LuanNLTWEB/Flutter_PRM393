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

// Thợ gửi / chỉnh sửa / thu hồi báo giá + danh sách đã báo giá
router.post('/', authorize('technician'), sendQuotation);
router.get('/my-quotes', authorize('technician'), getMyQuotations);
router.put('/:id', authorize('technician'), updateQuotation);
router.patch('/:id/retract', authorize('technician'), retractQuotation);

// Khách hàng xem / chốt / từ chối báo giá
router.get('/', authorize('user', 'technician'), getQuotationsByRequest);
router.post('/:id/accept', authorize('user'), acceptQuotation);
router.post('/:id/reject', authorize('user'), rejectQuotation);

module.exports = router;
