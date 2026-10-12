const RepairRequest = require('../models/RepairRequest');
const ServiceCategory = require('../models/ServiceCategory');
const Quotation = require('../models/Quotation');
const { uploadStream, deleteImage } = require('../config/cloudinary');

// Hàm kiểm tra văn bản spam hoặc ký tự vô nghĩa lặp lại
const isSpamText = (text) => {
  if (!text) return true;
  const clean = text.replace(/\s+/g, '');
  if (clean.length === 0) return true;
  // Ký tự lặp lại 5 lần liên tiếp: vd aaaaa, 11111
  if (/(.)\1{4,}/i.test(clean)) return true;
  // Chuỗi có quá ít ký tự phân biệt (dưới 3 ký tự khác nhau)
  const uniqueChars = new Set(clean.toLowerCase().split(''));
  if (clean.length >= 8 && uniqueChars.size < 3) return true;
  return false;
};

// Tạo yêu cầu sửa chữa mới
const createRepairRequest = async (req, res) => {
  try {
    const {
      serviceCategoryId,
      title,
      description,
      urgency,
      preferredTime,
    } = req.body;

    const category = await ServiceCategory.findById(serviceCategoryId);
    if (!category || !category.isActive) {
      return res.status(404).json({
        success: false,
        message: 'Danh mục dịch vụ không tồn tại hoặc đã ngừng hoạt động',
      });
    }

    const reqTitle = (title || '').trim();
    if (!reqTitle) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng nhập tiêu đề yêu cầu sửa chữa',
      });
    }

    if (reqTitle.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Tiêu đề sự cố quá ngắn (tối thiểu 6 ký tự)',
      });
    }

    if (reqTitle.length > 150) {
      return res.status(400).json({
        success: false,
        message: 'Tiêu đề không được vượt quá 150 ký tự',
      });
    }

    if (isSpamText(reqTitle)) {
      return res.status(400).json({
        success: false,
        message: 'Tiêu đề không hợp lệ, vui lòng không nhập ký tự lặp hoặc từ vô nghĩa',
      });
    }

    const reqDesc = (description || '').trim();
    if (!reqDesc) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng mô tả chi tiết sự cố hỏng hóc',
      });
    }

    if (reqDesc.length < 15) {
      return res.status(400).json({
        success: false,
        message: 'Mô tả triệu chứng hỏng hóc quá ngắn. Vui lòng nhập tối thiểu 15 ký tự để thợ có thể nắm được tình trạng',
      });
    }

    if (reqDesc.length > 1000) {
      return res.status(400).json({
        success: false,
        message: 'Mô tả không được vượt quá 1000 ký tự',
      });
    }

    const wordCount = reqDesc.split(/\s+/).filter(Boolean).length;
    if (wordCount < 3) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng mô tả rõ ràng hơn (ít nhất 3 từ) để thợ có thể hình dung sự cố',
      });
    }

    if (isSpamText(reqDesc)) {
      return res.status(400).json({
        success: false,
        message: 'Mô tả chứa ký tự lặp hoặc chuỗi vô nghĩa. Vui lòng mô tả sự cố thực tế',
      });
    }

    let normalizedUrgency = 'medium';
    const rawUrgency = (urgency || '').toLowerCase();
    if (['low', 'medium', 'high', 'emergency'].includes(rawUrgency)) {
      normalizedUrgency = rawUrgency;
    }

    let parsedPreferredTime = null;
    if (preferredTime) {
      const dt = new Date(preferredTime);
      if (!isNaN(dt.getTime())) {
        parsedPreferredTime = dt;
      }
    }

    const newRequest = await RepairRequest.create({
      customerId: req.user._id,
      serviceCategoryId,
      title: reqTitle,
      description: reqDesc,
      urgency: normalizedUrgency,
      preferredTime: parsedPreferredTime,
      status: 'OPEN',
      contactPhone: req.user.phoneNumber || '',
    });

    const populated = await RepairRequest.findById(newRequest._id)
      .populate('serviceCategoryId', 'name slug icon color basePrice')
      .populate('customerId', 'fullName email phoneNumber avatar');

    return res.status(201).json({
      success: true,
      message: 'Phiếu yêu cầu sửa chữa đã được tạo thành công',
      data: {
        repairRequest: populated,
      },
    });
  } catch (error) {
    console.error('createRepairRequest error:', error.message);

    if (error.name === 'ValidationError') {
      const messages = Object.values(error.errors).map((e) => e.message);
      return res.status(400).json({
        success: false,
        message: messages.join('. '),
      });
    }

    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi tạo yêu cầu sửa chữa',
      error: error.message,
    });
  }
};

/**
 * @desc    Xem lịch sử đơn hàng của tôi (UC-HIS-01: Đang xử lý, Đã hoàn tất, Đã hủy)
 * @route   GET /api/requests/my-requests
 * @access  Private (Khách hàng & Thợ)
 */
