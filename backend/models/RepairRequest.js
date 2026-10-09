const mongoose = require('mongoose');

// Phiếu yêu cầu sửa chữa của khách hàng
const repairRequestSchema = new mongoose.Schema(
  {
    // Khách hàng tạo yêu cầu
    customerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Thông tin khách hàng là bắt buộc'],
    },

    // Danh mục dịch vụ
    serviceCategoryId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'ServiceCategory',
      required: [true, 'Danh mục dịch vụ là bắt buộc'],
    },

    // Tiêu đề yêu cầu
    title: {
      type: String,
      required: [true, 'Tiêu đề sự cố là bắt buộc'],
      trim: true,
      maxlength: [200, 'Tiêu đề không được vượt quá 200 ký tự'],
    },

    // Mô tả chi tiết triệu chứng
    description: {
      type: String,
      required: [true, 'Mô tả triệu chứng hỏng hóc là bắt buộc'],
      trim: true,
      minlength: [10, 'Mô tả phải có ít nhất 10 ký tự'],
      maxlength: [1000, 'Mô tả không được vượt quá 1000 ký tự'],
    },

    // Danh sách ảnh hiện trường
    images: {
      type: [String],
      default: [],
    },

    // Mức độ khẩn cấp: low, medium, high, emergency
    urgency: {
      type: String,
      enum: {
        values: ['low', 'medium', 'high', 'emergency'],
        message: 'Mức độ khẩn cấp không hợp lệ',
      },
      default: 'medium',
    },

    // Địa chỉ và tọa độ sửa chữa
    location: {
      address: {
        type: String,
        trim: true,
        default: 'Chưa cập nhật địa chỉ',
      },
      latitude: {
        type: Number,
        default: null,
      },
      longitude: {
        type: Number,
        default: null,
      },
    },

    // Trạng thái yêu cầu: OPEN, QUOTED, ACCEPTED, IN_PROGRESS, COMPLETED, CANCELLED
    status: {
      type: String,
      enum: {
        values: ['OPEN', 'QUOTED', 'ACCEPTED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'],
        message: 'Trạng thái yêu cầu không hợp lệ',
      },
      default: 'OPEN',
    },

    // Thợ kỹ thuật được chỉ định thực hiện
    assignedTechnicianId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },

    // Trạng thái đánh giá dịch vụ
    isReviewed: {
      type: Boolean,
      default: false,
    },

    // Số điện thoại liên hệ
    contactPhone: {
      type: String,
      trim: true,
      default: '',
    },

    // Thời gian mong muốn
    preferredTime: {
      type: Date,
      default: null,
    },

    // Ghi chú của khách hàng
    customerNote: {
      type: String,
      trim: true,
      default: '',
    },

    // Thời điểm hủy
    cancelledAt: {
      type: Date,
      default: null,
    },

    // Lý do hủy
    cancellationReason: {
      type: String,
      trim: true,
      default: '',
    },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

repairRequestSchema.index({ customerId: 1, status: 1 });
repairRequestSchema.index({ serviceCategoryId: 1, status: 1 });
repairRequestSchema.index({ status: 1, createdAt: -1 });

module.exports = mongoose.model('RepairRequest', repairRequestSchema);
