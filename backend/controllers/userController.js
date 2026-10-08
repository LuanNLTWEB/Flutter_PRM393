const User = require('../models/User');

/**
 * @desc    Lấy thông tin cá nhân của người dùng hiện tại
 * @route   GET /api/users/profile
 * @access  Private
 */
const getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user._id).select('-password');
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy người dùng',
      });
    }

    return res.status(200).json({
      success: true,
      data: user,
    });
  } catch (error) {
    console.error('Lỗi khi lấy thông tin profile:', error);
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi lấy thông tin cá nhân',
      error: error.message,
    });
  }
};

/**
 * @desc    Cập nhật thông tin cá nhân
 * @route   PUT /api/users/profile
 * @access  Private
 */
const updateProfile = async (req, res) => {
  try {
    const { fullName, phoneNumber, dateOfBirth, gender } = req.body;
    const user = await User.findById(req.user._id);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy người dùng',
      });
    }

    // Nếu đổi số điện thoại, kiểm tra số mới có bị trùng với tài khoản khác không
    if (phoneNumber && phoneNumber.trim() !== user.phoneNumber) {
      const existingPhone = await User.findOne({
        phoneNumber: phoneNumber.trim(),
        _id: { $ne: user._id },
      });
      if (existingPhone) {
        return res.status(409).json({
          success: false,
          message: 'Số điện thoại này đã được sử dụng bởi tài khoản khác',
        });
      }
      user.phoneNumber = phoneNumber.trim();
    }

    if (fullName) user.fullName = fullName.trim();
    if (dateOfBirth) user.dateOfBirth = new Date(dateOfBirth);
    if (gender) {
      const validGenders = ['male', 'female', 'other'];
      if (!validGenders.includes(gender)) {
        return res.status(400).json({
          success: false,
          message: 'Giới tính không hợp lệ (male, female, other)',
        });
      }
      user.gender = gender;
    }

    const updatedUser = await user.save();

    return res.status(200).json({
      success: true,
      message: 'Cập nhật thông tin cá nhân thành công',
      data: updatedUser,
    });
  } catch (error) {
    console.error('Lỗi khi cập nhật profile:', error);
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi cập nhật thông tin cá nhân',
      error: error.message,
    });
  }
};

/**
 * @desc    Đổi mật khẩu tài khoản
 * @route   PUT /api/users/change-password
 * @access  Private
 */
const changePassword = async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng nhập mật khẩu hiện tại và mật khẩu mới',
      });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Mật khẩu mới phải có ít nhất 6 ký tự',
      });
    }

    const user = await User.findById(req.user._id);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy người dùng',
      });
    }

    const isMatch = await user.matchPassword(currentPassword);
    if (!isMatch) {
      return res.status(400).json({
        success: false,
        message: 'Mật khẩu hiện tại không chính xác',
      });
    }

    user.password = newPassword;
    await user.save();

    return res.status(200).json({
      success: true,
      message: 'Đổi mật khẩu thành công',
    });
  } catch (error) {
    console.error('Lỗi khi đổi mật khẩu:', error);
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi đổi mật khẩu',
      error: error.message,
    });
  }
};

/**
 * @desc    Cập nhật ảnh đại diện lên Cloudinary
 * @route   PUT /api/users/avatar
 * @access  Private
 */
const uploadAvatar = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng chọn một file ảnh để tải lên',
      });
    }

    const { uploadStream } = require('../config/cloudinary');

    // Upload buffer lên Cloudinary trong thư mục homefix/avatars
    const result = await uploadStream(req.file.buffer, {
      folder: 'homefix/avatars',
      transformation: [
        { width: 500, height: 500, crop: 'fill', gravity: 'face' },
        { quality: 'auto', fetch_format: 'auto' },
      ],
    });

    const user = await User.findById(req.user._id);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy người dùng',
      });
    }

    user.avatar = result.url;
    await user.save();

    return res.status(200).json({
      success: true,
      message: 'Cập nhật ảnh đại diện thành công',
      data: {
        avatar: user.avatar,
        user,
      },
    });
  } catch (error) {
    console.error('Lỗi khi upload avatar lên Cloudinary:', error);
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi tải ảnh lên Cloudinary',
      error: error.message,
    });
  }
};

module.exports = {
  getProfile,
  updateProfile,
  changePassword,
  uploadAvatar,
};

