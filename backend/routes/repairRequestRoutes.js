const express = require('express');
const router = express.Router();
const {
  createRepairRequest,
  getMyRepairRequests,
  uploadCompletionImages,
} = require('../controllers/repairRequestController');
const { protect, authorize } = require('../middlewares/auth');
const upload = require('../middlewares/upload');

// Yêu cầu đăng nhập cho tất cả các routes bên dưới
router.use(protect);

// Lịch sử đơn hàng của tôi (UC-HIS-01)
router.get('/my-requests', getMyRepairRequests);

// Thợ upload ảnh sau khi sửa xong (UC-CFM-01)
router.post(
  '/:id/completion-images',
  authorize('technician'),
  upload.array('images', 5),
  uploadCompletionImages
);

// Tạo yêu cầu sửa chữa mới
router.post('/', authorize('user'), createRepairRequest);

// Tạo đơn hàng hoàn tất mẫu để kiểm thử đánh giá

module.exports = router;
