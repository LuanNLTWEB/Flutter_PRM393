const express = require('express');
const router = express.Router();
const {
  getNearbyRequests,
  getRequestDetail,
} = require('../controllers/requestReadController');
const { protect, authorize } = require('../middlewares/auth');

// Đọc phiếu yêu cầu dành cho Thợ & Khách hàng
router.use(protect);

// ============================================================================
// UC-QUO-01: Xem tin sự cố quanh đây
//   START UC-QUO-01 — Feed yêu cầu sửa chữa còn nhận báo giá cho Thợ
//                   (mặc định lấy cả OPEN + QUOTED, xem controller để rõ cú pháp)
// ============================================================================
router.get('/nearby', authorize('technician'), getNearbyRequests);
//   END UC-QUO-01

// ============================================================================
// UC-QUO-02: Lọc sự cố theo chuyên môn
//   START UC-QUO-02 — Cùng endpoint /nearby, thêm tham số categorySlug / urgency
// ============================================================================
//   END UC-QUO-02 (tham số lọc, không phải route riêng)

// ============================================================================
// UC-QUO-03: Xem chi tiết sự cố
//   START UC-QUO-03 — Chi tiết 1 phiếu yêu cầu (Thợ bị che SĐT & địa chỉ)
// ============================================================================
router.get('/:id', authorize('user', 'technician', 'staff', 'admin'), getRequestDetail);
//   END UC-QUO-03

module.exports = router;
