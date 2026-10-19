const express = require('express');
const router = express.Router();
const {
  getNotifications,
  getUnreadCount,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  clearAllNotifications,
} = require('../controllers/notificationController');
const { protect } = require('../middlewares/auth');

// Toàn bộ API thông báo yêu cầu người dùng đăng nhập
router.use(protect);

// Lấy danh sách thông báo & đếm chưa đọc
router.get('/', getNotifications);
router.get('/unread-count', getUnreadCount);

// Đánh dấu đã đọc
router.put('/read-all', markAllAsRead);
router.put('/:id/read', markAsRead);

// Xóa thông báo
router.delete('/clear-all', clearAllNotifications);
router.delete('/:id', deleteNotification);

module.exports = router;
