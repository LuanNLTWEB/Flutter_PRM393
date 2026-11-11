/**
 * Author: Lam Hoang Phuc (CE191132)
 * Use Cases: #UC-PAY-01, #UC-PAY-02, #UC-PAY-03, #UC-PAY-04, #UC-PAY-05
 * Description: Controller quản lý bảng kê chi phí, thanh toán tiền mặt, hóa đơn linh kiện, xác nhận thu tiền và xuất biên nhận điện tử
 */
const RepairRequest = require('../models/RepairRequest');
const Quotation = require('../models/Quotation');
const { uploadStream, deleteImage } = require('../config/cloudinary');
const { createNotificationUtil } = require('./notificationController');

const PAYMENT_METHODS = ['CASH'];

const isAssignedTechnician = (request, quotation, userId) => {
  const assigned = request.assignedTechnicianId || quotation?.technicianId;
  const assignedId = assigned?._id ? assigned._id : assigned;
  return assignedId && assignedId.toString() === userId.toString();
};

const getAuthorizedRequest = async (requestId, user) => {
  const request = await RepairRequest.findById(requestId)
    .populate('serviceCategoryId', 'name')
    .populate('assignedTechnicianId', 'fullName avatar phoneNumber')
    .populate('customerId', 'fullName phoneNumber email');

  if (!request) {
    return { error: { status: 404, message: 'Không tìm thấy phiếu yêu cầu sửa chữa' } };
  }

  const quotation = await Quotation.findOne({
    requestId: request._id,
    status: 'ACCEPTED',
  }).populate('technicianId', 'fullName avatar phoneNumber');

  const customerId = request.customerId?._id ? request.customerId._id : request.customerId;
  const isCustomer = customerId && customerId.toString() === user._id.toString();
  const isTech = isAssignedTechnician(request, quotation, user._id);
  const isAdminOrStaff = user.role === 'admin' || user.role === 'staff';

  if (!isCustomer && !isTech && !isAdminOrStaff) {
    return {
      error: {
        status: 403,
        message: 'Bạn không có quyền truy cập dữ liệu thanh toán của đơn này',
      },
    };
  }

  return { request, quotation, isCustomer, isTech };
};

const buildInvoice = (request, quotation) => ({
  requestId: request._id,
  quotationId: quotation ? quotation._id : null,
  serviceTitle: request.title,
  serviceCategoryName: request.serviceCategoryId?.name || 'Dịch vụ sửa chữa',
  technicianName:
    request.assignedTechnicianId?.fullName ||
    quotation?.technicianId?.fullName ||
    'Thợ sửa chữa',
  technicianAvatar:
    request.assignedTechnicianId?.avatar ||
    quotation?.technicianId?.avatar ||
    '',
  labourCost: quotation ? quotation.labourCost : 0,
  partsCost: quotation ? quotation.partsCost : 0,
  total: quotation ? quotation.total : 0,
  currency: 'VND',
  requestStatus: request.status,
  completionImages: request.completionImages || [],
  partsInvoiceImages: request.partsInvoiceImages || [],
  paymentMethod: request.paymentMethod || null,
  paymentMethodSelectedAt: request.paymentMethodSelectedAt || null,
  paymentStatus: request.paymentStatus || 'UNPAID',
  paidAt: request.paidAt || null,
});

