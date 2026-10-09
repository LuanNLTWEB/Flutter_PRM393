const Quotation = require('../models/Quotation');
const RepairRequest = require('../models/RepairRequest');

// Trường thông tin công khai của Thợ được phép trả về Khách hàng
const TECHNICIAN_PUBLIC_FIELDS =
  'fullName avatar technicianProfile.skills technicianProfile.experienceYears technicianProfile.rating technicianProfile.reviewCount technicianProfile.completedJobsCount technicianProfile.isAvailable';

const isNonNegativeNumber = (value) =>
  typeof value === 'number' && Number.isFinite(value) && value >= 0;

const populateTechnician = (query) =>
  query.populate('technicianId', TECHNICIAN_PUBLIC_FIELDS);

/**
 * @desc    Thợ gửi báo giá cho phiếu yêu cầu (UC-QUO-04)
 * @route   POST /api/quotations
 * @access  Private (technician)
 */
const sendQuotation = async (req, res) => {
  try {
    const { requestId, labourCost, partsCost = 0, note = '' } = req.body;

    if (!requestId) {
      return res.status(400).json({
        success: false,
        message: 'Thiếu mã phiếu yêu cầu',
      });
    }

    if (!isNonNegativeNumber(labourCost) || !isNonNegativeNumber(partsCost)) {
      return res.status(400).json({
        success: false,
        message: 'Tiền công và giá linh kiện phải là số không âm',
      });
    }

    const request = await RepairRequest.findById(requestId);
    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Phiếu yêu cầu không tồn tại',
      });
    }

    if (request.status === 'ACCEPTED') {
      return res.status(400).json({
        success: false,
        message: 'Yêu cầu này đã được chốt thợ, không thể báo giá',
      });
    }

    if (request.status === 'CANCELLED') {
      return res.status(400).json({
        success: false,
        message: 'Yêu cầu này đã bị hủy',
      });
    }

    // Một thợ chỉ có 1 báo giá cho 1 yêu cầu (unique index)
    const existing = await Quotation.findOne({
      requestId: request._id,
      technicianId: req.user._id,
    });

    let quotation;

    if (existing && existing.status === 'RETRACTED') {
      // Thợ gửi lại báo giá sau khi đã thu hồi
      existing.labourCost = labourCost;
      existing.partsCost = partsCost;
      existing.note = (note || '').trim();
      existing.status = 'SENT';
      existing.resolvedAt = null;
      quotation = await existing.save();
    } else if (existing) {
      return res.status(409).json({
        success: false,
        message: 'Bạn đã gửi báo giá cho yêu cầu này rồi',
      });
    } else {
      quotation = await Quotation.create({
        requestId: request._id,
        technicianId: req.user._id,
        labourCost,
        partsCost,
        note: (note || '').trim(),
      });
    }

    // Yêu cầu chuyển sang trạng thái đã có báo giá
    if (request.status === 'OPEN') {
      request.status = 'QUOTED';
      await request.save();
    }

    const populated = await populateTechnician(
      Quotation.findById(quotation._id)
    ).lean();

    return res.status(201).json({
      success: true,
      message: 'Gửi báo giá thành công',
      data: { quotation: populated },
    });
  } catch (error) {
    console.error('sendQuotation error:', error.message);

    if (error.code === 11000) {
      return res.status(409).json({
        success: false,
        message: 'Bạn đã gửi báo giá cho yêu cầu này rồi',
      });
    }

    if (error.name === 'ValidationError') {
      const messages = Object.values(error.errors).map((e) => e.message);
      return res.status(400).json({
        success: false,
        message: messages.join('. '),
      });
    }

    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi gửi báo giá',
      error: error.message,
    });
  }
};

/**
 * @desc    Xem danh sách báo giá của 1 yêu cầu (UC-QUO-06)
 *          - Khách hàng: xem toàn bộ báo giá của yêu cầu mình tạo
 *          - Thợ: chỉ xem được báo giá của chính mình (không lộ giá thợ khác)
 * @route   GET /api/quotations?requestId=...
 * @access  Private (user, technician)
 */
const getQuotationsByRequest = async (req, res) => {
  try {
    const { requestId } = req.query;

    if (!requestId) {
      return res.status(400).json({
        success: false,
        message: 'Thiếu mã phiếu yêu cầu',
      });
    }

    const request = await RepairRequest.findById(requestId);
    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Phiếu yêu cầu không tồn tại',
      });
    }

    const filter = { requestId: request._id };

    if (req.user.role === 'user') {
      // Khách chỉ xem được báo giá của yêu cầu mình tạo
      if (request.customerId.toString() !== req.user._id.toString()) {
        return res.status(403).json({
          success: false,
          message: 'Bạn không có quyền xem báo giá của yêu cầu này',
        });
      }
    } else if (req.user.role === 'technician') {
      // Thợ chỉ thấy báo giá của mình
      filter.technicianId = req.user._id;
    }

    const quotations = await populateTechnician(
      Quotation.find(filter).sort({ createdAt: 1 })
    ).lean();

    return res.status(200).json({
      success: true,
      message: 'Lấy danh sách báo giá thành công',
      data: {
        total: quotations.length,
        requestStatus: request.status,
        quotations,
      },
    });
  } catch (error) {
    console.error('getQuotationsByRequest error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi lấy danh sách báo giá',
      error: error.message,
    });
  }
};

