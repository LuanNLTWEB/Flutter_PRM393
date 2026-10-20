const mongoose = require('mongoose');

// Schema Thông báo hệ thống & Người dùng (UC-NOT-01 & UC-NOT-02)
const notificationSchema = new mongoose.Schema(
  {
    // Người nhận thông báo
    recipient: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Người nhận thông báo là bắt buộc'],
      index: true,
    },

    // Tiêu đề ngắn gọn
    title: {
      type: String,
      required: [true, 'Tiêu đề thông báo là bắt buộc'],
      trim: true,
      maxlength: [120, 'Tiêu đề không được vượt quá 120 ký tự'],
    },

    // Nội dung chi tiết thông báo
    message: {
      type: String,
      required: [true, 'Nội dung thông báo là bắt buộc'],
      trim: true,
      maxlength: [500, 'Nội dung không được vượt quá 500 ký tự'],
    },

    // Phân loại thông báo
    type: {
      type: String,
      enum: {
        values: ['ORDER_STATUS', 'QUOTATION', 'APPOINTMENT', 'KYC', 'SYSTEM'],
        message: 'Loại thông báo không hợp lệ',
      },
      default: 'SYSTEM',
    },

    // Dữ liệu đính kèm (requestId, quotationId, action...)
    data: {
      type: mongoose.Schema.Types.Mixed,
      default: {},
    },

    // Trạng thái đã xem / chưa xem
    isRead: {
      type: Boolean,
      default: false,
      index: true,
    },

    // Thời điểm người dùng đọc thông báo
    readAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

// Tối ưu hóa truy vấn danh sách thông báo theo người nhận và thời gian mới nhất
notificationSchema.index({ recipient: 1, createdAt: -1 });
notificationSchema.index({ recipient: 1, isRead: 1 });

const Notification = mongoose.model('Notification', notificationSchema);

module.exports = Notification;
