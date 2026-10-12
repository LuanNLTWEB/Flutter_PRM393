const RepairRequest = require('../models/RepairRequest');
const Quotation = require('../models/Quotation');

const PAYMENT_METHODS = ['CASH', 'BANK_TRANSFER'];

const getOwnerRequest = async (requestId, userId) => {
  const request = await RepairRequest.findById(requestId)
    .populate('serviceCategoryId', 'name')
    .populate('assignedTechnicianId', 'fullName avatar');

  if (!request) return { error: { status: 404, message: 'Không tìm thấy phiếu yêu cầu sửa chữa' } };

  if (request.customerId.toString() !== userId.toString()) {
    return { error: { status: 403, message: 'Bạn không có quyền xem dữ liệu thanh toán của đơn này' } };
  }

  return { request };
};

const buildInvoice = (request, quotation) => ({
  requestId: request._id,
  quotationId: quotation._id,
  serviceTitle: request.title,
  serviceCategoryName: request.serviceCategoryId?.name || 'Dịch vụ sửa chữa',
  technicianName: request.assignedTechnicianId?.fullName || quotation.technicianId?.fullName || 'Thợ sửa chữa',
  technicianAvatar: request.assignedTechnicianId?.avatar || quotation.technicianId?.avatar || '',
  labourCost: quotation.labourCost,
  partsCost: quotation.partsCost,
  total: quotation.total,
  currency: 'VND',
  requestStatus: request.status,
  completionImages: request.completionImages || [],
  paymentMethod: request.paymentMethod,
  paymentMethodSelectedAt: request.paymentMethodSelectedAt,
  paymentStatus: 'UNPAID',
});

const findAcceptedQuotation = async (requestId) =>
  Quotation.findOne({ requestId, status: 'ACCEPTED' }).populate(
    'technicianId',
    'fullName avatar'
  );

const hasCompletionEvidence = (request) =>
  request.status === 'COMPLETED' || (request.completionImages || []).length > 0;

/**
 * @desc    Xem hóa đơn chi tiết từ báo giá đã được chốt (UC-PAY-01)
 * @route   GET /api/payments/requests/:id/invoice
 */
const getInvoice = async (req, res) => {
  try {
    const result = await getOwnerRequest(req.params.id, req.user._id);
    if (result.error) {
      return res.status(result.error.status).json({
        success: false,
        message: result.error.message,
      });
    }

    const quotation = await findAcceptedQuotation(result.request._id);
    if (!quotation) {
      return res.status(404).json({
        success: false,
        message: 'Đơn hàng chưa có báo giá được chốt để lập hóa đơn',
      });
    }

    if (!hasCompletionEvidence(result.request)) {
      return res.status(409).json({
        success: false,
        message: 'Chưa thể xem hóa đơn: thợ chưa gửi ảnh sau khi sửa',
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Lấy hóa đơn thành công',
      data: { invoice: buildInvoice(result.request, quotation) },
    });
  } catch (error) {
    console.error('getInvoice error:', error.message);
    if (error.name === 'CastError') {
      return res.status(400).json({
        success: false,
        message: 'Mã phiếu yêu cầu không hợp lệ',
      });
    }
    return res.status(500).json({
      success: false,
      message: 'Lỗi khi lấy hóa đơn',
      error: error.message,
    });
  }
};

/**
 * @desc    Khách chọn phương thức thanh toán (UC-PAY-02)
 * @route   PUT /api/payments/requests/:id/method
 */
const selectPaymentMethod = async (req, res) => {
  try {
    const { paymentMethod } = req.body;
    if (!PAYMENT_METHODS.includes(paymentMethod)) {
      return res.status(400).json({
        success: false,
        message: 'Phương thức thanh toán không hợp lệ',
      });
    }

    const result = await getOwnerRequest(req.params.id, req.user._id);
    if (result.error) {
      return res.status(result.error.status).json({
        success: false,
        message: result.error.message,
      });
    }

    const quotation = await findAcceptedQuotation(result.request._id);
    if (!quotation) {
      return res.status(404).json({
        success: false,
        message: 'Đơn hàng chưa có báo giá được chốt',
      });
    }

    if (result.request.status === 'CANCELLED') {
      return res.status(400).json({
        success: false,
        message: 'Không thể chọn phương thức thanh toán cho đơn đã hủy',
      });
    }

    if (!hasCompletionEvidence(result.request)) {
      return res.status(409).json({
        success: false,
        message: 'Chưa thể chọn phương thức: thợ chưa gửi ảnh sau khi sửa',
      });
    }

    result.request.paymentMethod = paymentMethod;
    result.request.paymentMethodSelectedAt = new Date();
    await result.request.save();

    return res.status(200).json({
      success: true,
      message: 'Đã lưu phương thức thanh toán',
      data: { invoice: buildInvoice(result.request, quotation) },
    });
  } catch (error) {
    console.error('selectPaymentMethod error:', error.message);
    if (error.name === 'CastError') {
      return res.status(400).json({
        success: false,
        message: 'Mã phiếu yêu cầu không hợp lệ',
      });
    }
    return res.status(500).json({
      success: false,
      message: 'Lỗi khi lưu phương thức thanh toán',
      error: error.message,
    });
  }
};

module.exports = {
  getInvoice,
  selectPaymentMethod,
};
