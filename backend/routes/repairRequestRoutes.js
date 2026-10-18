const express = require('express');
const router = express.Router();
const {
  createRepairRequest,
  getMyRepairRequests,
  confirmAppointment,
  proposeAppointment,
  respondAppointment,
  updateOnTheWay,
} = require('../controllers/repairRequestController');
const { protect, authorize } = require('../middlewares/auth');
const upload = require('../middlewares/upload');

// Yêu cầu đăng nhập cho tất cả các routes bên dưới
router.use(protect);

// Lịch sử đơn hàng của tôi (UC-HIS-01)
router.get('/my-requests', getMyRepairRequests);

// Tạo yêu cầu sửa chữa mới kèm ảnh hiện trường
router.post('/', authorize('user'), upload.array('images', 5), createRepairRequest);

// Thợ xác nhận / đổi lịch hẹn (UC-LIC-01)
router.patch(
  '/:id/appointment/confirm',
  authorize('technician'),
  confirmAppointment
);
router.patch(
  '/:id/appointment/propose',
  authorize('technician'),
  proposeAppointment
);

// Khách đồng ý / từ chối khung giờ thợ đề xuất (UC-LIC-01)
router.patch(
  '/:id/appointment/respond',
  authorize('user'),
  respondAppointment
);

// Thợ bấm "Đang trên đường đến nhà khách" (UC-DI-01)
router.patch(
  '/:id/on-the-way',
  authorize('technician'),
  updateOnTheWay
);

// Tạo đơn hàng hoàn tất mẫu để kiểm thử đánh giá

module.exports = router;
