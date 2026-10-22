const express = require('express');
const router = express.Router();
const {
  createRepairRequest,
  getMyRepairRequests,
  cancelRepairRequest,
  confirmAppointment,
  proposeAppointment,
  respondAppointment,
  updateOnTheWay,
  updateArrived,
  updateWorking,
  declareAdditionalCost,
  respondAdditionalCost,
} = require('../controllers/repairRequestController');
const { protect, authorize } = require('../middlewares/auth');
const upload = require('../middlewares/upload');

// Yêu cầu đăng nhập cho tất cả các routes bên dưới
router.use(protect);

// Lấy danh sách yêu cầu của tôi (UC-REQ-07, UC-HIS-01)
router.get('/my-requests', getMyRepairRequests);

// Tạo yêu cầu sửa chữa mới kèm ảnh hiện trường (UC-REQ-03, 04, 05)
router.post('/', authorize('user'), upload.array('images', 5), createRepairRequest);

// Hủy phiếu yêu cầu trước khi chốt thợ (UC-REQ-09)
router.patch('/:id/cancel', authorize('user'), cancelRepairRequest);


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

// Thợ bấm "Đã có mặt tại hiện trường" (UC-ARR-01)
router.patch(
  '/:id/arrived',
  authorize('technician'),
  updateArrived
);

// Thợ bấm "Bắt đầu sửa chữa" (UC-WRK-02)
router.patch(
  '/:id/working',
  authorize('technician'),
  updateWorking
);

// Thợ khai báo chi phí phát sinh (UC-WRK-05)
router.post(
  '/:id/costs',
  authorize('technician'),
  declareAdditionalCost
);

// Khách đồng ý / từ chối chi phí phát sinh (UC-WRK-06)
router.patch(
  '/:id/costs/:costId',
  authorize('user'),
  respondAdditionalCost
);

// Tạo đơn hàng hoàn tất mẫu để kiểm thử đánh giá

module.exports = router;
