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

module.exports = {
  createRepairRequest,
  getMyRepairRequests,
};
