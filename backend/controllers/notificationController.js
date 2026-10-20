const Notification = require('../models/Notification');

/**
 * @desc    Lấy danh sách thông báo của người dùng hiện tại (có phân trang & lọc)
 * @route   GET /api/notifications
 * @access  Private
 */
const getNotifications = async (req, res) => {
  try {
    const { page = 1, limit = 20, isRead, type } = req.query;

    const query = {
      recipient: req.user._id,
    };

    if (isRead !== undefined && isRead !== '') {
      query.isRead = isRead === 'true';
    }

    if (type && type.trim() !== '') {
      query.type = type.trim();
    }

    const pageNumber = Math.max(1, parseInt(page, 10) || 1);
    const pageSize = Math.max(1, parseInt(limit, 10) || 20);
    const skip = (pageNumber - 1) * pageSize;

    const [total, unreadCount, notifications] = await Promise.all([
      Notification.countDocuments(query),
      Notification.countDocuments({ recipient: req.user._id, isRead: false }),
      Notification.find(query)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(pageSize),
    ]);

    return res.status(200).json({
      success: true,
      message: 'Lấy danh sách thông báo thành công',
      data: {
        notifications,
        total,
        unreadCount,
        page: pageNumber,
        totalPages: Math.ceil(total / pageSize) || 1,
      },
    });
  } catch (error) {
    console.error('Lỗi khi lấy danh sách thông báo:', error);
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi lấy danh sách thông báo',
      error: error.message,
    });
  }
};

/**
 * @desc    Lấy số lượng thông báo chưa đọc
 * @route   GET /api/notifications/unread-count
 * @access  Private
 */
const getUnreadCount = async (req, res) => {
  try {
    const unreadCount = await Notification.countDocuments({
      recipient: req.user._id,
      isRead: false,
    });

    return res.status(200).json({
      success: true,
      message: 'Lấy số lượng thông báo chưa đọc thành công',
      data: {
        unreadCount,
      },
    });
  } catch (error) {
    console.error('Lỗi khi lấy số thông báo chưa đọc:', error);
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi lấy số thông báo chưa đọc',
      error: error.message,
    });
  }
};

/**
 * @desc    Đánh dấu 1 thông báo là đã đọc
 * @route   PUT /api/notifications/:id/read
 * @access  Private
 */
const markAsRead = async (req, res) => {
  try {
    const { id } = req.params;

    const notification = await Notification.findOne({
      _id: id,
      recipient: req.user._id,
    });

    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy thông báo',
      });
    }

    if (!notification.isRead) {
      notification.isRead = true;
      notification.readAt = new Date();
      await notification.save();
    }

    const unreadCount = await Notification.countDocuments({
      recipient: req.user._id,
      isRead: false,
    });

    return res.status(200).json({
      success: true,
      message: 'Đã đánh dấu thông báo là đã đọc',
      data: {
        notification,
        unreadCount,
      },
    });
  } catch (error) {
    console.error('Lỗi khi đánh dấu thông báo đã đọc:', error);
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi cập nhật thông báo',
      error: error.message,
    });
  }
};

/**
 * @desc    Đánh dấu tất cả thông báo của người dùng là đã đọc
 * @route   PUT /api/notifications/read-all
 * @access  Private
 */
const markAllAsRead = async (req, res) => {
  try {
    const now = new Date();
    const result = await Notification.updateMany(
      { recipient: req.user._id, isRead: false },
      { $set: { isRead: true, readAt: now } }
    );

    return res.status(200).json({
      success: true,
      message: `Đã đánh dấu ${result.modifiedCount} thông báo là đã đọc`,
      data: {
        modifiedCount: result.modifiedCount,
        unreadCount: 0,
      },
    });
  } catch (error) {
    console.error('Lỗi khi đánh dấu tất cả thông báo đã đọc:', error);
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi cập nhật tất cả thông báo',
      error: error.message,
    });
  }
};

/**
 * @desc    Xóa một thông báo cụ thể
 * @route   DELETE /api/notifications/:id
 * @access  Private
 */
const deleteNotification = async (req, res) => {
  try {
    const { id } = req.params;

    const notification = await Notification.findOneAndDelete({
      _id: id,
      recipient: req.user._id,
    });

    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy thông báo cần xóa',
      });
    }

    const unreadCount = await Notification.countDocuments({
      recipient: req.user._id,
      isRead: false,
    });

    return res.status(200).json({
      success: true,
      message: 'Đã xóa thông báo thành công',
      data: {
        deletedId: id,
        unreadCount,
      },
    });
  } catch (error) {
    console.error('Lỗi khi xóa thông báo:', error);
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi xóa thông báo',
      error: error.message,
    });
  }
};

/**
 * @desc    Xóa toàn bộ thông báo của người dùng
 * @route   DELETE /api/notifications/clear-all
 * @access  Private
 */
const clearAllNotifications = async (req, res) => {
  try {
    const result = await Notification.deleteMany({
      recipient: req.user._id,
    });

    return res.status(200).json({
      success: true,
      message: `Đã xóa tất cả ${result.deletedCount} thông báo`,
      data: {
        deletedCount: result.deletedCount,
        unreadCount: 0,
      },
    });
  } catch (error) {
    console.error('Lỗi khi xóa tất cả thông báo:', error);
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi xóa tất cả thông báo',
      error: error.message,
    });
  }
};

/**
 * Utility helper tạo thông báo nội bộ hệ thống từ các controller khác
 */
const createNotificationUtil = async ({
  recipient,
  title,
  message,
  type = 'SYSTEM',
  data = {},
}) => {
  try {
    if (!recipient || !title || !message) return null;
    const notification = await Notification.create({
      recipient,
      title,
      message,
      type,
      data,
    });
    return notification;
  } catch (err) {
    console.error('Lỗi tạo thông báo tự động:', err.message);
    return null;
  }
};

module.exports = {
  getNotifications,
  getUnreadCount,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  clearAllNotifications,
  createNotificationUtil,
};
