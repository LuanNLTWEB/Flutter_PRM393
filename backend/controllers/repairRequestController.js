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

    if (!preferredTime) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng chọn thời gian hẹn thợ đến nhà',
      });
    }

    let parsedPreferredTime = null;
    if (preferredTime) {
      const dt = new Date(preferredTime);
      if (!isNaN(dt.getTime())) {
        parsedPreferredTime = dt;
      }
    }

    if (!parsedPreferredTime) {
      return res.status(400).json({
        success: false,
        message: 'Thời gian hẹn không hợp lệ',
      });
    }

    const now = Date.now();
    const minTime = now + 15 * 60 * 1000; // ít nhất 15 phút nữa
    const maxTime = now + 14 * 24 * 60 * 60 * 1000; // tối đa 14 ngày
    if (parsedPreferredTime.getTime() <= now) {
      return res.status(400).json({
        success: false,
        message: 'Thời gian hẹn phải ở tương lai',
      });
    }
    if (parsedPreferredTime.getTime() < minTime) {
      return res.status(400).json({
        success: false,
        message: 'Thời gian hẹn cần cách thời điểm hiện tại ít nhất 15 phút',
      });
    }
    if (parsedPreferredTime.getTime() > maxTime) {
      return res.status(400).json({
        success: false,
        message: 'Thời gian hẹn không được vượt quá 14 ngày kể từ bây giờ',
      });
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

    const { tab, status } = req.query; // WAITING_QUOTES, PROCESSING, COMPLETED, CANCELLED, hoặc ALL
    let statusFilter = {};

    if (status) {
      statusFilter = { status };
    } else if (tab === 'WAITING_QUOTES') {
      statusFilter = { status: { $in: ['OPEN', 'QUOTED'] } };
    } else if (tab === 'OPEN') {
      statusFilter = { status: 'OPEN' };
    } else if (tab === 'QUOTED') {
      statusFilter = { status: 'QUOTED' };
    } else if (tab === 'PROCESSING') {
      statusFilter = { status: { $in: ['OPEN', 'QUOTED', 'ACCEPTED', 'ON_THE_WAY', 'ARRIVED', 'IN_PROGRESS'] } };
    } else if (tab === 'ACCEPTED') {
      statusFilter = { status: { $in: ['ACCEPTED', 'ON_THE_WAY', 'ARRIVED', 'IN_PROGRESS'] } };
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
    const [waitingCount, processingCount, completedCount, cancelledCount] = await Promise.all([
      RepairRequest.countDocuments({
        ...baseFilter,
        status: { $in: ['OPEN', 'QUOTED'] },
      }),
      RepairRequest.countDocuments({
        ...baseFilter,
        status: { $in: ['OPEN', 'QUOTED', 'ACCEPTED', 'ON_THE_WAY', 'ARRIVED', 'IN_PROGRESS'] },
      }),
      RepairRequest.countDocuments({ ...baseFilter, status: 'COMPLETED' }),
      RepairRequest.countDocuments({ ...baseFilter, status: 'CANCELLED' }),
    ]);

    // Thống kê số lượng báo giá cho mỗi yêu cầu
    const requestIds = requests.map((r) => r._id);
    let quoteCountMap = {};
    if (requestIds.length > 0) {
      const quoteCounts = await Quotation.aggregate([
        { $match: { requestId: { $in: requestIds }, status: { $ne: 'RETRACTED' } } },
        { $group: { _id: '$requestId', count: { $sum: 1 } } },
      ]);
      quoteCounts.forEach((qc) => {
        quoteCountMap[qc._id.toString()] = qc.count;
      });
    }

    const requestsWithQuotes = requests.map((r) => {
      const obj = r.toObject();
      obj.quotesCount = quoteCountMap[r._id.toString()] || 0;
      return obj;
    });

    return res.status(200).json({
      success: true,
      message: 'Lấy lịch sử đơn hàng thành công',
      data: {
        requests: requestsWithQuotes,
        counts: {
          waitingQuotes: waitingCount,
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

    if (request.status !== 'ACCEPTED') {
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

    if (request.preferredTime.getTime() <= Date.now()) {
      return res.status(400).json({
        success: false,
        message: 'Giờ hẹn đã qua, vui lòng đề xuất khung giờ mới',
      });
    }

    request.appointmentStatus = 'CONFIRMED';
    request.appointmentConfirmedAt = new Date();
    request.proposedTime = null;
    request.rescheduleNote = '';
    request.rescheduleRejectNote = '';
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

    if (request.status !== 'ACCEPTED') {
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

    const now = Date.now();
    if (dt.getTime() <= now) {
      return res.status(400).json({
        success: false,
        message: 'Khung giờ đề xuất phải ở tương lai',
      });
    }
    if (dt.getTime() < now + 15 * 60 * 1000) {
      return res.status(400).json({
        success: false,
        message: 'Khung giờ đề xuất cần cách thời điểm hiện tại ít nhất 15 phút',
      });
    }
    if (dt.getTime() > now + 14 * 24 * 60 * 60 * 1000) {
      return res.status(400).json({
        success: false,
        message: 'Khung giờ đề xuất không được vượt quá 14 ngày kể từ bây giờ',
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

    if (request.status !== 'ACCEPTED') {
      return res.status(400).json({
        success: false,
        message: 'Yêu cầu này không còn ở trạng thái có thể phản hồi lịch hẹn',
      });
    }

    if (request.appointmentStatus !== 'RESCHEDULED' || !request.proposedTime) {
      return res.status(400).json({
        success: false,
        message: 'Yêu cầu này không có lịch đổi hẹn đang chờ phản hồi',
      });
    }

    if (action === 'accept') {
      if (request.proposedTime.getTime() <= Date.now()) {
        return res.status(400).json({
          success: false,
          message: 'Giờ đề xuất đã qua, vui lòng nhờ thợ đề xuất khung giờ mới',
        });
      }

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

/**
 * @desc    Thợ bấm "Đã có mặt tại hiện trường" (UC-ARR-01)
 *          Chuyển status từ ON_THE_WAY sang IN_PROGRESS
 * @route   PATCH /api/requests/:id/arrived
 * @access  Private (technician - thợ được chốt)
 */
const updateArrived = async (req, res) => {
  try {
    const { id } = req.params;

    const request = await RepairRequest.findById(id);
    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy phiếu yêu cầu',
      });
    }

    if (request.status !== 'ON_THE_WAY') {
      return res.status(400).json({
        success: false,
        message: 'Chỉ có thể báo đã có mặt khi đang trên đường đến nhà khách',
      });
    }

    if (!(await isAssignedTechnician(request, req.user._id))) {
      return res.status(403).json({
        success: false,
        message: 'Bạn không phải thợ được chốt cho yêu cầu này',
      });
    }

    request.status = 'ARRIVED';
    request.arrivedAt = new Date();
    await request.save();

    // Gửi thông báo đến khách hàng
    await createNotificationUtil({
      recipient: request.customerId,
      title: 'Thợ đã có mặt! 📍',
      message: `Thợ ${req.user.fullName || 'kỹ thuật'} đã có mặt tại hiện trường cho yêu cầu "${request.title}". Vui lòng đón tiếp thợ.`,
      type: 'ORDER_STATUS',
      data: { requestId: request._id, status: 'ARRIVED' },
    });

    return res.status(200).json({
      success: true,
      message: 'Đã cập nhật: đã có mặt tại hiện trường',
      data: {
        status: request.status,
        arrivedAt: request.arrivedAt,
      },
    });
  } catch (error) {
    console.error('updateArrived error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi cập nhật trạng thái đã có mặt',
      error: error.message,
    });
  }
};

/**
 * @desc    Thợ bấm "Bắt đầu sửa chữa" (UC-WRK-02)
 *          Chuyển status từ ARRIVED sang IN_PROGRESS
 * @route   PATCH /api/requests/:id/working
 * @access  Private (technician - thợ được chốt)
 */
const updateWorking = async (req, res) => {
  try {
    const { id } = req.params;

    const request = await RepairRequest.findById(id);
    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy phiếu yêu cầu',
      });
    }

    if (request.status !== 'ARRIVED') {
      return res.status(400).json({
        success: false,
        message: 'Chỉ có thể bắt đầu sửa chữa khi đã có mặt tại hiện trường',
      });
    }

    if (!(await isAssignedTechnician(request, req.user._id))) {
      return res.status(403).json({
        success: false,
        message: 'Bạn không phải thợ được chốt cho yêu cầu này',
      });
    }

    request.status = 'IN_PROGRESS';
    request.startedAt = new Date();
    await request.save();

    // Gửi thông báo đến khách hàng
    await createNotificationUtil({
      recipient: request.customerId,
      title: 'Thợ bắt đầu sửa chữa 🔧',
      message: `Thợ ${req.user.fullName || 'kỹ thuật'} đã bắt đầu sửa chữa cho yêu cầu "${request.title}".`,
      type: 'ORDER_STATUS',
      data: { requestId: request._id, status: 'IN_PROGRESS' },
    });

    return res.status(200).json({
      success: true,
      message: 'Đã cập nhật: đang sửa chữa',
      data: {
        status: request.status,
        startedAt: request.startedAt,
      },
    });
  } catch (error) {
    console.error('updateWorking error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi cập nhật trạng thái bắt đầu sửa chữa',
      error: error.message,
    });
  }
};

// Hủy phiếu yêu cầu trước khi chốt thợ
const cancelRepairRequest = async (req, res) => {
  try {
    const { id } = req.params;
    const { cancellationReason, reason } = req.body;

    const request = await RepairRequest.findById(id);
    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy phiếu yêu cầu sửa chữa',
      });
    }

    if (request.customerId.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Bạn không có quyền hủy phiếu yêu cầu này',
      });
    }

    if (request.status === 'CANCELLED') {
      return res.status(400).json({
        success: false,
        message: 'Phiếu yêu cầu này đã được hủy trước đó',
      });
    }

    if (request.status !== 'OPEN' && request.status !== 'QUOTED') {
      return res.status(400).json({
        success: false,
        message: 'Không thể hủy yêu cầu sau khi đã chốt thợ hoặc đang xử lý',
      });
    }

    const cancelReasonText = (cancellationReason || reason || 'Khách hàng hủy yêu cầu').trim();

    request.status = 'CANCELLED';
    request.cancelledAt = new Date();
    request.cancellationReason = cancelReasonText;
    await request.save();

    await Quotation.updateMany(
      { requestId: request._id, status: 'SENT' },
      { status: 'REJECTED', resolvedAt: new Date() }
    );

    try {
      const sentQuotes = await Quotation.find({ requestId: request._id });
      for (const quote of sentQuotes) {
        if (quote.technicianId) {
          await createNotificationUtil({
            recipient: quote.technicianId,
            title: 'Yêu cầu sửa chữa đã bị hủy',
            message: `Khách hàng đã hủy phiếu yêu cầu "${request.title}".`,
            type: 'ORDER_STATUS',
            data: { requestId: request._id, status: 'CANCELLED' },
          });
        }
      }
    } catch (notifErr) {
      console.warn('Gửi thông báo hủy đơn cho thợ thất bại:', notifErr.message);
    }

    return res.status(200).json({
      success: true,
      message: 'Hủy phiếu yêu cầu sửa chữa thành công',
      data: {
        repairRequest: request,
      },
    });
  } catch (error) {
    console.error('cancelRepairRequest error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi hủy yêu cầu sửa chữa',
      error: error.message,
    });
  }
};

