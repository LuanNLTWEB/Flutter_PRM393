const mongoose = require('mongoose');
const User = require('../models/User');
const RepairRequest = require('../models/RepairRequest');
const Quotation = require('../models/Quotation');
const Complaint = require('../models/Complaint');
const ServiceCategory = require('../models/ServiceCategory');
const { createNotificationUtil } = require('./notificationController');

/**
 * @desc    Lấy danh sách tài khoản (có tìm kiếm, lọc theo vai trò và trạng thái)
 * @route   GET /api/admin/users
 * @access  Private/Admin
 */
const getUsers = async (req, res) => {
  try {
    const { search, role, isActive, page = 1, limit = 50 } = req.query;

    const query = {};

    // Tìm kiếm theo Họ tên, Email hoặc Số điện thoại
    if (search && search.trim() !== '') {
      const searchRegex = new RegExp(search.trim(), 'i');
      query.$or = [
        { fullName: searchRegex },
        { email: searchRegex },
        { phoneNumber: searchRegex },
      ];
    }

    // Lọc theo vai trò (user, technician, staff, admin)
    if (role && ['user', 'technician', 'staff', 'admin'].includes(role)) {
      query.role = role;
    }

    // Lọc theo trạng thái hoạt động (khóa / đang hoạt động)
    if (isActive !== undefined && isActive !== '') {
      query.isActive = isActive === 'true' || isActive === true;
    }

    const pageNumber = Math.max(1, parseInt(page, 10) || 1);
    const pageSize = Math.max(1, parseInt(limit, 10) || 50);
    const skip = (pageNumber - 1) * pageSize;

    const [total, users] = await Promise.all([
      User.countDocuments(query),
      User.find(query)
        .select('-password')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(pageSize),
    ]);

    return res.status(200).json({
      success: true,
      message: 'Lấy danh sách tài khoản thành công',
      data: {
        users,
        total,
        page: pageNumber,
        totalPages: Math.ceil(total / pageSize) || 1,
      },
    });
  } catch (error) {
    console.error('Lỗi khi lấy danh sách tài khoản:', error);
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi lấy danh sách tài khoản',
      error: error.message,
    });
  }
};

/**
 * @desc    Tạo tài khoản Staff (Nhân viên)
 * @route   POST /api/admin/users/staff
 * @access  Private/Admin
 */
const createStaff = async (req, res) => {
  try {
    const {
      fullName,
      email,
      phoneNumber,
      password,
      confirmPassword,
      dateOfBirth,
      gender,
    } = req.body;

    // 1. Kiểm tra các trường thông tin bắt buộc
    if (
      !fullName ||
      !email ||
      !phoneNumber ||
      !password ||
      !confirmPassword ||
      !dateOfBirth ||
      !gender
    ) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng điền đầy đủ tất cả các thông tin bắt buộc',
      });
    }

    // 2. Kiểm tra mật khẩu khớp nhau
    if (password !== confirmPassword) {
      return res.status(400).json({
        success: false,
        message: 'Mật khẩu và xác nhận mật khẩu không trùng khớp',
      });
    }

    // 3. Kiểm tra độ dài mật khẩu
    if (password.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Mật khẩu phải có ít nhất 6 ký tự',
      });
    }

    // 4. Kiểm tra giới tính
    const validGenders = ['male', 'female', 'other'];
    if (!validGenders.includes(gender)) {
      return res.status(400).json({
        success: false,
        message: 'Giới tính không hợp lệ (male, female, other)',
      });
    }

    // 5. Kiểm tra email đã tồn tại
    const existingEmail = await User.findOne({
      email: email.toLowerCase().trim(),
    });
    if (existingEmail) {
      return res.status(409).json({
        success: false,
        message: 'Email này đã được sử dụng trong hệ thống',
      });
    }

    // 6. Kiểm tra số điện thoại đã tồn tại
    const existingPhone = await User.findOne({
      phoneNumber: phoneNumber.trim(),
    });
    if (existingPhone) {
      return res.status(409).json({
        success: false,
        message: 'Số điện thoại này đã được sử dụng trong hệ thống',
      });
    }

    // 7. Tạo mới tài khoản với vai trò là 'staff'
    const newStaff = await User.create({
      fullName: fullName.trim(),
      email: email.toLowerCase().trim(),
      phoneNumber: phoneNumber.trim(),
      password,
      dateOfBirth: new Date(dateOfBirth),
      gender,
      role: 'staff',
      isActive: true,
      isDeleted: false,
    });

    return res.status(201).json({
      success: true,
      message: 'Tạo tài khoản Nhân viên (Staff) thành công',
      data: newStaff,
    });
  } catch (error) {
    console.error('Lỗi khi tạo tài khoản staff:', error);
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi tạo tài khoản Staff',
      error: error.message,
    });
  }
};

