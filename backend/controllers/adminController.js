const User = require('../models/User');

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
    const { status = 'pending', page = 1, limit = 20 } = req.query;

    const query = {
      role: 'technician',
    };

    if (status && ['pending', 'approved', 'rejected'].includes(status)) {
      query['technicianProfile.approvalStatus'] = status;
    }

    const pageNumber = Math.max(1, parseInt(page, 10) || 1);
    const pageSize = Math.max(1, parseInt(limit, 10) || 20);
    const skip = (pageNumber - 1) * pageSize;

    const [total, technicians] = await Promise.all([
      User.countDocuments(query),
      User.find(query)
        .select('-password')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(pageSize),
    ]);

    return res.status(200).json({
      success: true,
      message: 'Lấy danh sách duyệt hồ sơ thợ thành công',
      data: {
        technicians,
        total,
        page: pageNumber,
        totalPages: Math.ceil(total / pageSize) || 1,
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
    user.technicianProfile.approvedBy = req.user._id;
    user.technicianProfile.isAvailable = true; // Cho phép nhận việc sau khi duyệt
    await user.save();

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
    user.technicianProfile.isAvailable = false;
    await user.save();

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

module.exports = {
  getUsers,
  createStaff,
  updateUserRole,
  toggleUserStatus,
  getTechniciansForKYC,
  approveTechnician,
  rejectTechnician,
};