/**
 * @desc    Thợ hoặc khách báo hủy tại chỗ để đưa thiết bị về xưởng (UC-WRK-07)
 * @route   PATCH /api/requests/:id/onsite-cancel
 * @access  Private (customer/technician - đơn đã đến hiện trường hoặc đang sửa)
 */
const cancelOnsiteRepair = async (req, res) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;
    const request = await RepairRequest.findById(id);

    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy phiếu yêu cầu sửa chữa',
      });
    }

    if (!['ARRIVED', 'IN_PROGRESS'].includes(request.status)) {
      return res.status(400).json({
        success: false,
        message: 'Chỉ có thể báo hủy tại chỗ khi thợ đã có mặt hoặc đang sửa chữa',
      });
    }

    const isCustomer =
      req.user.role === 'user' &&
      request.customerId.toString() === req.user._id.toString();
    const isTechnician =
      req.user.role === 'technician' &&
      (await isAssignedTechnician(request, req.user._id));

    if (!isCustomer && !isTechnician) {
      return res.status(403).json({
        success: false,
        message: 'Bạn không có quyền báo hủy phiếu yêu cầu này',
      });
    }

    if (reason != null && typeof reason !== 'string') {
      return res.status(400).json({
        success: false,
        message: 'Lý do hủy không hợp lệ',
      });
    }

    const cancellationReason = (reason || '').trim();
    if (cancellationReason.length < 10) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng nhập lý do hủy tại chỗ tối thiểu 10 ký tự',
      });
    }
    if (cancellationReason.length > 300) {
      return res.status(400).json({
        success: false,
        message: 'Lý do hủy không được vượt quá 300 ký tự',
      });
    }

    request.status = 'CANCELLED';
    request.cancelledAt = new Date();
    request.cancellationReason = cancellationReason;
    request.cancellationInitiatedBy = isCustomer ? 'customer' : 'technician';
    await request.save();

    const recipient = isCustomer
      ? request.assignedTechnicianId
      : request.customerId;
    if (recipient) {
      try {
        await createNotificationUtil({
          recipient,
          title: 'Đơn sửa chữa đã được hủy tại chỗ',
          message: `${isCustomer ? 'Khách hàng' : `Thợ ${req.user.fullName || 'kỹ thuật'}`} đã báo hủy đơn "${request.title}" để đưa thiết bị về xưởng. Lý do: ${cancellationReason}`,
          type: 'ORDER_STATUS',
          data: {
            requestId: request._id,
            status: 'CANCELLED',
            action: 'ONSITE_CANCELLED',
            initiatedBy: request.cancellationInitiatedBy,
          },
        });
      } catch (notificationError) {
        console.warn(
          'Gửi thông báo hủy tại chỗ thất bại:',
          notificationError.message
        );
      }
    }

    return res.status(200).json({
      success: true,
      message: 'Đã báo hủy tại chỗ thành công',
      data: { repairRequest: request },
    });
  } catch (error) {
    console.error('cancelOnsiteRepair error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi báo hủy tại chỗ',
      error: error.message,
    });
  }
};