/**
 * @desc    Cập nhật vai trò & quyền hạn (Role) của tài khoản
 * @route   PUT /api/admin/users/:id/role
 * @access  Private/Admin
 */
const updateUserRole = async (req, res) => {
  try {
    const { id } = req.params;
    const { role } = req.body;

    const validRoles = ['user', 'technician', 'staff', 'admin'];
    if (!role || !validRoles.includes(role)) {
      return res.status(400).json({
        success: false,
        message: `Vai trò không hợp lệ. Chỉ chấp nhận: ${validRoles.join(', ')}`,
      });
    }

    // Tránh việc Admin tự hạ quyền của chính mình gây mất quyền quản trị
    if (req.user._id.toString() === id && role !== 'admin') {
      return res.status(400).json({
        success: false,
        message: 'Bạn không thể tự hạ quyền Quản trị viên của chính mình',
      });
    }

    const user = await User.findById(id).select('-password');
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy tài khoản người dùng',
      });
    }

    user.role = role;
    await user.save();

    return res.status(200).json({
      success: true,
      message: `Đã cập nhật vai trò người dùng thành "${role}"`,
      data: user,
    });
  } catch (error) {
    console.error('Lỗi khi cập nhật vai trò:', error);
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi cập nhật vai trò',
      error: error.message,
    });
  }
};

/**
 * @desc    Khóa hoặc Mở khóa tài khoản (Cập nhật isActive)
 * @route   PUT /api/admin/users/:id/status
 * @access  Private/Admin
 */
const toggleUserStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { isActive } = req.body;

    // Không cho phép Admin tự khóa tài khoản của chính mình
    if (req.user._id.toString() === id) {
      return res.status(400).json({
        success: false,
        message: 'Bạn không thể tự khóa tài khoản của chính mình',
      });
    }

    const user = await User.findById(id).select('-password');
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy tài khoản người dùng',
      });
    }

    // Nếu truyền isActive cụ thể thì gán, ngược lại thì đảo ngược giá trị hiện tại
    user.isActive = typeof isActive === 'boolean' ? isActive : !user.isActive;
    await user.save();

    const actionText = user.isActive ? 'Mở khóa' : 'Khóa';

    return res.status(200).json({
      success: true,
      message: `${actionText} tài khoản thành công`,
      data: user,
    });
  } catch (error) {
    console.error('Lỗi khi thay đổi trạng thái tài khoản:', error);
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi thay đổi trạng thái tài khoản',
      error: error.message,
    });
  }
};

/**
 * @desc    Lấy danh sách hồ sơ Thợ cần duyệt KYC
 * @route   GET /api/admin/technicians/kyc
 * @access  Private (Admin hoặc Staff)
 */
const getTechniciansForKYC = async (req, res) => {
  try {
    const { status = 'pending', page = 1, limit = 50, search } = req.query;

    const query = {
      role: 'technician',
    };

    if (status && ['pending', 'approved', 'rejected'].includes(status)) {
      query['technicianProfile.approvalStatus'] = status;
    }

    if (search && search.trim() !== '') {
      const searchRegex = new RegExp(search.trim(), 'i');
      query.$or = [
        { fullName: searchRegex },
        { phoneNumber: searchRegex },
        { email: searchRegex },
        { 'technicianProfile.skills': searchRegex },
      ];
    }

    const pageNumber = Math.max(1, parseInt(page, 10) || 1);
    const pageSize = Math.max(1, parseInt(limit, 10) || 50);
    const skip = (pageNumber - 1) * pageSize;

    const [total, technicians, pendingCount, approvedCount, rejectedCount] = await Promise.all([
      User.countDocuments(query),
      User.find(query)
        .select('-password')
        .populate('technicianProfile.approvedBy', 'fullName email')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(pageSize),
      User.countDocuments({ role: 'technician', 'technicianProfile.approvalStatus': 'pending' }),
      User.countDocuments({ role: 'technician', 'technicianProfile.approvalStatus': 'approved' }),
      User.countDocuments({ role: 'technician', 'technicianProfile.approvalStatus': 'rejected' }),
    ]);

    return res.status(200).json({
      success: true,
      message: 'Lấy danh sách duyệt hồ sơ thợ thành công',
      data: {
        technicians,
        total,
        page: pageNumber,
        totalPages: Math.ceil(total / pageSize) || 1,
        counts: {
          pending: pendingCount,
          approved: approvedCount,
          rejected: rejectedCount,
        },
      },
    });
  } catch (error) {
    console.error('Lỗi khi lấy danh sách duyệt hồ sơ thợ:', error);
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi lấy danh sách duyệt hồ sơ thợ',
      error: error.message,
    });
  }
};

/**
 * @desc    Phê duyệt hồ sơ Thợ (KYC Approval)
 * @route   PUT /api/admin/technicians/:id/approve
 * @access  Private (Admin hoặc Staff)
 */
