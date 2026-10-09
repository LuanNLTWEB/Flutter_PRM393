const express = require('express');
const router = express.Router();
const {
  getNearbyRequests,
  getRequestDetail,
} = require('../controllers/requestReadController');
const { protect, authorize } = require('../middlewares/auth');

// Đọc phiếu yêu cầu dành cho Thợ & Khách hàng
router.use(protect);

// Feed yêu cầu đang mở (UC-QUO-01 / UC-QUO-02)
router.get('/nearby', authorize('technician'), getNearbyRequests);

// Chi tiết phiếu yêu cầu (UC-QUO-03)
router.get('/:id', authorize('user', 'technician', 'staff', 'admin'), getRequestDetail);

module.exports = router;
