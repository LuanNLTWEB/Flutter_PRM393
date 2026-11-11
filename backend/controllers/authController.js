const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { sendOtpEmail } = require('../utils/emailService');

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

/**
 * @desc    Gửi mã OTP qua email để khôi phục mật khẩu
 * @route   POST /api/auth/forgot-password
 * @access  Public
 */
const forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;
    if (!email || !email.trim()) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng nhập địa chỉ email của bạn',
      });
    }

    const cleanEmail = email.toLowerCase().trim();
    const user = await User.findOne({ email: cleanEmail });
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy tài khoản với địa chỉ email này',
      });
    }

    if (!user.isActive) {
      return res.status(403).json({
        success: false,
        message: 'Tài khoản của bạn đã bị vô hiệu hóa. Vui lòng liên hệ bộ phận hỗ trợ.',
      });
    }

    // Kiểm tra Cooldown chống spam 60 giây giữa các lần yêu cầu OTP
    if (user.resetPasswordLastRequestedAt) {
      const diffSeconds = Math.floor(
        (Date.now() - new Date(user.resetPasswordLastRequestedAt).getTime()) / 1000
      );
      if (diffSeconds < 60) {
        return res.status(429).json({
          success: false,
          message: `Vui lòng đợi thêm ${60 - diffSeconds} giây trước khi yêu cầu gửi lại mã`,
        });
      }
    }

    // Sinh mã OTP 6 số ngẫu nhiên (100000 -> 999999)
    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    // Băm mã OTP bằng SHA-256 trước khi lưu database
    const hashedOtp = crypto.createHash('sha256').update(otp).digest('hex');

    user.resetPasswordOtp = hashedOtp;
    user.resetPasswordOtpExpires = new Date(Date.now() + 5 * 60 * 1000); // Hết hạn sau 5 phút
    user.resetPasswordAttempts = 0;
    user.resetPasswordLastRequestedAt = new Date();
    user.resetPasswordToken = null;
    user.resetPasswordTokenExpires = null;
    await user.save();

    // Gửi email chứa mã OTP (hoặc in console nếu chưa cấu hình Gmail)
    await sendOtpEmail(user.email, otp);

    return res.status(200).json({
      success: true,
      message: 'Mã xác thực OTP đã được gửi đến email của bạn',
      data: {
        email: user.email,
        expiresInSeconds: 300,
      },
    });
  } catch (error) {
    console.error('Lỗi khi yêu cầu quên mật khẩu:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Đã xảy ra lỗi máy chủ khi gửi mã xác nhận',
    });
  }
};

/**
 * @desc    Xác thực mã OTP và cấp Reset Token tạm thời
 * @route   POST /api/auth/verify-otp
 * @access  Public
 */