/**
 * @desc    Thợ khai báo chi phí phát sinh (phụ tùng cần thay + giá thực tế) (UC-WRK-05)
 * @route   POST /api/requests/:id/costs
 * @access  Private (technician - thợ được chốt, đơn đang IN_PROGRESS)
 */
const declareAdditionalCost = async (req, res) => {
  try {
    const { id } = req.params;
    // items: [{ name, quantity, unitPrice }], note áp dụng chung cho các mục
    const { items, note } = req.body;

    const request = await RepairRequest.findById(id);
    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy phiếu yêu cầu',
      });
    }

    if (request.status !== 'IN_PROGRESS') {
      return res.status(400).json({
        success: false,
        message: 'Chỉ có thể khai báo chi phí phát sinh khi đơn đang sửa chữa',
      });
    }

    if (!(await isAssignedTechnician(request, req.user._id))) {
      return res.status(403).json({
        success: false,
        message: 'Bạn không phải thợ được chốt cho yêu cầu này',
      });
    }

    if (!Array.isArray(items) || items.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng nhập ít nhất 1 hạng mục chi phí phát sinh',
      });
    }

    if (items.length > 20) {
      return res.status(400).json({
        success: false,
        message: 'Mỗi lần chỉ được khai báo tối đa 20 hạng mục',
      });
    }

    if (note != null && typeof note !== 'string') {
      return res.status(400).json({
        success: false,
        message: 'Ghi chú chi phí phát sinh không hợp lệ',
      });
    }

    const costNote = (note || '').trim();
    if (costNote.length > 300) {
      return res.status(400).json({
        success: false,
        message: 'Ghi chú chi phí không được vượt quá 300 ký tự',
      });
    }

    const normalizeCostName = (value) =>
      value.replace(/\s+/g, ' ').trim().toLowerCase();
    const existingNames = new Set(
      request.additionalCosts.map((cost) => normalizeCostName(cost.name))
    );
    const submittedNames = new Set();
    const maxQuantity = 10000;
    const maxUnitPrice = 1000000000;
    const maxTotal = 10000000000;
    let batchTotal = 0;
    const costDocs = [];
    for (let i = 0; i < items.length; i++) {
      const item = items[i] || {};
      const name = typeof item.name === 'string' ? item.name.trim() : '';
      if (!name) {
        return res.status(400).json({
          success: false,
          message: `Hạng mục ${i + 1}: vui lòng nhập tên phụ tùng / hạng mục`,
        });
      }
      if (name.length > 200) {
        return res.status(400).json({
          success: false,
          message: `Hạng mục ${i + 1}: tên phụ tùng không được vượt quá 200 ký tự`,
        });
      }

      const normalizedName = normalizeCostName(name);
      if (existingNames.has(normalizedName) || submittedNames.has(normalizedName)) {
        return res.status(400).json({
          success: false,
          message: `Hạng mục "${name}" đã được khai báo trước đó`,
        });
      }
      submittedNames.add(normalizedName);

      const qty = Number(item.quantity ?? 1);
      if (!Number.isInteger(qty) || qty < 1 || qty > maxQuantity) {
        return res.status(400).json({
          success: false,
          message: `Hạng mục "${name}": số lượng phải là số nguyên từ 1 đến ${maxQuantity}`,
        });
      }

      const price = Number(item.unitPrice);
      if (!Number.isFinite(price) || price <= 0 || price > maxUnitPrice) {
        return res.status(400).json({
          success: false,
          message: `Hạng mục "${name}": đơn giá phải lớn hơn 0 và không vượt quá ${maxUnitPrice.toLocaleString('vi-VN')}₫`,
        });
      }

      batchTotal += qty * price;
      if (!Number.isFinite(batchTotal) || batchTotal > maxTotal) {
        return res.status(400).json({
          success: false,
          message: `Tổng chi phí phát sinh không được vượt quá ${maxTotal.toLocaleString('vi-VN')}₫`,
        });
      }

      costDocs.push({
        name,
        quantity: qty,
        unitPrice: price,
        note: costNote,
        status: 'PENDING',
        declaredAt: new Date(),
      });
    }

    const existingTotal = request.additionalCosts.reduce(
      (sum, cost) => sum + Number(cost.quantity) * Number(cost.unitPrice),
      0
    );
    if (
      !Number.isFinite(existingTotal) ||
      existingTotal + batchTotal > maxTotal
    ) {
      return res.status(400).json({
        success: false,
        message: `Tổng chi phí phát sinh của đơn không được vượt quá ${maxTotal.toLocaleString('vi-VN')}₫`,
      });
    }

    request.additionalCosts.push(...costDocs);
    await request.save();

    const saved = request.additionalCosts.slice(-costDocs.length);
    const total = Math.round(
      saved.reduce((sum, c) => sum + c.quantity * c.unitPrice, 0)
    ).toLocaleString('vi-VN');

    // Thông báo cho khách hàng phê duyệt (UC-WRK-05)
    try {
      await createNotificationUtil({
        recipient: request.customerId,
        title: 'Có chi phí phát sinh cần phê duyệt',
        message: `Thợ ${req.user.fullName || 'kỹ thuật'} khai báo ${saved.length} hạng mục chi phí phát sinh (tổng ${total}₫) cho yêu cầu "${request.title}". Vui lòng đồng ý hoặc từ chối từng mục.`,
        type: 'ORDER_STATUS',
        data: {
          requestId: request._id,
          status: request.status,
          action: 'COST_PENDING',
          costIds: saved.map((c) => c._id),
        },
      });
    } catch (notifErr) {
      console.warn('Gửi thông báo chi phí phát sinh thất bại:', notifErr.message);
    }

    return res.status(201).json({
      success: true,
      message: 'Khai báo chi phí phát sinh thành công, chờ khách phê duyệt',
      data: { costs: saved },
    });
  } catch (error) {
    console.error('declareAdditionalCost error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi khai báo chi phí phát sinh',
      error: error.message,
    });
  }
};

