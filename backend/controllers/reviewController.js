const Review = require('../models/Review');
const User = require('../models/User');
const RepairRequest = require('../models/RepairRequest');

// Danh sách các tag đánh giá tiêu chuẩn
const DEFAULT_REVIEW_TAGS = [
  'Đúng giờ',
  'Tay nghề cao',
  'Nhiệt tình & Lịch sự',
  'Giá cả hợp lý',
  'Làm việc cẩn thận',
  'Dọn dẹp sạch sẽ',
  'Giải thích rõ ràng',
];

/**
 * @desc    Lấy danh sách các tag đánh giá gợi ý
 * @route   GET /api/reviews/tags
 * @access  Public
 */
const getReviewTags = async (req, res) => {
  try {
    return res.status(200).json({
      success: true,
      message: 'Lấy danh sách tag đánh giá thành công',
      data: DEFAULT_REVIEW_TAGS,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi lấy danh sách tag',
      error: error.message,
    });
  }
};

/**
 * @desc    Khách hàng gửi đánh giá cho thợ (UC-RAT-01 - Nghiệp vụ chuẩn: Bắt buộc đơn COMPLETED)
 * @route   POST /api/reviews
 * @access  Private (Chỉ user/khách hàng)
 */
const createReview = async (req, res) => {
  try {
    const customerId = req.user.id;
    const { bookingId, rating, tags, comment } = req.body;

    // 1. Kiểm tra mã đơn hàng
    if (!bookingId) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng cung cấp mã đơn hàng sửa chữa (bookingId)',
      });
    }

    // 2. Kiểm tra số sao đánh giá
    if (!rating || rating < 1 || rating > 5) {
      return res.status(400).json({
        success: false,
        message: 'Số sao đánh giá phải từ 1 đến 5 sao',
      });
    }

    // 3. Tìm đơn hàng trong hệ thống
    const repairRequest = await RepairRequest.findById(bookingId);
    if (!repairRequest) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy đơn hàng yêu cầu sửa chữa này',
      });
    }

    // 4. Kiểm tra quyền sở hữu đơn hàng (chỉ khách tạo đơn mới được đánh giá)
    if (repairRequest.customerId.toString() !== customerId.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Bạn chỉ có thể đánh giá cho đơn hàng do chính bạn tạo',
      });
    }

    // 5. Kiểm tra trạng thái đơn hàng: BẮT BUỘC PHẢI LÀ COMPLETED
    if (repairRequest.status !== 'COMPLETED') {
      return res.status(400).json({
        success: false,
        message: `Đơn hàng đang ở trạng thái "${repairRequest.status}", chưa hoàn tất! Chỉ có thể đánh giá khi đơn hàng đã COMPLETED.`,
      });
    }

    // 6. Xác định thợ kỹ thuật phụ trách từ chính đơn hàng
    const technicianId = repairRequest.assignedTechnicianId || req.body.technicianId;
    if (!technicianId) {
      return res.status(400).json({
        success: false,
        message: 'Đơn hàng này chưa được gán thông tin thợ kỹ thuật phụ trách',
      });
    }

    // Không được tự đánh giá chính mình
    if (customerId.toString() === technicianId.toString()) {
      return res.status(400).json({
        success: false,
        message: 'Bạn không thể tự đánh giá chính bản thân mình',
      });
    }

    // 7. Kiểm tra đơn hàng đã từng được đánh giá chưa (mỗi đơn chỉ đánh giá 1 lần)
    const existingReview = await Review.findOne({ bookingId });
    if (existingReview) {
      return res.status(400).json({
        success: false,
        message: 'Đơn hàng này đã được bạn gửi đánh giá trước đó rồi',
      });
    }

    // 8. Tạo review mới
    const review = await Review.create({
      customerId,
      technicianId,
      bookingId,
      rating: Number(rating),
      tags: Array.isArray(tags) ? tags : [],
      comment: (comment || '').trim(),
    });

    // 9. Cập nhật trạng thái đã đánh giá trên đơn hàng
    repairRequest.isReviewed = true;
    await repairRequest.save();

    const populatedReview = await Review.findById(review._id)
      .populate('customerId', 'fullName email')
      .populate('technicianId', 'fullName email rating reviewCount');

    return res.status(201).json({
      success: true,
      message: 'Gửi đánh giá dịch vụ thành công! Cảm ơn bạn đã phản hồi.',
      data: populatedReview,
    });
  } catch (error) {
    console.error('Create review error:', error);
    return res.status(500).json({
      success: false,
      message: 'Lỗi khi gửi đánh giá',
      error: error.message,
    });
  }
};

/**
 * @desc    Kiểm tra trạng thái đánh giá của một đơn hàng
 * @route   GET /api/reviews/order/:bookingId
 * @access  Private
 */
