const express = require('express');
const router = express.Router();
const {
  getCategories,
  getCategoryByIdentifier,
  searchCategories,
  getAllCategoriesForManage,
  createCategory,
  updateCategory,
  toggleCategoryStatus,
  deleteCategory,
} = require('../controllers/serviceCategoryController');
const { protect, authorize } = require('../middlewares/auth');

// 1. Public Routes
// Lấy toàn bộ danh mục dịch vụ đang kích hoạt
router.get('/', getCategories);

// Tìm kiếm danh mục dịch vụ
router.get('/search', searchCategories);

// 2. Staff & Admin Management Routes (UC-STF-02)
// Lấy toàn bộ danh mục kèm thống kê số lượng (đặt trước /:identifier để tránh match nhầm)
router.get('/manage', protect, authorize('admin', 'staff'), getAllCategoriesForManage);

// Tạo mới danh mục dịch vụ & giá sàn
router.post('/', protect, authorize('admin', 'staff'), createCategory);

// Cập nhật thông tin danh mục, icon và giá sàn
router.put('/:id', protect, authorize('admin', 'staff'), updateCategory);

// Đổi trạng thái kích hoạt / tạm ẩn
router.put('/:id/status', protect, authorize('admin', 'staff'), toggleCategoryStatus);

// Xóa danh mục dịch vụ
router.delete('/:id', protect, authorize('admin', 'staff'), deleteCategory);

// 3. Lấy chi tiết một danh mục dịch vụ theo slug hoặc id
router.get('/:identifier', getCategoryByIdentifier);

module.exports = router;
