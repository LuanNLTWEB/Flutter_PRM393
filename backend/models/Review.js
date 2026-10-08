const mongoose = require('mongoose');

const reviewSchema = new mongoose.Schema(
  {
    // Người đánh giá (Khách hàng)
    customerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Mã khách hàng là bắt buộc'],
    },
    // Người được đánh giá (Thợ kỹ thuật)
    technicianId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Mã thợ kỹ thuật là bắt buộc'],
    },
    // Đơn hàng / Yêu cầu sửa chữa liên quan (Tùy chọn để có thể test độc lập)
    bookingId: {
      type: mongoose.Schema.Types.ObjectId,
      default: null,
    },
    // Số sao đánh giá (1 đến 5 sao)
    rating: {
      type: Number,
      required: [true, 'Số sao đánh giá là bắt buộc'],
      min: [1, 'Đánh giá tối thiểu là 1 sao'],
      max: [5, 'Đánh giá tối đa là 5 sao'],
    },
    // Các tag chọn nhanh (ví dụ: 'Đúng giờ', 'Tay nghề tốt', 'Nhiệt tình', 'Giá hợp lý', 'Vệ sinh sạch sẽ')
    tags: {
      type: [String],
      default: [],
    },
    // Nhận xét chi tiết của khách hàng
    comment: {
      type: String,
      trim: true,
      maxlength: [1000, 'Nội dung nhận xét tối đa 1000 ký tự'],
      default: '',
    },
    // Phản hồi của thợ cho đánh giá này (Dành cho UC-RAT-02)
    reply: {
      comment: {
        type: String,
        trim: true,
        default: null,
      },
      repliedAt: {
        type: Date,
        default: null,
      },
    },
  },
  {
    timestamps: true,
  }
);

// Index hỗ trợ tìm kiếm nhanh theo thợ kỹ thuật và thời gian tạo
reviewSchema.index({ technicianId: 1, createdAt: -1 });

// Static method tính toán lại điểm rating trung bình của thợ
reviewSchema.statics.calculateAverageRating = async function (technicianId) {
  const stats = await this.aggregate([
    {
      $match: { technicianId: new mongoose.Types.ObjectId(technicianId) },
    },
    {
      $group: {
        _id: '$technicianId',
        averageRating: { $avg: '$rating' },
        reviewCount: { $sum: 1 },
      },
    },
  ]);

  const User = mongoose.model('User');
  if (stats.length > 0) {
    await User.findByIdAndUpdate(technicianId, {
      rating: Math.round(stats[0].averageRating * 10) / 10, // Làm tròn 1 chữ số thập phân
      reviewCount: stats[0].reviewCount,
    });
  } else {
    await User.findByIdAndUpdate(technicianId, {
      rating: 5.0,
      reviewCount: 0,
    });
  }
};

// Tự động tính lại rating sau khi lưu review mới
reviewSchema.post('save', async function () {
  await this.constructor.calculateAverageRating(this.technicianId);
});

// Tự động tính lại rating sau khi xóa review
reviewSchema.post('findOneAndDelete', async function (doc) {
  if (doc) {
    await doc.constructor.calculateAverageRating(doc.technicianId);
  }
});

const Review = mongoose.model('Review', reviewSchema);

module.exports = Review;
