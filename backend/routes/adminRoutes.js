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
  getStuckRequests,
  staffCancelRequest,
  staffReassignRequest,
  getOperationalReport,
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

// 3. Giám sát đơn hàng bị treo & Can thiệp điều phối/hủy đơn (UC-STF-04 - Admin & Staff)
router.get('/requests/stuck', authorize('admin', 'staff'), getStuckRequests);
router.put('/requests/:id/cancel', authorize('admin', 'staff'), staffCancelRequest);
router.put('/requests/:id/reassign', authorize('admin', 'staff'), staffReassignRequest);

// 4. Thống kê báo cáo vận hành (UC-STF-05 - Admin & Staff)
router.get('/reports/operations', authorize('admin', 'staff'), getOperationalReport);

// 4. Phân quyền và Tạo nhân viên (Chỉ Admin)
router.post('/users/staff', authorize('admin'), createStaff);
router.put('/users/:id/role', authorize('admin'), updateUserRole);

module.exports = router;

