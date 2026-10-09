const express = require('express');
const router = express.Router();
const {
  getUsers,
  createStaff,
  updateUserRole,
  toggleUserStatus,
  getTechniciansForKYC,
  approveTechnician,
  rejectTechnician,
} = require('../controllers/adminController');
const { protect, authorize } = require('../middlewares/auth');

// Toàn bộ API quản trị bắt buộc phải đăng nhập
router.use(protect);

// 1. Quản lý danh sách tài khoản & Khóa/Mở (Admin & Staff)
router.get('/users', authorize('admin', 'staff'), getUsers);
router.put('/users/:id/status', authorize('admin', 'staff'), toggleUserStatus);

// 2. Xét duyệt hồ sơ Thợ (KYC Approval Flow - Admin & Staff)
router.get('/technicians/kyc', authorize('admin', 'staff'), getTechniciansForKYC);
router.put('/technicians/:id/approve', authorize('admin', 'staff'), approveTechnician);
router.put('/technicians/:id/reject', authorize('admin', 'staff'), rejectTechnician);

// 3. Phân quyền và Tạo nhân viên (Chỉ Admin)
router.post('/users/staff', authorize('admin'), createStaff);
router.put('/users/:id/role', authorize('admin'), updateUserRole);

module.exports = router;