const buildReceipt = (request, quotation) => {
  const paidDate = request.paidAt || request.completedAt || new Date();
  const warrantyDays = 30;
  const warrantyEndDate = new Date(paidDate.getTime() + warrantyDays * 24 * 60 * 60 * 1000);
  const now = new Date();
  const isWarrantyActive = now <= warrantyEndDate;

  const idSuffix = request._id.toString().slice(-8).toUpperCase();
  const receiptCode = `REC-${idSuffix}`;
  const warrantyCode = `WRT-${idSuffix}`;

  return {
    receiptCode,
    warrantyCode,
    issuedAt: paidDate,
    requestId: request._id,
    serviceTitle: request.title,
    serviceCategoryName: request.serviceCategoryId?.name || 'Dịch vụ sửa chữa',
    customer: {
      fullName: request.customerId?.fullName || 'Khách hàng',
      phoneNumber: request.customerId?.phoneNumber || '',
      email: request.customerId?.email || '',
      address: request.location?.address || request.address || 'Tại địa chỉ khách hàng',
    },
    technician: {
      fullName:
        request.assignedTechnicianId?.fullName ||
        quotation?.technicianId?.fullName ||
        'Thợ sửa chữa',
      phoneNumber:
        request.assignedTechnicianId?.phoneNumber ||
        quotation?.technicianId?.phoneNumber ||
        '',
      avatar:
        request.assignedTechnicianId?.avatar ||
        quotation?.technicianId?.avatar ||
        '',
    },
    financial: {
      labourCost: quotation ? quotation.labourCost : 0,
      partsCost: quotation ? quotation.partsCost : 0,
      totalAmount: quotation ? quotation.total : 0,
      currency: 'VND',
      paymentMethod: request.paymentMethod || 'CASH',
      paymentStatus: request.paymentStatus || 'UNPAID',
      paidAt: request.paidAt || null,
    },
    warranty: {
      durationDays: warrantyDays,
      startDate: paidDate,
      endDate: warrantyEndDate,
      status: isWarrantyActive ? 'ACTIVE' : 'EXPIRED',
      statusText: isWarrantyActive ? 'Còn hiệu lực bảo hành' : 'Hết hạn bảo hành',
      terms: [
        'Bảo hành 30 ngày cho các hạng mục công việc đã thực hiện và linh kiện thay thế đính kèm biên nhận.',
        'Miễn phí 100% công sửa lại tại nhà nếu sự cố tương tự phát sinh trong thời gian còn bảo hành.',
        'Phiếu biên nhận điện tử kiêm bảo hành có giá trị đối soát chính thức trên toàn hệ thống HomeFix.',
        'Không áp dụng bảo hành nếu thiết bị bị tác động ngoại lực, chập cháy do nguồn điện hoặc tự ý tháo dỡ bởi bên thứ ba.',
      ],
    },
    completionImages: request.completionImages || [],
    partsInvoiceImages: request.partsInvoiceImages || [],
  };
};

const hasCompletionEvidence = (request) =>
  request.status === 'COMPLETED' || (request.completionImages || []).length > 0;

/**
 * @desc    Xem hóa đơn chi tiết từ báo giá đã được chốt (UC-PAY-01)
 * @route   GET /api/payments/requests/:id/invoice
 * @access  Private (Khách hàng chủ đơn, Thợ được gán, Admin/Staff)
 */