const checkOrderReviewStatus = async (req, res) => {
  try {
    const { bookingId } = req.params;
    const customerId = req.user.id;

    const repairRequest = await RepairRequest.findById(bookingId)
      .populate('assignedTechnicianId', 'fullName email rating');

    if (!repairRequest) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy đơn hàng',
      });
    }

    const review = await Review.findOne({ bookingId });

    return res.status(200).json({
      success: true,
      data: {
        bookingId,
        orderStatus: repairRequest.status,
        canReview:
          repairRequest.status === 'COMPLETED' &&
          repairRequest.customerId.toString() === customerId.toString() &&
          !review,
        hasReviewed: !!review,
        technician: repairRequest.assignedTechnicianId,
        review,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Lỗi kiểm tra trạng thái đánh giá',
      error: error.message,
    });
  }
};

/**
 * @desc    Lấy danh sách đánh giá & thống kê của 1 thợ
 * @route   GET /api/reviews/technician/:technicianId
 * @access  Public
 */
const getTechnicianReviews = async (req, res) => {
  try {
    const { technicianId } = req.params;
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 10;
    const skip = (page - 1) * limit;

    // Lọc theo rating cụ thể nếu có truyền lên query (?star=5)
    const filter = { technicianId };
    if (req.query.star) {
      filter.rating = parseInt(req.query.star, 10);
    }

    // Đếm tổng số review và truy vấn danh sách
    const totalReviews = await Review.countDocuments(filter);
    const reviews = await Review.find(filter)
      .populate('customerId', 'fullName email')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    // Tính toán thống kê phân bổ số sao (Breakdown 1-5 sao)
    const allReviewsOfTech = await Review.find({ technicianId });
    const starCounts = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
    let sumRating = 0;

    allReviewsOfTech.forEach((r) => {
      if (starCounts[r.rating] !== undefined) {
        starCounts[r.rating]++;
      }
      sumRating += r.rating;
    });

    const totalCount = allReviewsOfTech.length;
    const averageRating =
      totalCount > 0 ? Math.round((sumRating / totalCount) * 10) / 10 : 5.0;

    return res.status(200).json({
      success: true,
      message: 'Lấy danh sách đánh giá thành công',
      data: {
        summary: {
          averageRating,
          totalReviews: totalCount,
          starBreakdown: starCounts,
        },
        pagination: {
          currentPage: page,
          totalPages: Math.ceil(totalReviews / limit),
          totalItems: totalReviews,
          limit,
        },
        reviews,
      },
    });
  } catch (error) {
    console.error('Get technician reviews error:', error);
    return res.status(500).json({
      success: false,
      message: 'Lỗi khi lấy danh sách đánh giá của thợ',
      error: error.message,
    });
  }
};

/**
 * @desc    Xem danh sách đánh giá mà khách hàng đã gửi
 * @route   GET /api/reviews/my-reviews
 * @access  Private (Khách hàng)
 */
const getMyReviews = async (req, res) => {
  try {
    const customerId = req.user.id;
    const reviews = await Review.find({ customerId })
      .populate('technicianId', 'fullName email')
      .sort({ createdAt: -1 });

    return res.status(200).json({
      success: true,
      message: 'Lấy lịch sử đánh giá của bạn thành công',
      data: reviews,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Lỗi khi lấy danh sách đánh giá của bạn',
      error: error.message,
    });
  }
};

/**
 * @desc    Thợ phản hồi lại nhận xét của khách (UC-RAT-02)
 * @route   PUT /api/reviews/:id/reply
 * @access  Private (Thợ sửa)
 */
const replyReview = async (req, res) => {
  try {
    const { id } = req.params;
    const { comment } = req.body;

    if (!comment || !comment.trim()) {
      return res.status(400).json({
        success: false,
        message: 'Nội dung phản hồi không được để trống',
      });
    }

    const review = await Review.findById(id);
    if (!review) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy đánh giá này',
      });
    }

    // Chỉ thợ được đánh giá mới có quyền phản hồi
    if (review.technicianId.toString() !== req.user.id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Bạn chỉ có thể phản hồi các đánh giá dành cho chính mình',
      });
    }

    review.reply = {
      comment: comment.trim(),
      repliedAt: new Date(),
    };

    await review.save();

    return res.status(200).json({
      success: true,
      message: 'Phản hồi đánh giá thành công',
      data: review,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Lỗi khi phản hồi đánh giá',
      error: error.message,
    });
  }
};

/**
 * @desc    Lấy danh sách thợ kỹ thuật để khách hàng xem và đánh giá
 * @route   GET /api/reviews/technicians
 * @access  Public
 */
const getTechnicians = async (req, res) => {
  try {
    const technicians = await User.find({
      role: 'technician',
      isDeleted: false,
      isActive: true,
    }).select('fullName email rating reviewCount');

    return res.status(200).json({
      success: true,
      message: 'Lấy danh sách thợ kỹ thuật thành công',
      data: technicians,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Lỗi khi lấy danh sách thợ',
      error: error.message,
    });
  }
};

module.exports = {
  getReviewTags,
  getTechnicians,
  createReview,
  checkOrderReviewStatus,
  getTechnicianReviews,
  getMyReviews,
  replyReview,
};