const approveTechnician = async (req, res) => {
  try {
    const { id } = req.params;

    const user = await User.findOne({ _id: id, role: 'technician' });
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy hồ sơ thợ tương ứng',
      });
    }

    user.technicianProfile.approvalStatus = 'approved';
    user.technicianProfile.rejectionReason = '';
    user.technicianProfile.approvedAt = new Date();
    user.technicianProfile.rejectedAt = null;
    user.technicianProfile.approvedBy = req.user._id;
    user.technicianProfile.isAvailable = true; // Cho phép nhận việc sau khi duyệt
    await user.save();

    // Gửi thông báo tới thợ
    await createNotificationUtil({
      recipient: user._id,
      title: 'Hồ sơ Thợ đã được phê duyệt! 🎉',
      message: 'Chúc mừng bạn! Hồ sơ kỹ thuật viên đã được ban quản trị xét duyệt thành công. Bạn đã có thể bắt đầu nhận đơn và báo giá dịch vụ.',
      type: 'KYC',
      data: { status: 'approved' },
    });

    return res.status(200).json({
      success: true,
      message: `Đã phê duyệt hồ sơ cho thợ "${user.fullName}" thành công`,
      data: user,
    });
  } catch (error) {
    console.error('Lỗi khi phê duyệt hồ sơ thợ:', error);
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi phê duyệt hồ sơ thợ',
      error: error.message,
    });
  }
};

/**
 * @desc    Từ chối hồ sơ Thợ (KYC Rejection kèm lý do)
 * @route   PUT /api/admin/technicians/:id/reject
 * @access  Private (Admin hoặc Staff)
 */
const rejectTechnician = async (req, res) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;

    if (!reason || reason.trim() === '') {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng cung cấp lý do từ chối hồ sơ',
      });
    }

    const user = await User.findOne({ _id: id, role: 'technician' });
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy hồ sơ thợ tương ứng',
      });
    }

    user.technicianProfile.approvalStatus = 'rejected';
    user.technicianProfile.rejectionReason = reason.trim();
    user.technicianProfile.rejectedAt = new Date();
    user.technicianProfile.approvedBy = req.user._id;
    user.technicianProfile.isAvailable = false;
    await user.save();

    // Gửi thông báo từ chối tới thợ
    await createNotificationUtil({
      recipient: user._id,
      title: 'Hồ sơ Thợ chưa đạt yêu cầu ⚠️',
      message: `Hồ sơ kỹ thuật viên của bạn đã bị từ chối với lý do: "${reason.trim()}". Vui lòng kiểm tra và cập nhật lại thông tin giấy tờ.`,
      type: 'KYC',
      data: { status: 'rejected', reason: reason.trim() },
    });

    return res.status(200).json({
      success: true,
      message: `Đã từ chối hồ sơ thợ "${user.fullName}" với lý do: ${reason}`,
      data: user,
    });
  } catch (error) {
    console.error('Lỗi khi từ chối hồ sơ thợ:', error);
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi từ chối hồ sơ thợ',
      error: error.message,
    });
  }
};

/**
 * @desc    Giám sát danh sách đơn hàng bị treo / đang xử lý để Staff can thiệp (UC-STF-04)
 * @route   GET /api/admin/requests/stuck
 * @access  Private (Admin hoặc Staff)
 */
