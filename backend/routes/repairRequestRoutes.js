const express = require('express');
const router = express.Router();
const {
  createRepairRequest,
  getMyRepairRequests,
} = require('../controllers/repairRequestController');
const { protect, authorize } = require('../middlewares/auth');

// Yêu cầu đăng nhập cho tất cả các routes bên dưới
router.use(protect);

// Lịch sử đơn hàng của tôi (UC-HIS-01)
router.get('/my-requests', getMyRepairRequests);

// Tạo yêu cầu sửa chữa mới
router.post('/', authorize('user'), createRepairRequest);

// Tạo đơn hàng hoàn tất mẫu để kiểm thử đánh giá

module.exports = router;
