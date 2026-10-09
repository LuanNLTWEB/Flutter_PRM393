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

module.exports = {
  createRepairRequest,
};
