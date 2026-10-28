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
      minlength: [6, 'Tiêu đề phải có ít nhất 6 ký tự'],
      maxlength: [150, 'Tiêu đề không được vượt quá 150 ký tự'],
    },

    // Mô tả chi tiết triệu chứng
    description: {
      type: String,
      required: [true, 'Mô tả triệu chứng hỏng hóc là bắt buộc'],
      trim: true,
      minlength: [15, 'Mô tả triệu chứng phải có ít nhất 15 ký tự'],
      maxlength: [1000, 'Mô tả không được vượt quá 1000 ký tự'],
    },

    // Danh sách ảnh hiện trường
    images: {
      type: [String],
      default: [],
    },

    // Ảnh sau khi thợ hoàn tất sửa chữa (UC-CFM-01)
    completionImages: {
      type: [String],
      default: [],
    },

    // Ảnh chứng từ / hóa đơn mua linh kiện thay thế (UC-PAY-03)
    partsInvoiceImages: {
      type: [String],
      default: [],
    },

    // Token QR nghiệm thu chỉ lưu dạng băm; token gốc chỉ được trả về cho Thợ.
    completionQrTokenHash: {
      type: String,
      default: null,
      select: false,
    },

    completionQrGeneratedAt: {
      type: Date,
      default: null,
    },

    completionQrExpiresAt: {
      type: Date,
      default: null,
    },

    // Thông tin Khách xác nhận nghiệm thu (UC-CFM-03)
    completionConfirmedAt: {
      type: Date,
      default: null,
    },

    completionConfirmedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },

    completedAt: {
      type: Date,
      default: null,
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

    // Trạng thái yêu cầu: OPEN, QUOTED, ACCEPTED, ON_THE_WAY, ARRIVED, IN_PROGRESS, COMPLETED, CANCELLED
    status: {
      type: String,
      enum: {
        values: ['OPEN', 'QUOTED', 'ACCEPTED', 'ON_THE_WAY', 'ARRIVED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'],
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

    // Phương thức thanh toán khách hàng đã chọn (UC-PAY-02)
    paymentMethod: {
      type: String,
      enum: ['CASH', 'BANK_TRANSFER'],
      default: null,
    },

    paymentMethodSelectedAt: {
      type: Date,
      default: null,
    },

    // Trạng thái thu tiền mặt (UC-PAY-04): UNPAID, PAID
    paymentStatus: {
      type: String,
      enum: ['UNPAID', 'PAID'],
      default: 'UNPAID',
    },

    // Thời điểm thợ xác nhận đã thu đủ tiền mặt (UC-PAY-04)
    paidAt: {
      type: Date,
      default: null,
    },

    // Thợ nhận tiền (UC-PAY-04)
    paymentReceivedBy: {
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

    // Trạng thái lịch hẹn: PENDING (chờ thợ xác nhận), CONFIRMED (đã xác nhận), RESCHEDULED (thợ đề xuất giờ mới)
    appointmentStatus: {
      type: String,
      enum: {
        values: ['PENDING', 'CONFIRMED', 'RESCHEDULED'],
        message: 'Trạng thái lịch hẹn không hợp lệ',
      },
      default: 'PENDING',
    },

    // Giờ mới do Thợ đề xuất (khi appointmentStatus = RESCHEDULED)
    proposedTime: {
      type: Date,
      default: null,
    },

    // Lý do Thợ đổi lịch (tùy chọn)
    rescheduleNote: {
      type: String,
      trim: true,
      maxlength: [300, 'Lý do đổi lịch không được vượt quá 300 ký tự'],
      default: '',
    },

    // Lý do Khách từ chối khung giờ thợ đề xuất (tùy chọn)
    rescheduleRejectNote: {
      type: String,
      trim: true,
      maxlength: [300, 'Lý do từ chối không được vượt quá 300 ký tự'],
      default: '',
    },

    // Thời điểm Thợ xác nhận lịch hẹn
    appointmentConfirmedAt: {
      type: Date,
      default: null,
    },

    // Thời điểm Thợ bấm "Đang trên đường đến nhà khách"
    onTheWayAt: {
      type: Date,
      default: null,
    },

    // Thời điểm Thợ bấm "Đã có mặt tại hiện trường"
    arrivedAt: {
      type: Date,
      default: null,
    },

    // Thời điểm Thợ bấm "Bắt đầu sửa chữa"
    startedAt: {
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

    // Vai trò khởi tạo hủy tại chỗ (UC-WRK-07)
    cancellationInitiatedBy: {
      type: String,
      enum: ['customer', 'technician', null],
      default: null,
    },

    // Chi phí phát sinh Thợ khai báo khi đang sửa chữa (UC-WRK-05)
    additionalCosts: [
      {
        // Tên phụ tùng / hạng mục phát sinh
        name: {
          type: String,
          required: [true, 'Tên phụ tùng phát sinh là bắt buộc'],
          trim: true,
          maxlength: [200, 'Tên phụ tùng không được vượt quá 200 ký tự'],
        },

        // Số lượng cần thay
        quantity: {
          type: Number,
          required: true,
          min: [1, 'Số lượng phải từ 1'],
          default: 1,
        },

        // Đơn giá thực tế phát sinh (VNĐ)
        unitPrice: {
          type: Number,
          required: [true, 'Đơn giá phát sinh là bắt buộc'],
          min: [0, 'Đơn giá không được là số âm'],
        },

        // Ghi chú thêm của Thợ (tùy chọn)
        note: {
          type: String,
          trim: true,
          maxlength: [300, 'Ghi chú không được vượt quá 300 ký tự'],
          default: '',
        },

        // Trạng thái phê duyệt: PENDING (chờ khách), APPROVED (đồng ý), REJECTED (từ chối)
        status: {
          type: String,
          enum: {
            values: ['PENDING', 'APPROVED', 'REJECTED'],
            message: 'Trạng thái chi phí phát sinh không hợp lệ',
          },
          default: 'PENDING',
        },

        // Lý do Khách từ chối (tùy chọn)
        customerNote: {
          type: String,
          trim: true,
          maxlength: [300, 'Lý do từ chối không được vượt quá 300 ký tự'],
          default: '',
        },

        // Thời điểm Thợ khai báo
        declaredAt: {
          type: Date,
          default: Date.now,
        },

        // Thời điểm Khách đồng ý / từ chối
        decidedAt: {
          type: Date,
          default: null,
        },
      },
    ],
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