const getInvoice = async (req, res) => {
  try {
    const result = await getAuthorizedRequest(req.params.id, req.user);
    if (result.error) {
      return res.status(result.error.status).json({
        success: false,
        message: result.error.message,
      });
    }

    const { request, quotation } = result;

    if (!quotation) {
      return res.status(404).json({
        success: false,
        message: 'Đơn hàng chưa có báo giá được chốt để lập hóa đơn',
      });
    }

    if (!hasCompletionEvidence(request)) {
      return res.status(409).json({
        success: false,
        message: 'Chưa thể xem hóa đơn: thợ chưa gửi ảnh sau khi sửa',
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Lấy hóa đơn thành công',
      data: { invoice: buildInvoice(request, quotation) },
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
 * @desc    Khách xác nhận thanh toán tiền mặt tại chỗ (UC-PAY-02)
 * @route   PUT /api/payments/requests/:id/method
 * @access  Private (Khách hàng chủ đơn)
 */
const selectPaymentMethod = async (req, res) => {
  try {
    const { paymentMethod = 'CASH' } = req.body;
    if (paymentMethod !== 'CASH') {
      return res.status(400).json({
        success: false,
        message: 'Hệ thống chỉ hỗ trợ thanh toán trực tiếp bằng tiền mặt tại chỗ',
      });
    }

    const result = await getAuthorizedRequest(req.params.id, req.user);
    if (result.error) {
      return res.status(result.error.status).json({
        success: false,
        message: result.error.message,
      });
    }

    if (!result.isCustomer) {
      return res.status(403).json({
        success: false,
        message: 'Chỉ khách hàng chủ đơn mới có quyền xác nhận thanh toán tiền mặt',
      });
    }

    const { request, quotation } = result;

    if (!quotation) {
      return res.status(404).json({
        success: false,
        message: 'Đơn hàng chưa có báo giá được chốt',
      });
    }

    if (request.status === 'CANCELLED') {
      return res.status(400).json({
        success: false,
        message: 'Không thể chọn thanh toán cho đơn hàng đã hủy',
      });
    }

    if (!hasCompletionEvidence(request)) {
      return res.status(409).json({
        success: false,
        message: 'Chưa thể xác nhận thanh toán: thợ chưa gửi ảnh sau khi sửa',
      });
    }

    request.paymentMethod = 'CASH';
    request.paymentMethodSelectedAt = new Date();
    await request.save();

    return res.status(200).json({
      success: true,
      message: 'Đã xác nhận thanh toán tiền mặt tại chỗ thành công',
      data: { invoice: buildInvoice(request, quotation) },
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
      message: 'Lỗi khi xác nhận thanh toán tiền mặt',
      error: error.message,
    });
  }
};

/**
 * @desc    Thợ đính kèm chứng từ / hóa đơn mua linh kiện thay thế (UC-PAY-03)
 * @route   POST /api/payments/requests/:id/parts-invoices
 * @access  Private (Thợ sửa chữa phụ trách đơn)
 */
const uploadPartsInvoiceImages = async (req, res) => {
  const uploadedPublicIds = [];
  try {
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng chọn ít nhất 1 ảnh hóa đơn / phiếu mua linh kiện',
      });
    }

    if (req.files.length > 5) {
      return res.status(400).json({
        success: false,
        message: 'Mỗi lần chỉ được tải lên tối đa 5 ảnh hóa đơn linh kiện',
      });
    }

    const result = await getAuthorizedRequest(req.params.id, req.user);
    if (result.error) {
      return res.status(result.error.status).json({
        success: false,
        message: result.error.message,
      });
    }

    if (!result.isTech) {
      return res.status(403).json({
        success: false,
        message: 'Chỉ thợ được phân công mới có quyền tải hóa đơn linh kiện',
      });
    }

    const { request, quotation } = result;

    if (request.status === 'CANCELLED') {
      return res.status(400).json({
        success: false,
        message: 'Không thể đính kèm hóa đơn linh kiện cho đơn đã bị hủy',
      });
    }

    if ((request.partsInvoiceImages || []).length + req.files.length > 5) {
      return res.status(400).json({
        success: false,
        message: 'Mỗi đơn hàng chỉ được lưu tối đa 5 ảnh hóa đơn linh kiện',
      });
    }

    const uploadedUrls = [];
    for (const file of req.files) {
      const uploadRes = await uploadStream(file.buffer, {
        folder: 'homefix/parts-invoices',
        transformation: [{ quality: 'auto', fetch_format: 'auto' }],
      });
      uploadedUrls.push(uploadRes.url);
      uploadedPublicIds.push(uploadRes.publicId);
    }

    if (!request.partsInvoiceImages) {
      request.partsInvoiceImages = [];
    }
    request.partsInvoiceImages.push(...uploadedUrls);
    await request.save();

    return res.status(200).json({
      success: true,
      message: 'Đã tải lên hóa đơn linh kiện thay thế thành công',
      data: {
        invoice: buildInvoice(request, quotation),
        partsInvoiceImages: request.partsInvoiceImages,
      },
    });
  } catch (error) {
    await Promise.all(
      uploadedPublicIds.map((publicId) => deleteImage(publicId).catch(() => {}))
    );
    console.error('uploadPartsInvoiceImages error:', error.message);
    if (error.name === 'CastError') {
      return res.status(400).json({
        success: false,
        message: 'Mã phiếu yêu cầu không hợp lệ',
      });
    }
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi tải ảnh hóa đơn linh kiện',
      error: error.message,
    });
  }
};