const getStuckRequests = async (req, res) => {
  try {
    const { filter = 'ALL', search = '' } = req.query;

    const activeStatuses = [
      'OPEN',
      'QUOTED',
      'ACCEPTED',
      'ON_THE_WAY',
      'ARRIVED',
      'IN_PROGRESS',
    ];

    const [requests, candidateTechnicians] = await Promise.all([
      RepairRequest.find({ status: { $in: activeStatuses } })
        .populate('customerId', 'fullName phoneNumber email')
        .populate('serviceCategoryId', 'name basePrice icon color')
        .populate(
          'assignedTechnicianId',
          'fullName phoneNumber email rating reviewCount technicianProfile.skills technicianProfile.rating technicianProfile.reviewCount technicianProfile.completedJobsCount technicianProfile.isAvailable'
        )
        .sort({ updatedAt: 1 }),
      User.find({
        role: 'technician',
        isActive: true,
        'technicianProfile.approvalStatus': 'approved',
      })
        .select(
          'fullName phoneNumber email rating reviewCount technicianProfile.skills technicianProfile.rating technicianProfile.reviewCount technicianProfile.completedJobsCount technicianProfile.isAvailable'
        )
        .sort({
          'technicianProfile.isAvailable': -1,
          'technicianProfile.rating': -1,
          rating: -1,
          fullName: 1,
        }),
    ]);

    // Tuân thủ quy tắc nghiệp vụ: Mỗi kỹ thuật viên chỉ phụ trách tối đa 1 đơn đang thực hiện tại một thời điểm
    const busyJobStatuses = ['ACCEPTED', 'ON_THE_WAY', 'ARRIVED', 'IN_PROGRESS'];
    const busyTechnicianIds = new Set(
      requests
        .filter(
          (r) => busyJobStatuses.includes(r.status) && r.assignedTechnicianId
        )
        .map((r) =>
          (r.assignedTechnicianId._id || r.assignedTechnicianId).toString()
        )
    );

    const availableTechnicians = candidateTechnicians
      .filter((t) => !busyTechnicianIds.has(t._id.toString()))
      .map((t) => {
        const obj = t.toObject();
        const avgRating = Number(
          obj.technicianProfile?.rating ?? obj.rating ?? 5.0
        );
        const totalReviews = Number(
          obj.technicianProfile?.reviewCount ?? obj.reviewCount ?? 0
        );
        return {
          ...obj,
          rating: avgRating,
          reviewCount: totalReviews,
          technicianProfile: {
            ...(obj.technicianProfile || {}),
            rating: avgRating,
            reviewCount: totalReviews,
            averageRating: avgRating,
            totalReviews,
          },
        };
      });

    const now = new Date();

    const enrichedRequests = requests.map((doc) => {
      const obj = doc.toObject();
      const createdAt = obj.createdAt ? new Date(obj.createdAt) : now;
      const updatedAt = obj.updatedAt ? new Date(obj.updatedAt) : now;
      const preferredTime = obj.preferredTime ? new Date(obj.preferredTime) : null;

      const hoursSinceCreated = Math.max(
        0,
        Math.round(((now - createdAt) / (1000 * 60 * 60)) * 10) / 10
      );
      const hoursSinceUpdated = Math.max(
        0,
        Math.round(((now - updatedAt) / (1000 * 60 * 60)) * 10) / 10
      );

      let stuckType = 'IN_PROGRESS';
      let isStuck = false;
      let stuckSeverity = 'NORMAL';
      let stuckReason = '';

      const isOverduePreferred =
        preferredTime &&
        preferredTime < now &&
        ['OPEN', 'QUOTED', 'ACCEPTED', 'ON_THE_WAY', 'ARRIVED'].includes(obj.status);

      if (isOverduePreferred) {
        const overdueHours = Math.max(
          0.5,
          Math.round(((now - preferredTime) / (1000 * 60 * 60)) * 10) / 10
        );
        stuckType = 'OVERDUE';
        isStuck = true;
        stuckSeverity = 'HIGH';
        stuckReason = `Đã quá giờ hẹn khách chọn (${overdueHours} giờ) nhưng chưa bắt đầu sửa chữa`;
      } else if (['OPEN', 'QUOTED'].includes(obj.status)) {
        stuckType = 'NO_TECH';
        if (
          hoursSinceCreated >= 2 ||
          obj.urgency === 'emergency' ||
          obj.urgency === 'high'
        ) {
          isStuck = true;
          stuckSeverity = hoursSinceCreated >= 12 ? 'HIGH' : 'MEDIUM';
          stuckReason =
            obj.status === 'OPEN'
              ? `Đơn mở ${hoursSinceCreated} giờ chưa có thợ nhận xử lý`
              : `Đã có báo giá nhưng khách chưa chốt thợ sau ${hoursSinceCreated} giờ`;
        } else {
          isStuck = false;
          stuckSeverity = 'NORMAL';
          stuckReason = `Đang chờ điều phối / chốt thợ (${hoursSinceCreated} giờ)`;
        }
      } else {
        stuckType = 'IN_PROGRESS';
        if (hoursSinceUpdated >= 3) {
          isStuck = true;
          stuckSeverity = hoursSinceUpdated >= 12 ? 'HIGH' : 'MEDIUM';
          stuckReason = `Đơn ở trạng thái ${obj.status} bị đình trệ ${hoursSinceUpdated} giờ chưa cập nhật`;
        } else {
          isStuck = false;
          stuckSeverity = 'NORMAL';
          stuckReason = `Đang thực hiện (${hoursSinceUpdated} giờ từ lần cập nhật cuối)`;
        }
      }

      return {
        ...obj,
        stuckInfo: {
          isStuck,
          stuckType,
          stuckSeverity,
          stuckReason,
          hoursSinceCreated,
          hoursSinceUpdated,
        },
      };
    });

    const counts = {
      totalActive: enrichedRequests.length,
      stuckCount: enrichedRequests.filter((r) => r.stuckInfo.isStuck).length,
      overdueCount: enrichedRequests.filter(
        (r) => r.stuckInfo.stuckType === 'OVERDUE'
      ).length,
      noTechCount: enrichedRequests.filter((r) =>
        ['OPEN', 'QUOTED'].includes(r.status)
      ).length,
      inProgressCount: enrichedRequests.filter((r) =>
        ['ACCEPTED', 'ON_THE_WAY', 'ARRIVED', 'IN_PROGRESS'].includes(r.status)
      ).length,
    };

    let filtered = enrichedRequests;
    const normalizedFilter = String(filter).toUpperCase();
    if (normalizedFilter === 'STUCK') {
      filtered = filtered.filter((r) => r.stuckInfo.isStuck);
    } else if (normalizedFilter === 'OVERDUE') {
      filtered = filtered.filter((r) => r.stuckInfo.stuckType === 'OVERDUE');
    } else if (normalizedFilter === 'NO_TECH') {
      filtered = filtered.filter((r) => ['OPEN', 'QUOTED'].includes(r.status));
    } else if (normalizedFilter === 'IN_PROGRESS') {
      filtered = filtered.filter((r) =>
        ['ACCEPTED', 'ON_THE_WAY', 'ARRIVED', 'IN_PROGRESS'].includes(r.status)
      );
    }

    if (search && search.trim() !== '') {
      const q = search.trim().toLowerCase();
      filtered = filtered.filter((r) => {
        const title = (r.title || '').toLowerCase();
        const address = (r.location?.address || '').toLowerCase();
        const cusName = (r.customerId?.fullName || '').toLowerCase();
        const cusPhone = (r.customerId?.phoneNumber || '').toLowerCase();
        const techName = (r.assignedTechnicianId?.fullName || '').toLowerCase();
        const techPhone = (r.assignedTechnicianId?.phoneNumber || '').toLowerCase();
        const catName = (r.serviceCategoryId?.name || '').toLowerCase();
        return (
          title.contains(q) ||
          address.contains(q) ||
          cusName.contains(q) ||
          cusPhone.contains(q) ||
          techName.contains(q) ||
          techPhone.contains(q) ||
          catName.contains(q)
        );
      });
    }

    const severityRank = { HIGH: 0, MEDIUM: 1, NORMAL: 2 };
    filtered.sort((a, b) => {
      const rankDiff =
        (severityRank[a.stuckInfo.stuckSeverity] ?? 3) -
        (severityRank[b.stuckInfo.stuckSeverity] ?? 3);
      if (rankDiff !== 0) return rankDiff;
      return new Date(a.updatedAt) - new Date(b.updatedAt);
    });

    return res.status(200).json({
      success: true,
      message: 'Lấy danh sách giám sát đơn hàng thành công',
      data: {
        requests: filtered,
        counts,
        availableTechnicians,
      },
    });
  } catch (error) {
    console.error('Lỗi khi lấy danh sách đơn hàng bị treo:', error);
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi lấy danh sách giám sát đơn hàng',
      error: error.message,
    });
  }
};

