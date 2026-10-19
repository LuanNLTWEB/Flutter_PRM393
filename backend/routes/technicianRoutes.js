const express = require('express');
const router = express.Router();
const {
  getPublicTechnicians,
  getPublicTechnicianById,
  toggleAvailability,
  updateTechnicianSkills,
} = require('../controllers/technicianController');
const { protect } = require('../middlewares/auth');
const upload = require('../middlewares/upload');

// Public routes cho Khách hàng tìm kiếm và xem hồ sơ công khai của Thợ
router.get('/', getPublicTechnicians);
router.get('/:id', getPublicTechnicianById);

// Private routes cho Thợ
router.put('/status/availability', protect, toggleAvailability);
router.put(
  '/skills',
  protect,
  upload.array('certificates', 10),
  updateTechnicianSkills
);

module.exports = router;