/**
 * @desc    Thợ chỉnh sửa báo giá đã gửi (UC-QUO-05)
 * @route   PUT /api/quotations/:id
 * @access  Private (technician - chủ báo giá)
 */
const updateQuotation = async (req, res) => {
  try {
    const { labourCost, partsCost = 0, note = '' } = req.body;

    if (!isNonNegativeNumber(labourCost) || !isNonNegativeNumber(partsCost)) {
      return res.status(400).json({
        success: false,
        message: 'Tiền công và giá linh kiện phải là số không âm',
      });
    }

    const quotation = await Quotation.findById(req.params.id);
    if (!quotation) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy báo giá',
      });
    }

    if (quotation.technicianId.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Bạn không có quyền chỉnh sửa báo giá này',
      });
    }

    if (quotation.status !== 'SENT') {
      return res.status(400).json({
        success: false,
        message: 'Chỉ chỉnh sửa được báo giá chưa bị chốt hoặc từ chối',
      });
    }

    const request = await RepairRequest.findById(quotation.requestId);
    if (!request || request.status === 'ACCEPTED' || request.status === 'CANCELLED') {
      return res.status(400).json({
        success: false,
        message: 'Yêu cầu đã được chốt hoặc hủy, không thể chỉnh sửa báo giá',
      });
    }

    quotation.labourCost = labourCost;
    quotation.partsCost = partsCost;
    quotation.note = (note || '').trim();
    await quotation.save();

    const populated = await populateTechnician(
      Quotation.findById(quotation._id)
    ).lean();

    return res.status(200).json({
      success: true,
      message: 'Cập nhật báo giá thành công',
      data: { quotation: populated },
    });
  } catch (error) {
    console.error('updateQuotation error:', error.message);

    if (error.name === 'ValidationError') {
      const messages = Object.values(error.errors).map((e) => e.message);
      return res.status(400).json({
        success: false,
        message: messages.join('. '),
      });
    }

    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi cập nhật báo giá',
      error: error.message,
    });
  }
};

/**
 * @desc    Thợ thu hồi báo giá đã gửi (UC-QUO-05)
 *          Nếu không còn báo giá nào đang mở thì yêu cầu quay lại OPEN
 * @route   PATCH /api/quotations/:id/retract
 * @access  Private (technician - chủ báo giá)
 */
const retractQuotation = async (req, res) => {
  try {
    const quotation = await Quotation.findById(req.params.id);
    if (!quotation) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy báo giá',
      });
    }

    if (quotation.technicianId.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Bạn không có quyền thu hồi báo giá này',
      });
    }

    if (quotation.status !== 'SENT') {
      return res.status(400).json({
        success: false,
        message: 'Chỉ thu hồi được báo giá đang ở trạng thái đã gửi',
      });
    }

    quotation.status = 'RETRACTED';
    quotation.resolvedAt = new Date();
    await quotation.save();

    // Giải phóng yêu cầu nếu không còn báo giá nào đang mở
    const remaining = await Quotation.countDocuments({
      requestId: quotation.requestId,
      status: 'SENT',
    });

    const request = await RepairRequest.findById(quotation.requestId);
    if (request && remaining === 0 && request.status === 'QUOTED') {
      request.status = 'OPEN';
      await request.save();
    }

    return res.status(200).json({
      success: true,
      message: 'Thu hồi báo giá thành công',
      data: { quotationId: quotation._id, remainingQuotes: remaining },
    });
  } catch (error) {
    console.error('retractQuotation error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi thu hồi báo giá',
      error: error.message,
    });
  }
};

/**
 * @desc    Khách hàng chấp nhận 1 báo giá, chốt thợ (UC-QUO-08)
 *          Báo giá còn lại bị từ chối tự động, yêu cầu chuyển sang ACCEPTED
 * @route   POST /api/quotations/:id/accept
 * @access  Private (user - chủ yêu cầu)
 */