/**
 * @desc    Thợ xác nhận đã nhận đủ tiền mặt từ khách hàng (UC-PAY-04)
 * @route   PATCH /api/payments/requests/:id/confirm-payment
 * @access  Private (Thợ sửa chữa phụ trách đơn)
 */
const confirmPaymentReceived = async (req, res) => {
  try {
    const result = await getAuthorizedRequest(req.params.id, req.user);
    if (result.error) {
      return res.status(result.error.status).json({
        success: false,
        message: result.error.message,
      });
    }

    if (!result.isTech) {
      return res.status(403).json({
        success: false,
        message: 'Chỉ thợ phụ trách đơn mới có quyền xác nhận đã thu tiền',
      });
    }

    const { request, quotation } = result;

    if (request.status === 'CANCELLED') {
      return res.status(400).json({
        success: false,
        message: 'Đơn hàng đã bị hủy, không thể xác nhận thanh toán',
      });
    }

    if (request.paymentStatus === 'PAID') {
      return res.status(200).json({
        success: true,
        message: 'Đơn hàng đã được xác nhận thu tiền mặt trước đó',
        data: { invoice: buildInvoice(request, quotation) },
      });
    }

    const now = new Date();
    request.paymentStatus = 'PAID';
    request.paidAt = now;
    request.paymentReceivedBy = req.user._id;
    if (!request.paymentMethod) {
      request.paymentMethod = 'CASH';
      request.paymentMethodSelectedAt = now;
    }

    await request.save();

    // Bắn thông báo cho Khách hàng
    await createNotificationUtil({
      recipient: request.customerId,
      title: 'Thợ đã xác nhận thu tiền mặt',
      message: `Thợ ${req.user.fullName || 'kỹ thuật'} đã xác nhận nhận đủ tiền mặt cho yêu cầu "${request.title}". Cảm ơn bạn đã sử dụng HomeFix!`,
      type: 'ORDER_STATUS',
      data: {
        requestId: request._id,
        status: request.status,
        paymentStatus: 'PAID',
      },
    });

    return res.status(200).json({
      success: true,
      message: 'Đã xác nhận nhận đủ tiền mặt từ khách hàng thành công',
      data: { invoice: buildInvoice(request, quotation) },
    });
  } catch (error) {
    console.error('confirmPaymentReceived error:', error.message);
    if (error.name === 'CastError') {
      return res.status(400).json({
        success: false,
        message: 'Mã phiếu yêu cầu không hợp lệ',
      });
    }
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi xác nhận thanh toán tiền mặt',
      error: error.message,
    });
  }
};

/**
 * @desc    Xuất biên nhận thanh toán kiêm phiếu bảo hành dịch vụ điện tử (UC-PAY-05)
 * @route   GET /api/payments/requests/:id/receipt
 * @access  Private (Khách hàng chủ đơn, Thợ được gán, Admin/Staff)
 */
const getReceipt = async (req, res) => {
  try {
    const result = await getAuthorizedRequest(req.params.id, req.user);
    if (result.error) {
      return res.status(result.error.status).json({
        success: false,
        message: result.error.message,
      });
    }

    const { request, quotation } = result;

    if (!quotation) {
      return res.status(404).json({
        success: false,
        message: 'Đơn hàng chưa có báo giá được chốt để xuất biên nhận điện tử',
      });
    }

    if (!hasCompletionEvidence(request)) {
      return res.status(409).json({
        success: false,
        message: 'Chưa thể xuất biên nhận: thợ chưa gửi ảnh sau khi sửa',
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Lấy biên nhận thanh toán kiêm bảo hành điện tử thành công',
      data: {
        receipt: buildReceipt(request, quotation),
      },
    });
  } catch (error) {
    console.error('getReceipt error:', error.message);
    if (error.name === 'CastError') {
      return res.status(400).json({
        success: false,
        message: 'Mã phiếu yêu cầu không hợp lệ',
      });
    }
    return res.status(500).json({
      success: false,
      message: 'Lỗi khi lấy biên nhận điện tử',
      error: error.message,
    });
  }
};

module.exports = {
  getInvoice,
  selectPaymentMethod,
  uploadPartsInvoiceImages,
  confirmPaymentReceived,
  getReceipt,
};