/**
 * @desc    Khách đồng ý / từ chối chi phí phát sinh (UC-WRK-06)
 * @route   PATCH /api/requests/:id/costs/:costId
 * @access  Private (customer - chủ phiếu yêu cầu)
 */
const respondAdditionalCost = async (req, res) => {
  try {
    const { id, costId } = req.params;
    const { action, note } = req.body; // action: 'APPROVE' | 'REJECT'

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
        message: 'Bạn không có quyền phê duyệt chi phí của phiếu này',
      });
    }

    if (request.status !== 'IN_PROGRESS') {
      return res.status(400).json({
        success: false,
        message: 'Chỉ có thể phê duyệt chi phí khi đơn đang sửa chữa',
      });
    }

    if (!['APPROVE', 'REJECT'].includes(action)) {
      return res.status(400).json({
        success: false,
        message: 'Thao tác phê duyệt không hợp lệ',
      });
    }

    if (note != null && typeof note !== 'string') {
      return res.status(400).json({
        success: false,
        message: 'Ghi chú phản hồi chi phí không hợp lệ',
      });
    }

    const customerNote = (note || '').trim();
    if (customerNote.length > 300) {
      return res.status(400).json({
        success: false,
        message: 'Ghi chú phản hồi chi phí không được vượt quá 300 ký tự',
      });
    }

    const cost = request.additionalCosts.id(costId);
    if (!cost) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy chi phí phát sinh',
      });
    }

    if (cost.status !== 'PENDING') {
      return res.status(400).json({
        success: false,
        message: 'Chi phí phát sinh này đã được xử lý trước đó',
      });
    }

    cost.status = action === 'APPROVE' ? 'APPROVED' : 'REJECTED';
    cost.customerNote = customerNote;
    cost.decidedAt = new Date();
    await request.save();

    // Thông báo kết quả cho thợ
    try {
      if (request.assignedTechnicianId) {
        await createNotificationUtil({
          recipient: request.assignedTechnicianId,
          title: action === 'APPROVE' ? 'Chi phí phát sinh được đồng ý' : 'Chi phí phát sinh bị từ chối',
          message: action === 'APPROVE'
            ? `Khách hàng đã đồng ý chi phí phát sinh "${cost.name}" cho yêu cầu "${request.title}".`
            : `Khách hàng từ chối chi phí phát sinh "${cost.name}" cho yêu cầu "${request.title}".${cost.customerNote ? ` Lý do: ${cost.customerNote}` : ''}`,
          type: 'ORDER_STATUS',
          data: {
            requestId: request._id,
            status: request.status,
            action: 'COST_DECIDED',
            costStatus: cost.status,
            costId: cost._id,
          },
        });
      }
    } catch (notifErr) {
      console.warn('Gửi thông báo kết quả chi phí thất bại:', notifErr.message);
    }

    return res.status(200).json({
      success: true,
      message: action === 'APPROVE'
        ? 'Đã đồng ý chi phí phát sinh'
        : 'Đã từ chối chi phí phát sinh',
      data: { cost },
    });
  } catch (error) {
    console.error('respondAdditionalCost error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi phê duyệt chi phí phát sinh',
      error: error.message,
    });
  }
};

module.exports = {
  createRepairRequest,
  getMyRepairRequests,
  cancelRepairRequest,
  confirmAppointment,
  proposeAppointment,
  respondAppointment,
  updateOnTheWay,
  updateArrived,
  updateWorking,
  declareAdditionalCost,
  respondAdditionalCost,
  cancelOnsiteRepair,
};