/**
 * @desc    Staff/Admin can thiệp hủy đơn hàng bị treo (UC-STF-04)
 * @route   PUT /api/admin/requests/:id/cancel
 * @access  Private (Admin hoặc Staff)
 */
const staffCancelRequest = async (req, res) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;

    if (!mongoose.isValidObjectId(id)) {
      return res.status(400).json({
        success: false,
        message: 'Mã đơn hàng không hợp lệ',
      });
    }

    if (!reason || reason.trim().length < 5) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng nhập lý do can thiệp hủy đơn (ít nhất 5 ký tự)',
      });
    }

    const repairRequest = await RepairRequest.findById(id);
    if (!repairRequest) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy đơn sửa chữa',
      });
    }

    if (['COMPLETED', 'CANCELLED'].includes(repairRequest.status)) {
      return res.status(400).json({
        success: false,
        message: `Đơn hàng đã ở trạng thái ${repairRequest.status}, không thể can thiệp hủy`,
      });
    }

    const previousTechnicianId = repairRequest.assignedTechnicianId
      ? repairRequest.assignedTechnicianId.toString()
      : null;
    const cleanReason = reason.trim();
    const now = new Date();

    // Hủy tất cả các chi phí phát sinh đang chờ duyệt (nếu có)
    if (Array.isArray(repairRequest.additionalCosts)) {
      repairRequest.additionalCosts.forEach((item) => {
        if (item.status === 'PENDING') {
          item.status = 'REJECTED';
          item.resolvedAt = now;
        }
      });
    }

    repairRequest.status = 'CANCELLED';
    repairRequest.cancelledAt = now;
    repairRequest.cancellationReason = `[Vận hành can thiệp] ${cleanReason}`;
    repairRequest.cancellationInitiatedBy = 'staff';
    repairRequest.staffInterventionNote = cleanReason;
    await repairRequest.save();

    // Tìm các báo giá đang ở trạng thái SENT để thông báo cho các kỹ thuật viên đã gửi báo giá
    const sentQuotations = await Quotation.find({
      requestId: repairRequest._id,
      status: 'SENT',
    }).select('technicianId');

    await Quotation.updateMany(
      {
        requestId: repairRequest._id,
        status: { $in: ['SENT', 'ACCEPTED'] },
      },
      {
        $set: {
          status: 'REJECTED',
          resolvedAt: now,
        },
      }
    );

    await createNotificationUtil({
      recipient: repairRequest.customerId,
      title: 'Đơn sửa chữa đã được bộ phận Vận hành hủy ⚠️',
      message: `Đơn "${repairRequest.title}" đã được nhân viên vận hành can thiệp hủy với lý do: "${cleanReason}".`,
      type: 'ORDER_STATUS',
      data: {
        requestId: repairRequest._id,
        status: 'CANCELLED',
        reason: cleanReason,
      },
    });

    if (previousTechnicianId) {
      await createNotificationUtil({
        recipient: previousTechnicianId,
        title: 'Đơn sửa chữa đã bị hủy bởi Vận hành ⚠️',
        message: `Đơn "${repairRequest.title}" bạn đang phụ trách đã được bộ phận vận hành hủy: "${cleanReason}".`,
        type: 'ORDER_STATUS',
        data: {
          requestId: repairRequest._id,
          status: 'CANCELLED',
          reason: cleanReason,
        },
      });
    }

    for (const q of sentQuotations) {
      const quotedTechId = q.technicianId ? q.technicianId.toString() : null;
      if (quotedTechId && quotedTechId !== previousTechnicianId) {
        await createNotificationUtil({
          recipient: quotedTechId,
          title: 'Đơn bạn báo giá đã bị hủy bởi Vận hành ⚠️',
          message: `Đơn "${repairRequest.title}" mà bạn đã gửi báo giá đã được bộ phận vận hành hủy: "${cleanReason}".`,
          type: 'ORDER_STATUS',
          data: {
            requestId: repairRequest._id,
            status: 'CANCELLED',
            reason: cleanReason,
          },
        });
      }
    }

    const populated = await RepairRequest.findById(repairRequest._id)
      .populate('customerId', 'fullName phoneNumber email')
      .populate('serviceCategoryId', 'name basePrice icon color')
      .populate(
        'assignedTechnicianId',
        'fullName phoneNumber email rating reviewCount technicianProfile.skills technicianProfile.rating technicianProfile.reviewCount technicianProfile.completedJobsCount'
      );

    return res.status(200).json({
      success: true,
      message: 'Đã can thiệp hủy đơn hàng thành công',
      data: { request: populated },
    });
  } catch (error) {
    console.error('Lỗi khi Staff can thiệp hủy đơn:', error);
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi can thiệp hủy đơn hàng',
      error: error.message,
    });
  }
};

