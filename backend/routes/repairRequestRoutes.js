const express = require('express');
const router = express.Router();
const { createRepairRequest } = require('../controllers/repairRequestController');
const { protect, authorize } = require('../middlewares/auth');

// Yêu cầu đăng nhập
router.use(protect);

// Tạo yêu cầu mới
router.post('/', authorize('user'), createRepairRequest);

module.exports = router;
