const express = require('express');
const router = express.Router();
const {
  getPublicTechnicians,
  getPublicTechnicianById,
  toggleAvailability,
} = require('../controllers/technicianController');
const { protect } = require('../middlewares/auth');

// Public routes cho Khách hàng tìm kiếm và xem hồ sơ công khai của Thợ
router.get('/', getPublicTechnicians);
router.get('/:id', getPublicTechnicianById);

// Private route cho Thợ bật/tắt trạng thái nhận việc
router.put('/status/availability', protect, toggleAvailability);

module.exports = router;
