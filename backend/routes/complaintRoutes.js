const express = require('express');
const router = express.Router();
const {
  createComplaint,
  getComplaintsForManage,
  handleComplaint,
} = require('../controllers/complaintController');
const { protect, authorize } = require('../middlewares/auth');

router.use(protect);

// Staff nhận và lập biên bản xử lý tranh chấp (UC-STF-03).
router.get('/manage', authorize('staff', 'admin'), getComplaintsForManage);
router.patch('/:id/handle', authorize('staff', 'admin'), handleComplaint);

// Một bên của đơn có thể gửi báo cáo để Staff có hồ sơ tiếp nhận.
router.post('/', authorize('user', 'technician'), createComplaint);

module.exports = router;
