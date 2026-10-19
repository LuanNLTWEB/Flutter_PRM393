const mongoose = require('mongoose');

// ============================================================================
// Bảng dữ liệu trung tâm của Epic "Báo giá & Khớp lệnh".
// Một bản ghi = 1 báo giá của 1 Thợ cho 1 phiếu yêu cầu.
//   UC-QUO-04: Gửi báo giá        — tạo bản ghi (status = SENT)
//   UC-QUO-05: Cập nhật / Hủy     — sửa labourCost/partsCost/note, hoặc RETRACT
//   UC-QUO-06: Xem danh sách nhận được — đọc nhiều bản ghi của 1 requestId
//   UC-QUO-07: So sánh các thợ    — đọc & so sánh total/rating giữa các bản ghi
//   UC-QUO-08: Chấp nhận           — status = ACCEPTED, các bản ghi khác = REJECTED
//   UC-QUO-09: Từ chối             — status = REJECTED
// ============================================================================
const quotationSchema = new mongoose.Schema(
  {
    // Phiếu yêu cầu được báo giá
    requestId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'RepairRequest',
      required: [true, 'Phiếu yêu cầu là bắt buộc'],
    },

    // Thợ gửi báo giá
    technicianId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Thợ báo giá là bắt buộc'],
    },

    // Tiền công ước tính
    labourCost: {
      type: Number,
      required: [true, 'Tiền công là bắt buộc'],
      min: [0, 'Tiền công không được âm'],
    },

    // Giá linh kiện (không có thì = 0)
    partsCost: {
      type: Number,
      default: 0,
      min: [0, 'Giá linh kiện không được âm'],
    },

    // Tổng cộng = tiền công + giá linh kiện (tự tính ở server)
    total: {
      type: Number,
      required: [true, 'Tổng chi phí là bắt buộc'],
      min: [0, 'Tổng chi phí không được âm'],
    },

    // Ghi chú gửi khách
    note: {
      type: String,
      trim: true,
      maxlength: [500, 'Ghi chú không được vượt quá 500 ký tự'],
      default: '',
    },

    // SENT: đã gửi | ACCEPTED: khách chốt | REJECTED: khách từ chối | RETRACTED: thợ thu hồi
    status: {
      type: String,
      enum: {
        values: ['SENT', 'ACCEPTED', 'REJECTED', 'RETRACTED'],
        message: 'Trạng thái báo giá không hợp lệ',
      },
      default: 'SENT',
    },

    // Thời điểm khách chốt / từ chối
    resolvedAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

// Mỗi thợ chỉ được 1 báo giá cho 1 phiếu yêu cầu
quotationSchema.index({ requestId: 1, technicianId: 1 }, { unique: true });
quotationSchema.index({ requestId: 1, createdAt: -1 });

// Tự tính tổng chi phí trước khi lưu
quotationSchema.pre('validate', function (next) {
  if (typeof this.labourCost === 'number' && typeof this.partsCost === 'number') {
    this.total = this.labourCost + this.partsCost;
  }
  next();
});

module.exports = mongoose.model('Quotation', quotationSchema);