/**
 * @desc    Staff/Admin hỗ trợ điều phối lại thợ khác hoặc mở lại đơn bị treo (UC-STF-04)
 * @route   PUT /api/admin/requests/:id/reassign
 * @access  Private (Admin hoặc Staff)
 */
const staffReassignRequest = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      newTechnicianId,
      note = '',
      mode = 'ASSIGN',
      newPreferredTime,
    } = req.body;

    if (!mongoose.isValidObjectId(id)) {
      return res.status(400).json({
        success: false,
        message: 'Mã đơn hàng không hợp lệ',
      });
    }

    const repairRequest = await RepairRequest.findById(id).populate(
      'serviceCategoryId',
      'name basePrice'
    );
    if (!repairRequest) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy đơn sửa chữa',
      });
    }

    if (['COMPLETED', 'CANCELLED'].includes(repairRequest.status)) {
      return res.status(400).json({
        success: false,
        message: `Đơn hàng đã ở trạng thái ${repairRequest.status}, không thể điều phối lại`,
      });
    }

    const previousTechnicianId = repairRequest.assignedTechnicianId
      ? repairRequest.assignedTechnicianId.toString()
      : null;
    const cleanNote = note.trim();
    const now = new Date();

    // Hủy các khoản chi phí phát sinh đang chờ duyệt của thợ cũ (nếu có)
    if (Array.isArray(repairRequest.additionalCosts)) {
      repairRequest.additionalCosts.forEach((item) => {
        if (item.status === 'PENDING') {
          item.status = 'REJECTED';
          item.resolvedAt = now;
        }
      });
    }

    // Tự động gia hạn preferredTime (+2 giờ) nếu giờ hẹn cũ đã qua,
    // đảm bảo thợ mới có thể xác nhận lịch hẹn (UC-SCH-02) hoặc khách có thể duyệt báo giá mới (UC-QUO-08)
    let timeExtended = false;
    if (newPreferredTime && !Number.isNaN(new Date(newPreferredTime).getTime())) {
      const parsedTime = new Date(newPreferredTime);
      if (parsedTime > now) {
        repairRequest.preferredTime = parsedTime;
        timeExtended = true;
      }
    } else if (
      !repairRequest.preferredTime ||
      new Date(repairRequest.preferredTime) <= now
    ) {
      repairRequest.preferredTime = new Date(now.getTime() + 2 * 60 * 60 * 1000);
      timeExtended = true;
    }

    // Chế độ 1: Mở lại đơn về trạng thái OPEN/QUOTED để các thợ khác gửi báo giá
    if (mode === 'REOPEN' || !newTechnicianId) {
      await Quotation.updateMany(
        { requestId: repairRequest._id, status: 'ACCEPTED' },
        { $set: { status: 'REJECTED', resolvedAt: now } }
      );

      const remainingSentQuotes = await Quotation.countDocuments({
        requestId: repairRequest._id,
        status: 'SENT',
      });

      const reopenedStatus = remainingSentQuotes > 0 ? 'QUOTED' : 'OPEN';

      repairRequest.assignedTechnicianId = null;
      repairRequest.status = reopenedStatus;
      repairRequest.appointmentStatus = 'PENDING';
      repairRequest.proposedTime = null;
      repairRequest.rescheduleNote = '';
      repairRequest.rescheduleRejectNote = '';
      repairRequest.appointmentConfirmedAt = null;
      repairRequest.onTheWayAt = null;
      repairRequest.arrivedAt = null;
      repairRequest.startedAt = null;
      repairRequest.staffInterventionNote =
        cleanNote || 'Mở lại đơn hàng để tìm kỹ thuật viên mới';
      await repairRequest.save();

      await createNotificationUtil({
        recipient: repairRequest.customerId,
        title: 'Đơn sửa chữa đang được điều phối lại 🔄',
        message: `Bộ phận vận hành đã mở lại đơn "${repairRequest.title}" để hỗ trợ tìm thợ mới cho bạn.${cleanNote ? ` Ghi chú: ${cleanNote}` : ''}`,
        type: 'ORDER_STATUS',
        data: { requestId: repairRequest._id, status: reopenedStatus },
      });

      if (previousTechnicianId) {
        await createNotificationUtil({
          recipient: previousTechnicianId,
          title: 'Thu hồi phân công đơn sửa chữa 🔄',
          message: `Đơn "${repairRequest.title}" đã được bộ phận vận hành thu hồi để điều phối lại.${cleanNote ? ` Lý do: ${cleanNote}` : ''}`,
          type: 'ORDER_STATUS',
          data: { requestId: repairRequest._id, status: reopenedStatus },
        });
      }

      const populated = await RepairRequest.findById(repairRequest._id)
        .populate('customerId', 'fullName phoneNumber email')
        .populate('serviceCategoryId', 'name basePrice icon color')
        .populate(
          'assignedTechnicianId',
          'fullName phoneNumber email rating reviewCount technicianProfile.skills technicianProfile.rating technicianProfile.reviewCount technicianProfile.completedJobsCount'
        );

      return res.status(200).json({
        success: true,
        message: timeExtended
          ? 'Đã gỡ thợ cũ, mở lại đơn hàng và gia hạn khung giờ hẹn mới (+2 giờ)'
          : 'Đã gỡ thợ cũ và mở lại đơn hàng thành công',
        data: { request: populated },
      });
    }

    // Chế độ 2: Gán trực tiếp cho một thợ mới cụ thể
    if (!mongoose.isValidObjectId(newTechnicianId)) {
      return res.status(400).json({
        success: false,
        message: 'Mã kỹ thuật viên được chọn không hợp lệ',
      });
    }

    if (previousTechnicianId && previousTechnicianId === newTechnicianId) {
      return res.status(400).json({
        success: false,
        message: 'Kỹ thuật viên này đang phụ trách đơn hàng rồi, vui lòng chọn thợ khác',
      });
    }

    const newTechnician = await User.findOne({
      _id: newTechnicianId,
      role: 'technician',
      isActive: true,
      'technicianProfile.approvalStatus': 'approved',
    });

    if (!newTechnician) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy kỹ thuật viên hợp lệ hoặc tài khoản thợ đã bị khóa',
      });
    }

    // Kiểm tra quy tắc 1 thợ chỉ phụ trách tối đa 1 đơn đang thực hiện tại 1 thời điểm
    const activeJobOfNewTech = await RepairRequest.findOne({
      _id: { $ne: repairRequest._id },
      assignedTechnicianId: newTechnician._id,
      status: { $in: ['ACCEPTED', 'ON_THE_WAY', 'ARRIVED', 'IN_PROGRESS'] },
    }).select('_id title status');

    if (activeJobOfNewTech) {
      return res.status(400).json({
        success: false,
        message: `Thợ "${newTechnician.fullName}" hiện đang bận thực hiện đơn "${activeJobOfNewTech.title}" (${activeJobOfNewTech.status}). Vui lòng chọn kỹ thuật viên khác.`,
      });
    }

    const [existingQuoteOfNewTech, oldAcceptedQuote] = await Promise.all([
      Quotation.findOne({
        requestId: repairRequest._id,
        technicianId: newTechnician._id,
      }),
      Quotation.findOne({
        requestId: repairRequest._id,
        status: 'ACCEPTED',
      }),
    ]);

    const defaultLabourCost = Number(
      existingQuoteOfNewTech?.labourCost ??
        oldAcceptedQuote?.labourCost ??
        repairRequest.serviceCategoryId?.basePrice ??
        150000
    );
    const defaultPartsCost = Number(
      existingQuoteOfNewTech?.partsCost ?? oldAcceptedQuote?.partsCost ?? 0
    );

    // Từ chối toàn bộ các báo giá SENT/ACCEPTED của những kỹ thuật viên khác trên đơn này
    await Quotation.updateMany(
      {
        requestId: repairRequest._id,
        technicianId: { $ne: newTechnician._id },
        status: { $in: ['SENT', 'ACCEPTED'] },
      },
      { $set: { status: 'REJECTED', resolvedAt: now } }
    );

    await Quotation.findOneAndUpdate(
      {
        requestId: repairRequest._id,
        technicianId: newTechnician._id,
      },
      {
        $set: {
          labourCost: defaultLabourCost,
          partsCost: defaultPartsCost,
          total: defaultLabourCost + defaultPartsCost,
          status: 'ACCEPTED',
          resolvedAt: now,
          note:
            cleanNote ||
            `Được điều phối trực tiếp bởi bộ phận Vận hành (${req.user.fullName || 'Staff'})`,
        },
      },
      { upsert: true, new: true }
    );

    repairRequest.assignedTechnicianId = newTechnician._id;
    repairRequest.status = 'ACCEPTED';
    repairRequest.appointmentStatus = 'PENDING';
    repairRequest.proposedTime = null;
    repairRequest.rescheduleNote = '';
    repairRequest.rescheduleRejectNote = '';
    repairRequest.appointmentConfirmedAt = null;
    repairRequest.onTheWayAt = null;
    repairRequest.arrivedAt = null;
    repairRequest.startedAt = null;
    repairRequest.staffInterventionNote =
      cleanNote || `Điều phối sang kỹ thuật viên ${newTechnician.fullName}`;
    await repairRequest.save();

    await createNotificationUtil({
      recipient: repairRequest.customerId,
      title: 'Đã điều phối kỹ thuật viên mới cho đơn của bạn 🛠️',
      message: `Bộ phận vận hành đã điều phối thợ "${newTechnician.fullName}" (${newTechnician.phoneNumber}) tiếp nhận đơn "${repairRequest.title}".`,
      type: 'ORDER_STATUS',
      data: {
        requestId: repairRequest._id,
        status: 'ACCEPTED',
        technicianId: newTechnician._id,
      },
    });

    await createNotificationUtil({
      recipient: newTechnician._id,
      title: 'Bạn được điều phối nhận đơn sửa chữa mới 📋',
      message: `Bộ phận vận hành đã phân công bạn phụ trách đơn "${repairRequest.title}". Vui lòng kiểm tra và xác nhận lịch hẹn với khách hàng.`,
      type: 'ORDER_STATUS',
      data: {
        requestId: repairRequest._id,
        status: 'ACCEPTED',
      },
    });

    if (previousTechnicianId) {
      await createNotificationUtil({
        recipient: previousTechnicianId,
        title: 'Đơn sửa chữa đã được chuyển cho thợ khác 🔄',
        message: `Đơn "${repairRequest.title}" đã được bộ phận vận hành điều phối sang kỹ thuật viên khác.${cleanNote ? ` Ghi chú: ${cleanNote}` : ''}`,
        type: 'ORDER_STATUS',
        data: {
          requestId: repairRequest._id,
          status: 'ACCEPTED',
        },
      });
    }

    const populated = await RepairRequest.findById(repairRequest._id)
      .populate('customerId', 'fullName phoneNumber email')
      .populate('serviceCategoryId', 'name basePrice icon color')
      .populate(
        'assignedTechnicianId',
        'fullName phoneNumber email rating reviewCount technicianProfile.skills technicianProfile.rating technicianProfile.reviewCount technicianProfile.completedJobsCount'
      );

    return res.status(200).json({
      success: true,
      message: timeExtended
        ? `Đã điều phối đơn cho thợ "${newTechnician.fullName}" và tự động gia hạn khung giờ hẹn (+2 giờ)`
        : `Đã điều phối đơn hàng cho thợ "${newTechnician.fullName}" thành công`,
      data: { request: populated },
    });
  } catch (error) {
    console.error('Lỗi khi điều phối lại thợ:', error);
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi điều phối lại đơn hàng',
      error: error.message,
    });
  }
};

module.exports = {
  getUsers,
  createStaff,
  updateUserRole,
  toggleUserStatus,
  getTechniciansForKYC,
  approveTechnician,
  rejectTechnician,
  getStuckRequests,
  staffCancelRequest,
  staffReassignRequest,
};
