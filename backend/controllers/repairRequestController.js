const RepairRequest = require('../models/RepairRequest');
const ServiceCategory = require('../models/ServiceCategory');
const Quotation = require('../models/Quotation');
const { uploadStream } = require('../config/cloudinary');
const { createNotificationUtil } = require('./notificationController');

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
    if (req.user && req.user.role !== 'user') {
      let roleLabel = 'nội bộ';
      if (req.user.role === 'technician') roleLabel = 'Kỹ thuật viên (Thợ)';
      else if (req.user.role === 'staff') roleLabel = 'Nhân viên vận hành (Staff)';
      else if (req.user.role === 'admin') roleLabel = 'Quản trị viên (Admin)';

      return res.status(403).json({
        success: false,
        message: `Tài khoản ${roleLabel} không thể tạo yêu cầu sửa chữa. Tính năng này chỉ dành riêng cho Khách hàng.`,
      });
    }

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

    let imageUrls = [];
    if (req.files && req.files.length > 0) {
      const uploadPromises = req.files.map((file) =>
        uploadStream(file.buffer, {
          folder: 'homefix/repair_requests',
        })
      );
      const results = await Promise.all(uploadPromises);
      imageUrls = results.map((res) => res.url);
    } else if (req.body.images) {
      if (Array.isArray(req.body.images)) {
        imageUrls = req.body.images;
      } else if (typeof req.body.images === 'string') {
        try {
          const parsed = JSON.parse(req.body.images);
          if (Array.isArray(parsed)) {
            imageUrls = parsed;
          } else {
            imageUrls = [req.body.images];
          }
        } catch (_) {
          imageUrls = [req.body.images];
        }
      }
    }

    let locationData = {
      address: 'Chưa cập nhật địa chỉ',
      latitude: null,
      longitude: null,
    };

    if (req.body.location) {
      if (typeof req.body.location === 'string') {
        try {
          const parsed = JSON.parse(req.body.location);
          locationData = {
            address: (parsed.address || '').trim() || 'Chưa cập nhật địa chỉ',
            latitude: parsed.latitude != null ? Number(parsed.latitude) : null,
            longitude: parsed.longitude != null ? Number(parsed.longitude) : null,
          };
        } catch (_) {
          locationData.address = req.body.location.trim();
        }
      } else if (typeof req.body.location === 'object') {
        locationData = {
          address: (req.body.location.address || '').trim() || 'Chưa cập nhật địa chỉ',
          latitude: req.body.location.latitude != null ? Number(req.body.location.latitude) : null,
          longitude: req.body.location.longitude != null ? Number(req.body.location.longitude) : null,
        };
      }
    } else if (req.body.address) {
      locationData.address = req.body.address.trim();
      if (req.body.latitude != null) locationData.latitude = Number(req.body.latitude);
      if (req.body.longitude != null) locationData.longitude = Number(req.body.longitude);
    }

    const newRequest = await RepairRequest.create({
      customerId: req.user._id,
      serviceCategoryId,
      title: reqTitle,
      description: reqDesc,
      images: imageUrls,
      urgency: normalizedUrgency,
      preferredTime: parsedPreferredTime,
      location: locationData,
      status: 'OPEN',
      contactPhone: (req.body.contactPhone || '').trim() || req.user.phoneNumber || '',
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
      statusFilter = { status: { $in: ['OPEN', 'QUOTED', 'ACCEPTED', 'ON_THE_WAY', 'IN_PROGRESS'] } };
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
        status: { $in: ['OPEN', 'QUOTED', 'ACCEPTED', 'ON_THE_WAY', 'IN_PROGRESS'] },
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

// Hàm xác định Thợ đã được chốt cho 1 phiếu yêu cầu (thắng báo giá hoặc assignedTechnicianId)
const isAssignedTechnician = async (request, technicianId) => {
  if (
    request.assignedTechnicianId &&
    request.assignedTechnicianId.toString() === technicianId.toString()
  ) {
    return true;
  }
  const won = await Quotation.findOne({
    requestId: request._id,
    technicianId,
    status: 'ACCEPTED',
  });
  return Boolean(won);
};

/**
 * @desc    Thợ xác nhận giờ hẹn do khách đề xuất (UC-LIC-01)
 *          Chuyển appointmentStatus sang CONFIRMED
 * @route   PATCH /api/requests/:id/appointment/confirm
 * @access  Private (technician - thợ được chốt)
 */
const confirmAppointment = async (req, res) => {
  try {
    const { id } = req.params;

    const request = await RepairRequest.findById(id);
    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy phiếu yêu cầu',
      });
    }

    if (request.status !== 'ACCEPTED' && request.status !== 'IN_PROGRESS') {
      return res.status(400).json({
        success: false,
        message: 'Chỉ có thể xác nhận lịch hẹn khi yêu cầu đã được chốt thợ',
      });
    }

    if (!(await isAssignedTechnician(request, req.user._id))) {
      return res.status(403).json({
        success: false,
        message: 'Bạn không phải thợ được chốt cho yêu cầu này',
      });
    }

    if (request.appointmentStatus === 'CONFIRMED') {
      return res.status(400).json({
        success: false,
        message: 'Lịch hẹn đã được xác nhận trước đó',
      });
    }

    if (request.appointmentStatus === 'RESCHEDULED') {
      return res.status(400).json({
        success: false,
        message:
          'Bạn đã đề xuất khung giờ mới, đang chờ khách phản hồi. Không thể xác nhận giờ hẹn lúc này',
      });
    }

    if (!request.preferredTime) {
      return res.status(400).json({
        success: false,
        message: 'Yêu cầu chưa có giờ hẹn để xác nhận',
      });
    }

    request.appointmentStatus = 'CONFIRMED';
    request.appointmentConfirmedAt = new Date();
    request.proposedTime = null;
    request.rescheduleNote = '';
    await request.save();

    return res.status(200).json({
      success: true,
      message: 'Xác nhận lịch hẹn thành công',
      data: {
        appointmentStatus: request.appointmentStatus,
        preferredTime: request.preferredTime,
        appointmentConfirmedAt: request.appointmentConfirmedAt,
      },
    });
  } catch (error) {
    console.error('confirmAppointment error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi xác nhận lịch hẹn',
      error: error.message,
    });
  }
};