const acceptQuotation = async (req, res) => {
  try {
    const quotation = await Quotation.findById(req.params.id);
    if (!quotation) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy báo giá',
      });
    }

    const request = await RepairRequest.findById(quotation.requestId);
    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Phiếu yêu cầu không tồn tại',
      });
    }

    if (request.customerId.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Bạn không có quyền chốt báo giá của yêu cầu này',
      });
    }

    if (request.status === 'ACCEPTED') {
      return res.status(400).json({
        success: false,
        message: 'Yêu cầu này đã được chốt thợ trước đó',
      });
    }

    if (request.status === 'CANCELLED') {
      return res.status(400).json({
        success: false,
        message: 'Yêu cầu này đã bị hủy',
      });
    }

    if (quotation.status !== 'SENT') {
      return res.status(400).json({
        success: false,
        message: 'Báo giá này không còn ở trạng thái có thể chấp nhận',
      });
    }

    const now = new Date();

    quotation.status = 'ACCEPTED';
    quotation.resolvedAt = now;
    await quotation.save();

    // Các báo giá khác chuyển sang bị từ chối
    await Quotation.updateMany(
      {
        requestId: quotation.requestId,
        _id: { $ne: quotation._id },
        status: 'SENT',
      },
      { $set: { status: 'REJECTED', resolvedAt: now } }
    );

    request.status = 'ACCEPTED';
    await request.save();

    const populated = await populateTechnician(
      Quotation.findById(quotation._id)
    ).lean();

    return res.status(200).json({
      success: true,
      message: 'Chấp nhận báo giá thành công, đã chốt thợ',
      data: { quotation: populated, requestId: request._id },
    });
  } catch (error) {
    console.error('acceptQuotation error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi chấp nhận báo giá',
      error: error.message,
    });
  }
};

/**
 * @desc    Khách hàng từ chối 1 báo giá (UC-QUO-09)
 *          Nếu không còn báo giá nào đang mở thì giải phóng yêu cầu (OPEN)
 * @route   POST /api/quotations/:id/reject
 * @access  Private (user - chủ yêu cầu)
 */
const rejectQuotation = async (req, res) => {
  try {
    const quotation = await Quotation.findById(req.params.id);
    if (!quotation) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy báo giá',
      });
    }

    const request = await RepairRequest.findById(quotation.requestId);
    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Phiếu yêu cầu không tồn tại',
      });
    }

    if (request.customerId.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Bạn không có quyền từ chối báo giá của yêu cầu này',
      });
    }

    if (quotation.status !== 'SENT') {
      return res.status(400).json({
        success: false,
        message: 'Báo giá này không còn ở trạng thái có thể từ chối',
      });
    }

    quotation.status = 'REJECTED';
    quotation.resolvedAt = new Date();
    await quotation.save();

    // Giải phóng yêu cầu khi không còn báo giá nào đang mở
    const remaining = await Quotation.countDocuments({
      requestId: quotation.requestId,
      status: 'SENT',
    });

    if (remaining === 0 && request.status === 'QUOTED') {
      request.status = 'OPEN';
      await request.save();
    }

    return res.status(200).json({
      success: true,
      message: 'Từ chối báo giá thành công',
      data: { quotationId: quotation._id, requestStatus: request.status },
    });
  } catch (error) {
    console.error('rejectQuotation error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi từ chối báo giá',
      error: error.message,
    });
  }
};

/**
 * @desc    Thợ xem danh sách "Yêu cầu đã báo giá" của chính mình (UC-QUO-05)
 *          Mỗi báo giá kèm thông tin phiếu yêu cầu (đã populate)
 *          Che SĐT/địa chỉ đến khi báo giá được chấp nhận
 * @route   GET /api/quotations/my-quotes
 * @access  Private (technician)
 */
const getMyQuotations = async (req, res) => {
  try {
    const quotations = await Quotation.find({ technicianId: req.user._id })
      .sort({ createdAt: -1 })
      .limit(200)
      .populate(
        'requestId',
        'title description urgency status images location contactPhone serviceCategoryId createdAt updatedAt'
      )
      .lean();

    const items = quotations
      .filter((q) => q.requestId && q.requestId._id)
      .map((q) => {
        const request = q.requestId;
        const isWinner = q.status === 'ACCEPTED';
        if (!isWinner) {
          request.contactPhone = '';
          if (request.location) {
            request.location = {
              ...request.location,
              address: '',
              latitude: null,
              longitude: null,
            };
          }
        }
        return q;
      });

    return res.status(200).json({
      success: true,
      message: 'Lấy danh sách yêu cầu đã báo giá thành công',
      data: {
        total: items.length,
        quotations: items,
      },
    });
  } catch (error) {
    console.error('getMyQuotations error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi lấy danh sách báo giá đã gửi',
      error: error.message,
    });
  }
};

module.exports = {
  sendQuotation,
  getQuotationsByRequest,
  getMyQuotations,
  updateQuotation,
  retractQuotation,
  acceptQuotation,
  rejectQuotation,
};
