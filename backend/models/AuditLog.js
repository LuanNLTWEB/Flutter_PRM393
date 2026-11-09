const mongoose = require('mongoose');

/**
 * Schema lưu trữ nhật ký hoạt động (Audit Log)
 * Ghi nhận lịch sử thao tác kiểm duyệt, quản trị của Staff và Admin
 */
const auditLogSchema = new mongoose.Schema(
  {
    // Người thực hiện thao tác (Staff hoặc Admin)
    actorId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    actorName: {
      type: String,
      required: true,
      trim: true,
    },
    actorEmail: {
      type: String,
      default: '',
      trim: true,
    },
    actorRole: {
      type: String,
      enum: ['staff', 'admin'],
      required: true,
    },

    // Mã hành động (ví dụ: KYC_APPROVE, KYC_REJECT, USER_LOCK, USER_UNLOCK, ROLE_UPDATE, STAFF_CREATE, COMPLAINT_HANDLE, CATEGORY_CREATE, CATEGORY_UPDATE, CATEGORY_STATUS, CATEGORY_DELETE)
    action: {
      type: String,
      required: true,
      index: true,
    },

    // Tiêu đề hành động dễ hiểu cho người xem (ví dụ: "Phê duyệt hồ sơ thợ", "Từ chối hồ sơ thợ", "Khóa tài khoản"...)
    actionTitle: {
      type: String,
      required: true,
      trim: true,
    },

    // Nhóm đối tượng bị tác động
    targetType: {
      type: String,
      enum: ['Technician', 'User', 'Complaint', 'ServiceCategory', 'Other'],
      default: 'Other',
    },

    // ID đối tượng bị tác động (nếu có)
    targetId: {
      type: String,
      default: '',
    },

    // Tên hoặc định danh của đối tượng (ví dụ: Họ tên thợ, Họ tên người dùng, Tên danh mục dịch vụ, Tiêu đề khiếu nại)
    targetName: {
      type: String,
      default: '',
      trim: true,
    },

    // Chi tiết bổ sung (ví dụ: lý do từ chối hồ sơ, ghi chú biên bản xử lý, vai trò mới, giá sàn...)
    details: {
      type: String,
      default: '',
      trim: true,
    },
  },
  {
    timestamps: true, // Tự động tạo createdAt (thời gian thao tác) và updatedAt
  }
);

// Tạo index để tìm kiếm và lọc nhanh theo thời gian và người thực hiện
auditLogSchema.index({ createdAt: -1 });
auditLogSchema.index({ actorRole: 1, createdAt: -1 });
auditLogSchema.index({ action: 1, createdAt: -1 });

const AuditLog = mongoose.model('AuditLog', auditLogSchema);

module.exports = AuditLog;