const getMyRepairRequests = async (req, res) => {
  try {
    const isTech = req.user.role === 'technician';
    const baseFilter = isTech
      ? { assignedTechnicianId: req.user._id }
      : { customerId: req.user._id };

    const { tab } = req.query; // PROCESSING, COMPLETED, CANCELLED, hoặc ALL
    let statusFilter = {};

    if (tab === 'PROCESSING') {
      statusFilter = { status: { $in: ['OPEN', 'QUOTED', 'ACCEPTED', 'IN_PROGRESS'] } };
    } else if (tab === 'COMPLETED') {
      statusFilter = { status: 'COMPLETED' };
    } else if (tab === 'CANCELLED') {
      statusFilter = { status: 'CANCELLED' };
    }

    const filter = { ...baseFilter, ...statusFilter };

    const requests = await RepairRequest.find(filter)
      .populate('serviceCategoryId', 'name slug icon color basePrice')
      .populate('assignedTechnicianId', 'fullName email phoneNumber avatar rating reviewCount')
      .populate('customerId', 'fullName email phoneNumber avatar')
      .sort({ createdAt: -1 });

    // Đếm số lượng theo từng tab
    const [processingCount, completedCount, cancelledCount] = await Promise.all([
      RepairRequest.countDocuments({
        ...baseFilter,
        status: { $in: ['OPEN', 'QUOTED', 'ACCEPTED', 'IN_PROGRESS'] },
      }),
      RepairRequest.countDocuments({ ...baseFilter, status: 'COMPLETED' }),
      RepairRequest.countDocuments({ ...baseFilter, status: 'CANCELLED' }),
    ]);

    return res.status(200).json({
      success: true,
      message: 'Lấy lịch sử đơn hàng thành công',
      data: {
        requests,
        counts: {
          processing: processingCount,
          completed: completedCount,
          cancelled: cancelledCount,
          total: processingCount + completedCount + cancelledCount,
        },
      },
    });
  } catch (error) {
    console.error('getMyRepairRequests error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Lỗi khi tải lịch sử đơn hàng',
      error: error.message,
    });
  }
};

/**
 * @desc    Thợ upload ảnh sau khi hoàn tất sửa chữa (UC-CFM-01)
 * @route   POST /api/requests/:id/completion-images
 * @access  Private (technician - thợ được gán cho đơn)
 */
const uploadCompletionImages = async (req, res) => {
  const uploadedPublicIds = [];

  try {
    const request = await RepairRequest.findById(req.params.id);
    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy phiếu yêu cầu sửa chữa',
      });
    }

    if (!req.files || req.files.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng chọn ít nhất một ảnh sau khi sửa',
      });
    }

    if (req.files.length > 5) {
      return res.status(400).json({
        success: false,
        message: 'Mỗi lần chỉ được tải tối đa 5 ảnh sau khi sửa',
      });
    }

    if (request.status !== 'ACCEPTED' && request.status !== 'IN_PROGRESS') {
      return res.status(400).json({
        success: false,
        message: 'Đơn hàng không ở trạng thái có thể nghiệm thu',
      });
    }

    // Tương thích với các đơn cũ chưa được gán assignedTechnicianId khi chốt báo giá.
    let isAssignedTechnician =
      request.assignedTechnicianId?.toString() === req.user._id.toString();

    if (!isAssignedTechnician) {
      const acceptedQuotation = await Quotation.findOne({
        requestId: request._id,
        technicianId: req.user._id,
        status: 'ACCEPTED',
      });
      isAssignedTechnician = Boolean(acceptedQuotation);

      if (isAssignedTechnician && !request.assignedTechnicianId) {
        request.assignedTechnicianId = req.user._id;
      }
    }

    if (!isAssignedTechnician) {
      return res.status(403).json({
        success: false,
        message: 'Bạn không phải thợ được gán cho đơn hàng này',
      });
    }

    if (request.completionImages.length + req.files.length > 5) {
      return res.status(400).json({
        success: false,
        message: 'Mỗi đơn hàng chỉ được lưu tối đa 5 ảnh sau khi sửa',
      });
    }

    const uploadedUrls = [];
    for (const file of req.files) {
      const result = await uploadStream(file.buffer, {
        folder: 'homefix/completion-images',
        transformation: [{ quality: 'auto', fetch_format: 'auto' }],
      });
      uploadedUrls.push(result.url);
      uploadedPublicIds.push(result.publicId);
    }

    request.completionImages.push(...uploadedUrls);
    if (request.status === 'ACCEPTED') {
      request.status = 'IN_PROGRESS';
    }
    await request.save();

    const populated = await RepairRequest.findById(request._id)
      .populate('serviceCategoryId', 'name slug icon color basePrice')
      .populate('assignedTechnicianId', 'fullName email phoneNumber avatar');

    return res.status(200).json({
      success: true,
      message: 'Đã tải ảnh sau khi sửa thành công',
      data: { repairRequest: populated },
    });
  } catch (error) {
    await Promise.all(uploadedPublicIds.map((publicId) => deleteImage(publicId)));
    console.error('uploadCompletionImages error:', error.message);

    if (error.name === 'CastError') {
      return res.status(400).json({
        success: false,
        message: 'Mã phiếu yêu cầu không hợp lệ',
      });
    }

    return res.status(500).json({
      success: false,
      message: 'Lỗi khi tải ảnh sau khi sửa',
      error: error.message,
    });
  }
};

module.exports = {
  createRepairRequest,
  getMyRepairRequests,
  uploadCompletionImages,
};