/**
 * @desc    Thợ đề xuất khung giờ mới (UC-LIC-01)
 *          Chuyển appointmentStatus sang RESCHEDULED, lưu proposedTime
 * @route   PATCH /api/requests/:id/appointment/propose
 * @access  Private (technician - thợ được chốt)
 */
const proposeAppointment = async (req, res) => {
  try {
    const { id } = req.params;
    const { proposedTime, note } = req.body;

    const request = await RepairRequest.findById(id);
    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy phiếu yêu cầu',
      });
    }

    if (request.status !== 'ACCEPTED' && request.status !== 'IN_PROGRESS') {
      return res.status(400).json({
        success: false,
        message: 'Chỉ có thể đổi lịch hẹn khi yêu cầu đã được chốt thợ',
      });
    }

    if (!(await isAssignedTechnician(request, req.user._id))) {
      return res.status(403).json({
        success: false,
        message: 'Bạn không phải thợ được chốt cho yêu cầu này',
      });
    }

    if (!proposedTime) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng chọn khung giờ mới',
      });
    }

    const dt = new Date(proposedTime);
    if (isNaN(dt.getTime())) {
      return res.status(400).json({
        success: false,
        message: 'Khung giờ đề xuất không hợp lệ',
      });
    }

    if (dt.getTime() <= Date.now()) {
      return res.status(400).json({
        success: false,
        message: 'Khung giờ đề xuất phải ở tương lai',
      });
    }

    request.appointmentStatus = 'RESCHEDULED';
    request.proposedTime = dt;
    request.rescheduleNote = (note || '').trim();
    request.rescheduleRejectNote = ''; // lý do từ chối cũ không còn áp dụng
    request.appointmentConfirmedAt = null;
    await request.save();

    return res.status(200).json({
      success: true,
      message: 'Đề xuất khung giờ mới thành công, chờ khách hàng xác nhận',
      data: {
        appointmentStatus: request.appointmentStatus,
        preferredTime: request.preferredTime,
        proposedTime: request.proposedTime,
        rescheduleNote: request.rescheduleNote,
      },
    });
  } catch (error) {
    console.error('proposeAppointment error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi đề xuất lịch hẹn mới',
      error: error.message,
    });
  }
};

/**
 * @desc    Khách hàng đồng ý / từ chối khung giờ Thợ đề xuất (UC-LIC-01)
 *          - accept: proposedTime → preferredTime, chuyển CONFIRMED
 *          - reject: bỏ proposedTime, quay về PENDING (chờ thợ xử lý lại)
 * @route   PATCH /api/requests/:id/appointment/respond
 * @access  Private (user - chủ yêu cầu)
 */
