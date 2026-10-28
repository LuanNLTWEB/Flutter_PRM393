const crypto = require('crypto');

const Quotation = require('../models/Quotation');
const RepairRequest = require('../models/RepairRequest');
const { createNotificationUtil } = require('./notificationController');

const DEFAULT_QR_TTL_MINUTES = 15;

const idsEqual = (left, right) =>
  left != null && right != null && left.toString() === right.toString();

const hashToken = (token) =>
  crypto.createHash('sha256').update(token).digest('hex');

const getQrTtlMinutes = () => {
  const configured = Number(process.env.COMPLETION_QR_TTL_MINUTES);
  return Number.isFinite(configured) && configured > 0
    ? configured
    : DEFAULT_QR_TTL_MINUTES;
};

const buildQrPayload = ({ requestId, amount, token }) =>
  `homefix://completion?requestId=${encodeURIComponent(requestId)}` +
  `&amount=${encodeURIComponent(amount)}` +
  `&token=${encodeURIComponent(token)}`;

const findAcceptedQuotation = (requestId) =>
  Quotation.findOne({ requestId, status: 'ACCEPTED' });

/**
 * @desc    Thợ tạo QR nghiệm thu chứa mã đơn, số tiền chốt và token dùng một lần (UC-CFM-02)
 * @route   POST /api/requests/:id/completion-qr
 * @access  Private (technician - thợ được gán)
 */
const generateCompletionQr = async (req, res) => {
  try {
    const request = await RepairRequest.findById(req.params.id);
    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy phiếu yêu cầu sửa chữa',
      });
    }

    if (request.status !== 'IN_PROGRESS') {
      return res.status(400).json({
        success: false,
        message: 'Chỉ có thể tạo QR nghiệm thu khi đơn đang sửa chữa',
      });
    }

    if (!request.completionImages || request.completionImages.length === 0) {
      return res.status(409).json({
        success: false,
        message: 'Cần tải ảnh sau khi sửa trước khi tạo QR nghiệm thu',
      });
    }

    const quotation = await findAcceptedQuotation(request._id);
    if (!quotation) {
      return res.status(409).json({
        success: false,
        message: 'Không tìm thấy báo giá đã chốt của đơn hàng',
      });
    }

    const assignedTechnicianId =
      request.assignedTechnicianId || quotation.technicianId;
    if (!idsEqual(assignedTechnicianId, req.user._id)) {
      return res.status(403).json({
        success: false,
        message: 'Bạn không phải thợ được gán cho đơn hàng này',
      });
    }

    if (!request.assignedTechnicianId) {
      request.assignedTechnicianId = quotation.technicianId;
    }

    const token = crypto.randomBytes(32).toString('base64url');
    const now = new Date();
    const expiresAt = new Date(
      now.getTime() + getQrTtlMinutes() * 60 * 1000
    );
    const amount = Number(quotation.total);

    request.completionQrTokenHash = hashToken(token);
    request.completionQrGeneratedAt = now;
    request.completionQrExpiresAt = expiresAt;
    await request.save();

    return res.status(200).json({
      success: true,
      message: 'Tạo mã QR nghiệm thu thành công',
      data: {
        confirmationQr: {
          requestId: request._id.toString(),
          amount,
          payload: buildQrPayload({
            requestId: request._id.toString(),
            amount,
            token,
          }),
          expiresAt,
        },
      },
    });
  } catch (error) {
    console.error('generateCompletionQr error:', error.message);
    if (error.name === 'CastError') {
      return res.status(400).json({
        success: false,
        message: 'Mã phiếu yêu cầu không hợp lệ',
      });
    }
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi tạo QR nghiệm thu',
      error: error.message,
    });
  }
};

/**
 * @desc    Khách quét QR và xác nhận đơn đã hoàn tất (UC-CFM-03)
 * @route   POST /api/requests/:id/confirm-completion
 * @access  Private (user - chủ đơn hàng)
 */
