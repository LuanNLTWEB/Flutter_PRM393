const express = require('express');
const router = express.Router();
const {
  getProfile,
  updateProfile,
  changePassword,
} = require('../controllers/userController');
const { protect } = require('../middlewares/auth');

// Tất cả các routes bên dưới đều yêu cầu đăng nhập (JWT Auth)
router.get('/profile', protect, getProfile);
router.put('/profile', protect, updateProfile);
router.put('/change-password', protect, changePassword);

module.exports = router;