const respondAppointment = async (req, res) => {
  try {
    const { id } = req.params;
    const { action, reason } = req.body; // 'accept' | 'reject', reason tùy chọn

    if (!['accept', 'reject'].includes(action)) {
      return res.status(400).json({
        success: false,
        message: 'Hành động phản hồi lịch hẹn không hợp lệ',
      });
    }

    const request = await RepairRequest.findById(id);
    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy phiếu yêu cầu',
      });
    }

    if (request.customerId.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Bạn không có quyền phản hồi lịch hẹn của yêu cầu này',
      });
    }

    if (request.appointmentStatus !== 'RESCHEDULED' || !request.proposedTime) {
      return res.status(400).json({
        success: false,
        message: 'Yêu cầu này không có lịch đổi hẹn đang chờ phản hồi',
      });
    }

    if (action === 'accept') {
      request.preferredTime = request.proposedTime;
      request.appointmentStatus = 'CONFIRMED';
      request.appointmentConfirmedAt = new Date();
      request.proposedTime = null;
      request.rescheduleNote = '';
      request.rescheduleRejectNote = '';
      await request.save();

      return res.status(200).json({
        success: true,
        message: 'Đã đồng ý khung giờ mới với thợ',
        data: {
          appointmentStatus: request.appointmentStatus,
          preferredTime: request.preferredTime,
        },
      });
    }

    // reject — lưu lý do từ chối (nếu khách có nhập)
    request.appointmentStatus = 'PENDING';
    request.proposedTime = null;
    request.rescheduleNote = '';
    request.rescheduleRejectNote = (reason || '').trim().slice(0, 300);
    request.appointmentConfirmedAt = null;
    await request.save();

    return res.status(200).json({
      success: true,
      message: 'Đã từ chối khung giờ mới, chờ thợ đề xuất lịch khác',
      data: {
        appointmentStatus: request.appointmentStatus,
        preferredTime: request.preferredTime,
      },
    });
  } catch (error) {
    console.error('respondAppointment error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi phản hồi lịch hẹn',
      error: error.message,
    });
  }
};

/**
 * @desc    Thợ bấm "Đang trên đường đến nhà khách" (UC-DI-01)
 *          Chuyển status từ ACCEPTED sang ON_THE_WAY — chỉ khi lịch hẹn đã CONFIRMED
 * @route   PATCH /api/requests/:id/on-the-way
 * @access  Private (technician - thợ được chốt)
 */
const updateOnTheWay = async (req, res) => {
  try {
    const { id } = req.params;

    const request = await RepairRequest.findById(id);
    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy phiếu yêu cầu',
      });
    }

    if (request.status !== 'ACCEPTED') {
      return res.status(400).json({
        success: false,
        message: 'Chỉ có thể cập nhật trạng thái di chuyển khi yêu cầu đã được chốt thợ',
      });
    }

    if (!(await isAssignedTechnician(request, req.user._id))) {
      return res.status(403).json({
        success: false,
        message: 'Bạn không phải thợ được chốt cho yêu cầu này',
      });
    }

    if (request.appointmentStatus !== 'CONFIRMED') {
      return res.status(400).json({
        success: false,
        message: 'Cần xác nhận lịch hẹn trước khi bắt đầu di chuyển đến nhà khách',
      });
    }

    request.status = 'ON_THE_WAY';
    request.onTheWayAt = new Date();
    await request.save();

    // Gửi thông báo đến khách hàng
    await createNotificationUtil({
      recipient: request.customerId,
      title: 'Thợ đang trên đường đến! 🛵',
      message: `Thợ ${req.user.fullName || 'kỹ thuật'} đang di chuyển đến nhà bạn cho yêu cầu "${request.title}". Vui lòng chuẩn bị và chú ý điện thoại.`,
      type: 'ORDER_STATUS',
      data: { requestId: request._id, status: 'ON_THE_WAY' },
    });

    return res.status(200).json({
      success: true,
      message: 'Đã cập nhật: đang trên đường đến nhà khách',
      data: {
        status: request.status,
        onTheWayAt: request.onTheWayAt,
      },
    });
  } catch (error) {
    console.error('updateOnTheWay error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi cập nhật trạng thái di chuyển',
      error: error.message,
    });
  }
};

module.exports = {
  createRepairRequest,
  getMyRepairRequests,
  confirmAppointment,
  proposeAppointment,
  respondAppointment,
  updateOnTheWay,
};
