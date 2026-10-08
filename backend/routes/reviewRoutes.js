const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middlewares/auth');
const {
  getReviewTags,
  getTechnicians,
  createReview,
  getTechnicianReviews,
  getMyReviews,
  replyReview,
} = require('../controllers/reviewController');

// Lấy danh sách tag đánh giá gợi ý (Public)
router.get('/tags', getReviewTags);

// Lấy danh sách thợ kỹ thuật (Public)
router.get('/technicians', getTechnicians);

// Xem danh sách đánh giá của 1 thợ kỹ thuật (Public)
router.get('/technician/:technicianId', getTechnicianReviews);

// Tạo mới đánh giá (Chỉ khách hàng đã đăng nhập)
router.post('/', protect, createReview);

// Xem danh sách đánh giá cá nhân đã gửi (Private)
router.get('/my-reviews', protect, getMyReviews);

// Thợ phản hồi lại đánh giá (Private - Chỉ thợ hoặc admin)
router.put('/:id/reply', protect, authorize('technician', 'admin'), replyReview);

module.exports = router;