const confirmCompletion = async (req, res) => {
  try {
    const { token, amount } = req.body;
    if (typeof token !== 'string' || token.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'QR nghiệm thu không chứa token hợp lệ',
      });
    }

    const request = await RepairRequest.findById(req.params.id).select(
      '+completionQrTokenHash'
    );
    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy phiếu yêu cầu sửa chữa',
      });
    }

    if (!idsEqual(request.customerId, req.user._id)) {
      return res.status(403).json({
        success: false,
        message: 'Bạn không có quyền nghiệm thu đơn hàng này',
      });
    }

    if (request.status === 'COMPLETED') {
      return res.status(200).json({
        success: true,
        message: 'Đơn hàng đã được nghiệm thu trước đó',
        data: {
          requestId: request._id.toString(),
          status: request.status,
          completedAt: request.completedAt || request.completionConfirmedAt,
          alreadyConfirmed: true,
        },
      });
    }

    if (request.status !== 'IN_PROGRESS') {
      return res.status(400).json({
        success: false,
        message: 'Đơn hàng không ở trạng thái có thể nghiệm thu',
      });
    }

    if (!request.completionImages || request.completionImages.length === 0) {
      return res.status(409).json({
        success: false,
        message: 'Đơn hàng chưa có ảnh xác nhận sau khi sửa',
      });
    }

    if (!request.completionQrTokenHash || !request.completionQrExpiresAt) {
      return res.status(400).json({
        success: false,
        message: 'QR nghiệm thu chưa được tạo hoặc đã bị vô hiệu hóa',
      });
    }

    if (request.completionQrExpiresAt.getTime() <= Date.now()) {
      request.completionQrTokenHash = null;
      request.completionQrExpiresAt = null;
      await request.save();
      return res.status(410).json({
        success: false,
        message: 'QR nghiệm thu đã hết hạn, vui lòng yêu cầu thợ tạo mã mới',
      });
    }

    const providedHash = Buffer.from(hashToken(token.trim()), 'hex');
    const storedHash = Buffer.from(request.completionQrTokenHash, 'hex');
    if (
      providedHash.length !== storedHash.length ||
      !crypto.timingSafeEqual(providedHash, storedHash)
    ) {
      return res.status(400).json({
        success: false,
        message: 'QR nghiệm thu không hợp lệ hoặc đã được thay thế',
      });
    }

    const quotation = await findAcceptedQuotation(request._id);
    if (!quotation) {
      return res.status(409).json({
        success: false,
        message: 'Không tìm thấy báo giá đã chốt của đơn hàng',
      });
    }

    const scannedAmount = Number(amount);
    if (!Number.isFinite(scannedAmount) || scannedAmount !== Number(quotation.total)) {
      return res.status(400).json({
        success: false,
        message: 'Số tiền trong QR không khớp với báo giá đã chốt',
      });
    }

    const completedAt = new Date();
    request.status = 'COMPLETED';
    request.completedAt = completedAt;
    request.completionConfirmedAt = completedAt;
    request.completionConfirmedBy = req.user._id;
    request.completionQrTokenHash = null;
    request.completionQrExpiresAt = null;
    await request.save();

    await createNotificationUtil({
      recipient: request.assignedTechnicianId || quotation.technicianId,
      title: 'Khách đã nghiệm thu dịch vụ',
      message: `Khách hàng đã xác nhận hoàn tất yêu cầu "${request.title}".`,
      type: 'ORDER_STATUS',
      data: { requestId: request._id, status: 'COMPLETED' },
    });

    return res.status(200).json({
      success: true,
      message: 'Nghiệm thu thành công, đơn hàng đã hoàn tất',
      data: {
        requestId: request._id.toString(),
        status: request.status,
        completedAt,
        amount: Number(quotation.total),
        alreadyConfirmed: false,
      },
    });
  } catch (error) {
    console.error('confirmCompletion error:', error.message);
    if (error.name === 'CastError') {
      return res.status(400).json({
        success: false,
        message: 'Mã phiếu yêu cầu không hợp lệ',
      });
    }
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi xác nhận nghiệm thu',
      error: error.message,
    });
  }
};

module.exports = {
  generateCompletionQr,
  confirmCompletion,
};