const verifyOtp = async (req, res) => {
  try {
    const { email, otp } = req.body;
    if (!email || !otp) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng cung cấp email và mã OTP 6 số',
      });
    }

    const cleanEmail = email.toLowerCase().trim();
    const cleanOtp = otp.toString().trim();

    const user = await User.findOne({ email: cleanEmail });
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy tài khoản',
      });
    }

    // Kiểm tra có yêu cầu OTP chưa
    if (!user.resetPasswordOtp || !user.resetPasswordOtpExpires) {
      return res.status(400).json({
        success: false,
        message: 'Không có yêu cầu đặt lại mật khẩu nào đang chờ xử lý',
      });
    }

    // Kiểm tra hết hạn (5 phút)
    if (new Date(user.resetPasswordOtpExpires).getTime() < Date.now()) {
      user.resetPasswordOtp = null;
      user.resetPasswordOtpExpires = null;
      await user.save();
      return res.status(400).json({
        success: false,
        message: 'Mã OTP đã hết hạn (5 phút). Vui lòng yêu cầu gửi mã mới',
      });
    }

    // Giới hạn nhập sai tối đa 5 lần chống Brute-force
    if (user.resetPasswordAttempts >= 5) {
      user.resetPasswordOtp = null;
      user.resetPasswordOtpExpires = null;
      await user.save();
      return res.status(400).json({
        success: false,
        message: 'Bạn đã nhập sai mã OTP quá 5 lần. Vui lòng gửi lại mã mới để tiếp tục',
      });
    }

    // So khớp mã OTP
    const hashedInputOtp = crypto.createHash('sha256').update(cleanOtp).digest('hex');
    if (hashedInputOtp !== user.resetPasswordOtp) {
      user.resetPasswordAttempts += 1;
      await user.save();
      const remainingAttempts = 5 - user.resetPasswordAttempts;
      return res.status(400).json({
        success: false,
        message: `Mã OTP không chính xác. Bạn còn ${remainingAttempts} lần thử`,
      });
    }

    // OTP chính xác -> Tạo Reset Token tạm thời (10 phút)
    const rawResetToken = crypto.randomBytes(32).toString('hex');
    user.resetPasswordToken = crypto.createHash('sha256').update(rawResetToken).digest('hex');
    user.resetPasswordTokenExpires = new Date(Date.now() + 10 * 60 * 1000); // 10 phút
    user.resetPasswordOtp = null;
    user.resetPasswordOtpExpires = null;
    user.resetPasswordAttempts = 0;
    await user.save();

    return res.status(200).json({
      success: true,
      message: 'Xác thực mã OTP thành công',
      data: {
        resetToken: rawResetToken,
      },
    });
  } catch (error) {
    console.error('Lỗi khi xác thực OTP:', error);
    return res.status(500).json({
      success: false,
      message: 'Đã xảy ra lỗi máy chủ trong quá trình xác thực OTP',
      error: error.message,
    });
  }
};

/**
 * @desc    Đặt mật khẩu mới bằng Reset Token
 * @route   POST /api/auth/reset-password
 * @access  Public
 */
const resetPassword = async (req, res) => {
  try {
    const { resetToken, newPassword, confirmPassword } = req.body;

    if (!resetToken || !newPassword || !confirmPassword) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng cung cấp đầy đủ thông tin đặt lại mật khẩu',
      });
    }

    if (newPassword !== confirmPassword) {
      return res.status(400).json({
        success: false,
        message: 'Mật khẩu mới và xác nhận mật khẩu không trùng khớp',
      });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Mật khẩu mới phải có ít nhất 6 ký tự',
      });
    }

    // Băm token đầu vào để đối chiếu trong Database
    const hashedToken = crypto.createHash('sha256').update(resetToken.trim()).digest('hex');
    const user = await User.findOne({
      resetPasswordToken: hashedToken,
      resetPasswordTokenExpires: { $gt: Date.now() },
    });

    if (!user) {
      return res.status(400).json({
        success: false,
        message: 'Phiên đặt lại mật khẩu không hợp lệ hoặc đã hết hạn. Vui lòng thực hiện lại từ đầu',
      });
    }

    // Cập nhật mật khẩu mới (Mongoose pre-save hook sẽ tự động băm bcrypt)
    user.password = newPassword;
    user.resetPasswordToken = null;
    user.resetPasswordTokenExpires = null;
    user.resetPasswordOtp = null;
    user.resetPasswordOtpExpires = null;
    user.resetPasswordAttempts = 0;
    await user.save();

    return res.status(200).json({
      success: true,
      message: 'Đặt lại mật khẩu thành công! Bạn có thể đăng nhập ngay bằng mật khẩu mới.',
    });
  } catch (error) {
    console.error('Lỗi khi đặt lại mật khẩu:', error);
    return res.status(500).json({
      success: false,
      message: 'Đã xảy ra lỗi máy chủ khi cập nhật mật khẩu mới',
      error: error.message,
    });
  }
};

module.exports = {
  register,
  login,
  forgotPassword,
  verifyOtp,
  resetPassword,
};
