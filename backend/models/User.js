const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema(
  {
    fullName: {
      type: String,
      required: [true, 'Họ và tên là bắt buộc'],
      trim: true,
    },
    email: {
      type: String,
      required: [true, 'Email là bắt buộc'],
      unique: true,
      lowercase: true,
      trim: true,
      match: [
        /^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/,
        'Vui lòng nhập địa chỉ email hợp lệ',
      ],
    },
    phoneNumber: {
      type: String,
      required: [true, 'Số điện thoại là bắt buộc'],
      trim: true,
    },
    password: {
      type: String,
      required: [true, 'Mật khẩu là bắt buộc'],
      minlength: [6, 'Mật khẩu phải có ít nhất 6 ký tự'],
    },
    dateOfBirth: {
      type: Date,
      required: [true, 'Ngày sinh là bắt buộc'],
    },
    gender: {
      type: String,
      required: [true, 'Giới tính là bắt buộc'],
      enum: {
        values: ['male', 'female', 'other'],
        message: 'Giới tính không hợp lệ (male, female, other)',
      },
    },
    // Quản lý vai trò (Role-based access control)
    // - user: Khách hàng sử dụng dịch vụ sửa chữa
    // - technician: Thợ kỹ thuật sửa chữa
    // - staff: Nhân viên vận hành, điều phối
    // - admin: Quản trị viên hệ thống (quản lý tài khoản, phân quyền, khóa/mở)
    role: {
      type: String,
      enum: ['user', 'technician', 'staff', 'admin'],
      default: 'user',
    },
    // Đường dẫn ảnh đại diện (Cloudinary URL)
    avatar: {
      type: String,
      default: '',
    },
    // Hồ sơ chuyên môn dành riêng cho thợ (Technician Profile & KYC)
    technicianProfile: {
      skills: {
        type: [String],
        default: [],
      },
      experienceYears: {
        type: Number,
        default: 0,
      },
      bio: {
        type: String,
        default: '',
        trim: true,
      },
      idCardFront: {
        type: String,
        default: '',
      },
      idCardBack: {
        type: String,
        default: '',
      },
      certificates: {
        type: [String],
        default: [],
      },
      approvalStatus: {
        type: String,
        enum: ['pending', 'approved', 'rejected'],
        default: 'pending',
      },
      rejectionReason: {
        type: String,
        default: '',
      },
      approvedAt: {
        type: Date,
        default: null,
      },
      approvedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        default: null,
      },
      isAvailable: {
        type: Boolean,
        default: false,
      },
      completedJobsCount: {
        type: Number,
        default: 0,
      },
      rating: {
        type: Number,
        default: 5.0,
      },
      reviewCount: {
        type: Number,
        default: 0,
      },
    },
    // Trạng thái tài khoản (Admin có thể khóa / kích hoạt lại tài khoản)
    isActive: {
      type: Boolean,
      default: true,
    },
    // Xóa mềm tài khoản (Soft Delete)
    isDeleted: {
      type: Boolean,
      default: false,
    },
    // Đánh giá thợ kỹ thuật
    rating: {
      type: Number,
      default: 5.0,
      min: 1,
      max: 5,
    },
    reviewCount: {
      type: Number,
      default: 0,
    },
    deletedAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

// Tự động mã hóa mật khẩu trước khi lưu vào MongoDB
userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) {
    return next();
  }
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

// Middleware tự động lọc bỏ các tài khoản đã bị xóa mềm khi truy vấn thông thường
userSchema.pre(/^find/, function (next) {
  if (this.getQuery().isDeleted === undefined) {
    this.where({ isDeleted: false });
  }
  next();
});

// Phương thức kiểm tra mật khẩu
userSchema.methods.matchPassword = async function (enteredPassword) {
  return await bcrypt.compare(enteredPassword, this.password);
};

// Phương thức hỗ trợ xóa mềm
userSchema.methods.softDelete = async function () {
  this.isDeleted = true;
  this.deletedAt = new Date();
  return await this.save();
};

// Loại bỏ trường password khi chuyển đổi sang JSON
userSchema.methods.toJSON = function () {
  const userObject = this.toObject();
  delete userObject.password;
  return userObject;
};

const User = mongoose.model('User', userSchema);

module.exports = User;
