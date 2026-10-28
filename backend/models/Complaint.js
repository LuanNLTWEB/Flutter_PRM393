const mongoose = require('mongoose');

// Khiếu nại là hồ sơ tranh chấp giữa Khách hàng và Thợ trên một đơn đã chốt thợ.
const complaintSchema = new mongoose.Schema(
  {
    requestId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'RepairRequest',
      required: [true, 'Phiếu yêu cầu là bắt buộc'],
      index: true,
    },
    reporterId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Người gửi khiếu nại là bắt buộc'],
      index: true,
    },
    respondentId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Bên liên quan là bắt buộc'],
    },
    category: {
      type: String,
      enum: ['SERVICE_QUALITY', 'PRICING', 'BEHAVIOR', 'PAYMENT', 'OTHER'],
      default: 'OTHER',
    },
    subject: {
      type: String,
      required: [true, 'Tiêu đề khiếu nại là bắt buộc'],
      trim: true,
      minlength: [6, 'Tiêu đề khiếu nại phải có ít nhất 6 ký tự'],
      maxlength: [120, 'Tiêu đề khiếu nại không được vượt quá 120 ký tự'],
    },
    description: {
      type: String,
      required: [true, 'Nội dung khiếu nại là bắt buộc'],
      trim: true,
      minlength: [20, 'Nội dung khiếu nại phải có ít nhất 20 ký tự'],
      maxlength: [2000, 'Nội dung khiếu nại không được vượt quá 2000 ký tự'],
    },
    evidenceUrls: {
      type: [String],
      default: [],
    },
    status: {
      type: String,
      enum: ['RECEIVED', 'IN_REVIEW', 'RESOLVED', 'REJECTED'],
      default: 'RECEIVED',
      index: true,
    },
    staffNote: {
      type: String,
      trim: true,
      maxlength: [2000, 'Biên bản xử lý không được vượt quá 2000 ký tự'],
      default: '',
    },
    handledBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    handledAt: {
      type: Date,
      default: null,
    },
  },
  { timestamps: true }
);

complaintSchema.index({ requestId: 1, reporterId: 1, status: 1 });
complaintSchema.index({ status: 1, createdAt: -1 });

module.exports = mongoose.model('Complaint', complaintSchema);
