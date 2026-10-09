const RepairRequest = require('../models/RepairRequest');
const ServiceCategory = require('../models/ServiceCategory');

// Tạo yêu cầu sửa chữa mới
const createRepairRequest = async (req, res) => {
  try {
    const {
      serviceCategoryId,
      title,
      description,
      urgency,
    } = req.body;

    const category = await ServiceCategory.findById(serviceCategoryId);
    if (!category || !category.isActive) {
      return res.status(404).json({
        success: false,
        message: 'Danh mục dịch vụ không tồn tại hoặc đã ngừng hoạt động',
      });
    }

    const reqTitle = (title || category.name || 'Yêu cầu sửa chữa').trim();
    const reqDesc = (description || '').trim();

    if (!reqDesc || reqDesc.length < 10) {
      return res.status(400).json({
        success: false,
        message: 'Mô tả triệu chứng hỏng hóc phải có ít nhất 10 ký tự',
      });
    }

    let normalizedUrgency = 'medium';
    const rawUrgency = (urgency || '').toLowerCase();
    if (['low', 'medium', 'high', 'emergency'].includes(rawUrgency)) {
      normalizedUrgency = rawUrgency;
    }

    const newRequest = await RepairRequest.create({
      customerId: req.user._id,
      serviceCategoryId,
      title: reqTitle,
      description: reqDesc,
      urgency: normalizedUrgency,
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
 * @desc    Tạo đơn hàng mẫu đã hoàn tất (COMPLETED) để kiểm thử luồng đánh giá chuẩn
 * @route   POST /api/requests/seed-demo
 * @access  Private (Khách hàng)
 */
const seedDemoCompletedRequest = async (req, res) => {
  try {
    const User = require('../models/User');
    // Tìm 1 thợ có sẵn trong hệ thống
    const technician = await User.findOne({ role: 'technician', isDeleted: false });
    if (!technician) {
      return res.status(400).json({
        success: false,
        message: 'Hệ thống chưa có thợ kỹ thuật nào để tạo đơn mẫu',
      });
    }

    // Tìm 1 danh mục có sẵn
    const category = await ServiceCategory.findOne({ isActive: true });
    const categoryId = category ? category._id : null;

    const demoRequest = await RepairRequest.create({
      customerId: req.user._id,
      assignedTechnicianId: technician._id,
      serviceCategoryId: categoryId || req.user._id,
      title: 'Sửa chữa điều hòa Panasonic bị chảy nước',
      description: 'Điều hòa phòng ngủ mở lên 15 phút thì bị rò nước xuống sàn, cần kiểm tra vệ sinh ống xả.',
      urgency: 'high',
      status: 'COMPLETED',
      isReviewed: false,
      contactPhone: req.user.phoneNumber || '0901234567',
      location: {
        address: '123 Đường 3/2, Ninh Kiều, Cần Thơ',
      },
    });

    const populated = await RepairRequest.findById(demoRequest._id)
      .populate('serviceCategoryId', 'name slug icon color basePrice')
      .populate('assignedTechnicianId', 'fullName email phoneNumber avatar rating reviewCount');

    return res.status(201).json({
      success: true,
      message: 'Đã tạo thành công đơn hàng hoàn tất mẫu (COMPLETED) để kiểm thử đánh giá',
      data: populated,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Lỗi khi tạo đơn hàng mẫu',
      error: error.message,
    });
  }
};

module.exports = {
  createRepairRequest,
  getMyRepairRequests,
  seedDemoCompletedRequest,
};
