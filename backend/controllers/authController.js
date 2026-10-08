const jwt = require('jsonwebtoken');
const User = require('../models/User');

// Hàm tạo JWT Token
const generateToken = (id, role) => {
  return jwt.sign(
    { id, role },
    process.env.JWT_SECRET || 'homefix_jwt_secret_key_2026_super_secure',
    {
      expiresIn: process.env.JWT_EXPIRE || '30d',
    }
  );
};

/**
 * @desc    Đăng ký tài khoản người dùng mới
 * @route   POST /api/auth/register
 * @access  Public
 */
const register = async (req, res) => {
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

    // 1. Kiểm tra các trường bắt buộc
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

    // 4. Kiểm tra định dạng giới tính
    const validGenders = ['male', 'female', 'other'];
    if (!validGenders.includes(gender)) {
      return res.status(400).json({
        success: false,
        message: 'Giới tính không hợp lệ (male, female, other)',
      });
    }

    // 5. Kiểm tra email đã tồn tại hay chưa
    const existingEmail = await User.findOne({ email: email.toLowerCase().trim() });
    if (existingEmail) {
      return res.status(409).json({
        success: false,
        message: 'Email này đã được đăng ký trong hệ thống',
      });
    }

    // 6. Kiểm tra số điện thoại đã tồn tại hay chưa
    const existingPhone = await User.findOne({ phoneNumber: phoneNumber.trim() });
    if (existingPhone) {
      return res.status(409).json({
        success: false,
        message: 'Số điện thoại này đã được sử dụng',
      });
    }

    // 7. Tạo người dùng mới (Mặc định role: 'user', isActive: true, isDeleted: false)
    const newUser = await User.create({
      fullName: fullName.trim(),
      email: email.toLowerCase().trim(),
      phoneNumber: phoneNumber.trim(),
      password,
      dateOfBirth: new Date(dateOfBirth),
      gender,
      role: 'user',
      isActive: true,
      isDeleted: false,
    });

    return res.status(201).json({
      success: true,
      message: 'Đăng ký tài khoản thành công',
      data: newUser,
    });
  } catch (error) {
    console.error('Lỗi khi đăng ký:', error);
    return res.status(500).json({
      success: false,
      message: 'Đã xảy ra lỗi máy chủ trong quá trình đăng ký',
      error: error.message,
    });
  }
};

/**
 * @desc    Đăng nhập người dùng (bằng Email hoặc Số điện thoại)
 * @route   POST /api/auth/login
 * @access  Public
 */
const login = async (req, res) => {
  try {
    const { identifier, password } = req.body;

    // 1. Kiểm tra đầu vào
    if (!identifier || !password) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng nhập email/số điện thoại và mật khẩu',
      });
    }

    const cleanIdentifier = identifier.trim();

    // 2. Tìm người dùng theo email hoặc số điện thoại
    const user = await User.findOne({
      $or: [
        { email: cleanIdentifier.toLowerCase() },
        { phoneNumber: cleanIdentifier },
      ],
    });

    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Thông tin đăng nhập không chính xác',
      });
    }

    // 3. Kiểm tra trạng thái kích hoạt tài khoản
    if (!user.isActive) {
      return res.status(403).json({
        success: false,
        message:
          'Tài khoản của bạn đã bị vô hiệu hóa bởi quản trị viên. Vui lòng liên hệ bộ phận hỗ trợ.',
      });
    }

    // 4. Kiểm tra mật khẩu
    const isMatch = await user.matchPassword(password);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Thông tin đăng nhập không chính xác',
      });
    }

    // 5. Kiểm tra xét duyệt (KYC) đối với tài khoản Thợ
    if (user.role === 'technician') {
      const approvalStatus =
        user.technicianProfile?.approvalStatus || 'pending';

      if (approvalStatus === 'pending') {
        return res.status(403).json({
          success: false,
          message:
            'Tài khoản Thợ của bạn đang ở trạng thái CHỜ XÉT DUYỆT (KYC). Vui lòng đợi quản trị viên phê duyệt hồ sơ trước khi đăng nhập.',
        });
      }

      if (approvalStatus === 'rejected') {
        const reason = user.technicianProfile?.rejectionReason
          ? ` (Lý do: ${user.technicianProfile.rejectionReason})`
          : '';
        return res.status(403).json({
          success: false,
          message: `Hồ sơ Thợ của bạn đã bị từ chối phê duyệt${reason}. Vui lòng liên hệ hỗ trợ để nộp lại.`,
        });
      }
    }

    // 6. Tạo token và phản hồi
    const token = generateToken(user._id, user.role);

    return res.status(200).json({
      success: true,
      message: 'Đăng nhập thành công',
      data: {
        token,
        user,
      },
    });

  } catch (error) {
    console.error('Lỗi khi đăng nhập:', error);
    return res.status(500).json({
      success: false,
      message: 'Đã xảy ra lỗi máy chủ trong quá trình đăng nhập',
      error: error.message,
    });
  }
};

module.exports = {
  register,
  login,
};
