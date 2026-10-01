const express = require('express');
const router = express.Router();
const {
  getUsers,
  createStaff,
  updateUserRole,
  toggleUserStatus,
} = require('../controllers/adminController');
const { protect, authorize } = require('../middlewares/auth');

// Toàn bộ API của admin bắt buộc phải đăng nhập và có role là 'admin'
router.use(protect, authorize('admin'));

// Quản lý danh sách tài khoản
router.get('/users', getUsers);

// Tạo tài khoản Staff
router.post('/users/staff', createStaff);

// Quản lý Role & Quyền hạn
router.put('/users/:id/role', updateUserRole);

// Khóa / Mở khóa tài khoản
router.put('/users/:id/status', toggleUserStatus);

module.exports = router;
