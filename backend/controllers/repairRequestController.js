const RepairRequest = require('../models/RepairRequest');
const ServiceCategory = require('../models/ServiceCategory');

// Cấu hình lịch hẹn: khung giờ thợ đến nhà (08:00 - 17:00), hẹn trước tối đa 14 ngày
const SCHEDULE_START_HOUR = 8;
const SCHEDULE_END_HOUR = 17;
const SCHEDULE_MAX_DAYS_AHEAD = 14;

// Kiểm tra thời gian hẹn (preferredTime) có hợp lệ là một khung giờ được phép không
const validatePreferredTime = (preferredTime) => {
  if (preferredTime === undefined || preferredTime === null || preferredTime === '') {
    return { isValid: true, value: null };
  }

  const scheduledAt = new Date(preferredTime);
  if (Number.isNaN(scheduledAt.getTime())) {
    return { isValid: false, message: 'Thời gian hẹn không hợp lệ' };
  }

  if (scheduledAt.getTime() <= Date.now()) {
    return { isValid: false, message: 'Thời gian hẹn phải ở trong tương lai' };
  }

  if (scheduledAt.getHours() < SCHEDULE_START_HOUR || scheduledAt.getHours() > SCHEDULE_END_HOUR) {
    return {
      isValid: false,
      message: `Khung giờ hẹn phải nằm trong khoảng ${SCHEDULE_START_HOUR}:00 - ${SCHEDULE_END_HOUR}:59`,
    };
  }

  const maxDate = new Date();
  maxDate.setDate(maxDate.getDate() + SCHEDULE_MAX_DAYS_AHEAD);
  if (scheduledAt.getTime() > maxDate.getTime()) {
    return { isValid: false, message: `Chỉ có thể hẹn trước tối đa ${SCHEDULE_MAX_DAYS_AHEAD} ngày` };
  }

  return { isValid: true, value: scheduledAt };
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

    // Validate khung giờ hẹn thợ đến nhà
    const scheduleCheck = validatePreferredTime(preferredTime);
    if (!scheduleCheck.isValid) {
      return res.status(400).json({
        success: false,
        message: scheduleCheck.message,
      });
    }

    const newRequest = await RepairRequest.create({
      customerId: req.user._id,
      serviceCategoryId,
      title: reqTitle,
      description: reqDesc,
      urgency: normalizedUrgency,
      preferredTime: scheduleCheck.value,
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
