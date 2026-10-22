const mongoose = require('mongoose');
const Complaint = require('../models/Complaint');
const RepairRequest = require('../models/RepairRequest');
const { createNotificationUtil } = require('./notificationController');

const activeStatuses = ['RECEIVED', 'IN_REVIEW'];
const validStatuses = [...activeStatuses, 'RESOLVED', 'REJECTED'];
const validCategories = [
  'SERVICE_QUALITY',
  'PRICING',
  'BEHAVIOR',
  'PAYMENT',
  'OTHER',
];

const populateComplaint = (query) =>
  query
    .populate('requestId', 'title status location.address')
    .populate('reporterId', 'fullName role phoneNumber')
    .populate('respondentId', 'fullName role phoneNumber')
    .populate('handledBy', 'fullName role');

/**
 * @desc    Khách/Thợ gửi một báo cáo tranh chấp cho đơn có cả hai bên tham gia
 * @route   POST /api/complaints
 * @access  Private (Customer, Technician)
 */
const createComplaint = async (req, res) => {
  try {
    const { requestId, category = 'OTHER', subject, description, evidenceUrls = [] } = req.body;

    if (!mongoose.isValidObjectId(requestId)) {
      return res.status(400).json({ success: false, message: 'Mã đơn hàng không hợp lệ' });
    }
    if (!validCategories.includes(category)) {
      return res.status(400).json({ success: false, message: 'Nhóm khiếu nại không hợp lệ' });
    }

    const repairRequest = await RepairRequest.findById(requestId).select(
      'customerId assignedTechnicianId status title'
    );
    if (!repairRequest) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy đơn hàng' });
    }
    if (!repairRequest.assignedTechnicianId) {
      return res.status(400).json({
        success: false,
        message: 'Chỉ có thể khiếu nại khi đơn hàng đã được chốt thợ',
      });
    }

    const userId = req.user._id.toString();
    const isCustomer = repairRequest.customerId.toString() === userId;
    const isTechnician = repairRequest.assignedTechnicianId.toString() === userId;
    if (!isCustomer && !isTechnician) {
      return res.status(403).json({
        success: false,
        message: 'Bạn không phải là một bên tham gia đơn hàng này',
      });
    }

    const existing = await Complaint.findOne({
      requestId,
      reporterId: req.user._id,
      status: { $in: activeStatuses },
    });
    if (existing) {
      return res.status(409).json({
        success: false,
        message: 'Bạn đã có một khiếu nại đang được xử lý cho đơn hàng này',
      });
    }

    const complaint = await Complaint.create({
      requestId,
      reporterId: req.user._id,
      respondentId: isCustomer
        ? repairRequest.assignedTechnicianId
        : repairRequest.customerId,
      category,
      subject: (subject || '').trim(),
      description: (description || '').trim(),
      evidenceUrls: Array.isArray(evidenceUrls) ? evidenceUrls.slice(0, 5) : [],
    });

    const populated = await populateComplaint(Complaint.findById(complaint._id));
    return res.status(201).json({
      success: true,
      message: 'Khiếu nại đã được tiếp nhận và chuyển đến bộ phận vận hành',
      data: { complaint: populated },
    });
  } catch (error) {
    console.error('createComplaint error:', error.message);
    if (error.name === 'ValidationError') {
      const message = Object.values(error.errors)
        .map((item) => item.message)
        .join('. ');
      return res.status(400).json({ success: false, message });
    }
    return res.status(500).json({
      success: false,
      message: 'Không thể tiếp nhận khiếu nại',
      error: error.message,
    });
  }
};

/**
 * @desc    Staff/Admin xem hàng đợi tranh chấp, có thể lọc theo trạng thái
 * @route   GET /api/complaints/manage?status=RECEIVED
 * @access  Private (Staff, Admin)
 */
const getComplaintsForManage = async (req, res) => {
  try {
    const { status } = req.query;
    const filter = {};
    if (status && status !== 'ALL') {
      if (!validStatuses.includes(status)) {
        return res.status(400).json({ success: false, message: 'Trạng thái lọc không hợp lệ' });
      }
      filter.status = status;
    }

    const [complaints, counts] = await Promise.all([
      populateComplaint(Complaint.find(filter).sort({ createdAt: -1 })),
      Complaint.aggregate([
        { $group: { _id: '$status', count: { $sum: 1 } } },
      ]),
    ]);

    const statusCounts = validStatuses.reduce(
      (result, item) => ({ ...result, [item]: 0 }),
      {}
    );
    counts.forEach((item) => {
      statusCounts[item._id] = item.count;
    });

    return res.status(200).json({
      success: true,
      message: 'Lấy danh sách khiếu nại thành công',
      data: { complaints, counts: statusCounts },
    });
  } catch (error) {
    console.error('getComplaintsForManage error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Không thể lấy danh sách khiếu nại',
      error: error.message,
    });
  }
};

/**
 * @desc    Staff/Admin ghi biên bản và cập nhật kết quả xử lý khiếu nại
 * @route   PATCH /api/complaints/:id/handle
 * @access  Private (Staff, Admin)
 */
const handleComplaint = async (req, res) => {
  try {
    const { status, staffNote = '' } = req.body;
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ success: false, message: 'Trạng thái xử lý không hợp lệ' });
    }
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({ success: false, message: 'Mã khiếu nại không hợp lệ' });
    }

    const complaint = await Complaint.findById(req.params.id);
    if (!complaint) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy khiếu nại' });
    }
    if (['RESOLVED', 'REJECTED'].includes(complaint.status)) {
      return res.status(409).json({
        success: false,
        message: 'Khiếu nại đã có kết quả cuối cùng và không thể cập nhật lại',
      });
    }

    const normalizedNote = staffNote.trim();
    if (['RESOLVED', 'REJECTED'].includes(status) && normalizedNote.length < 10) {
      return res.status(400).json({
        success: false,
        message: 'Cần ghi biên bản ít nhất 10 ký tự trước khi kết thúc xử lý',
      });
    }

    complaint.status = status;
    if (normalizedNote) complaint.staffNote = normalizedNote;
    complaint.handledBy = req.user._id;
    if (['RESOLVED', 'REJECTED'].includes(status)) {
      complaint.handledAt = new Date();
    }
    await complaint.save();

    const populated = await populateComplaint(Complaint.findById(complaint._id));
    const statusLabel = {
      IN_REVIEW: 'đang được xử lý',
      RESOLVED: 'đã được giải quyết',
      REJECTED: 'đã được từ chối',
    }[status];
    await createNotificationUtil({
      recipient: complaint.reporterId,
      title: 'Cập nhật khiếu nại',
      message: `Khiếu nại "${complaint.subject}" ${statusLabel}.`,
      type: 'SYSTEM',
      data: { complaintId: complaint._id, requestId: complaint.requestId, status },
    });

    return res.status(200).json({
      success: true,
      message: 'Đã cập nhật hồ sơ khiếu nại',
      data: { complaint: populated },
    });
  } catch (error) {
    console.error('handleComplaint error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Không thể cập nhật khiếu nại',
      error: error.message,
    });
  }
};

module.exports = {
  createComplaint,
  getComplaintsForManage,
  handleComplaint,
};
