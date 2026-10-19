const express = require('express');
const router = express.Router();
const {
  getNearbyRequests,
  getRequestDetail,
} = require('../controllers/requestReadController');
const { protect, authorize } = require('../middlewares/auth');

// Đọc phiếu yêu cầu dành cho Thợ & Khách hàng
router.use(protect);

// START UC-QUO-01 + UC-QUO-02: Xem & lọc sự cố quanh đây
router.get('/nearby', authorize('technician'), getNearbyRequests);
// END UC-QUO-01 + UC-QUO-02

// START UC-QUO-03: Xem chi tiết sự cố
router.get('/:id', authorize('user', 'technician', 'staff', 'admin'), getRequestDetail);
// END UC-QUO-03

module.exports = router;