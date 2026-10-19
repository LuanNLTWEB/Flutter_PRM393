const User = require('../models/User');
const { uploadStream } = require('../config/cloudinary');

/**
 * @desc    Đăng ký tài khoản Thợ (kèm upload CCCD 2 mặt và Chứng chỉ)
 * @route   POST /api/auth/register-technician
 * @access  Public
 */
const registerTechnician = async (req, res) => {
  try {
    const {
      fullName,
      email,
      phoneNumber,
      password,
      confirmPassword,
      dateOfBirth,
      gender,
      skills,
      experienceYears,
      bio,
    } = req.body;

    // 1. Kiểm tra các thông tin cá nhân bắt buộc
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
        message: 'Vui lòng điền đầy đủ các thông tin cá nhân bắt buộc',
      });
    }

    // 2. Kiểm tra mật khẩu khớp nhau
    if (password !== confirmPassword) {
      return res.status(400).json({
        success: false,
        message: 'Mật khẩu và xác nhận mật khẩu không trùng khớp',
      });
    }

    if (password.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Mật khẩu phải có ít nhất 6 ký tự',
      });
    }

    // 3. Kiểm tra ảnh CCCD (Mặt trước & Mặt sau bắt buộc khi đăng ký Thợ)
    const files = req.files || {};
    const idCardFrontFile = files.idCardFront ? files.idCardFront[0] : null;
    const idCardBackFile = files.idCardBack ? files.idCardBack[0] : null;
    const certificateFiles = files.certificates || [];

    if (!idCardFrontFile || !idCardBackFile) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng tải lên cả 2 mặt ảnh CCCD/CMND để xác minh danh tính',
      });
    }

    // 4. Kiểm tra email và số điện thoại đã tồn tại chưa
    const existingEmail = await User.findOne({ email: email.toLowerCase().trim() });
    if (existingEmail) {
      return res.status(409).json({
        success: false,
        message: 'Email này đã được sử dụng trong hệ thống',
      });
    }

    const existingPhone = await User.findOne({ phoneNumber: phoneNumber.trim() });
    if (existingPhone) {
      return res.status(409).json({
        success: false,
        message: 'Số điện thoại này đã được sử dụng trong hệ thống',
      });
    }

    // 5. Upload CCCD lên Cloudinary
    const [frontUpload, backUpload] = await Promise.all([
      uploadStream(idCardFrontFile.buffer, {
        folder: 'homefix/technicians/id_cards',
      }),
      uploadStream(idCardBackFile.buffer, {
        folder: 'homefix/technicians/id_cards',
      }),
    ]);

    // 6. Upload các chứng chỉ/bằng cấp (nếu có)
    const certificateUrls = [];
    if (certificateFiles.length > 0) {
      const certUploadPromises = certificateFiles.map((file) =>
        uploadStream(file.buffer, {
          folder: 'homefix/technicians/certificates',
        })
      );
      const certResults = await Promise.all(certUploadPromises);
      certResults.forEach((item) => certificateUrls.push(item.url));
    }

    // Xử lý mảng kỹ năng
    let parsedSkills = [];
    if (Array.isArray(skills)) {
      parsedSkills = skills;
    } else if (typeof skills === 'string') {
      parsedSkills = skills
        .split(',')
        .map((s) => s.trim())
        .filter((s) => s.length > 0);
    }

    // 7. Tạo mới tài khoản Thợ ở trạng thái CHỜ DUYỆT (pending)
    const newTechnician = await User.create({
      fullName: fullName.trim(),
      email: email.toLowerCase().trim(),
      phoneNumber: phoneNumber.trim(),
      password,
      dateOfBirth: new Date(dateOfBirth),
      gender,
      role: 'technician',
      isActive: true,
      technicianProfile: {
        skills: parsedSkills,
        experienceYears: Number(experienceYears) || 0,
        bio: bio ? bio.trim() : '',
        idCardFront: frontUpload.url,
        idCardBack: backUpload.url,
        certificates: certificateUrls,
        approvalStatus: 'pending',
        rejectionReason: '',
        isAvailable: false, // Chưa duyệt không thể nhận việc
        completedJobsCount: 0,
        rating: 5.0,
        reviewCount: 0,
      },
    });

    return res.status(201).json({
      success: true,
      message:
        'Đăng ký tài khoản Thợ thành công! Hồ sơ của bạn đang được chuyển đến Quản trị viên xét duyệt (KYC).',
      data: newTechnician,
    });
  } catch (error) {
    console.error('Lỗi khi đăng ký Thợ:', error);
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi đăng ký tài khoản Thợ',
      error: error.message,
    });
  }
};

/**
 * @desc    Lấy danh sách thợ công khai đã được duyệt (Dành cho Khách hàng)
 * @route   GET /api/technicians
 * @access  Public
 */
const getPublicTechnicians = async (req, res) => {
  try {
    const { skill, search, page = 1, limit = 20 } = req.query;

    const query = {
      role: 'technician',
      isActive: true,
      'technicianProfile.approvalStatus': 'approved',
    };

    if (skill && skill.trim() !== '') {
      query['technicianProfile.skills'] = { $in: [new RegExp(skill.trim(), 'i')] };
    }

    if (search && search.trim() !== '') {
      const searchRegex = new RegExp(search.trim(), 'i');
      query.$or = [
        { fullName: searchRegex },
        { 'technicianProfile.bio': searchRegex },
        { 'technicianProfile.skills': { $in: [searchRegex] } },
      ];
    }

    const pageNumber = Math.max(1, parseInt(page, 10) || 1);
    const pageSize = Math.max(1, parseInt(limit, 10) || 20);
    const skip = (pageNumber - 1) * pageSize;

    const [total, rawTechnicians] = await Promise.all([
      User.countDocuments(query),
      User.find(query)
        .select(
          'fullName email phoneNumber avatar technicianProfile.skills technicianProfile.experienceYears technicianProfile.bio technicianProfile.rating technicianProfile.reviewCount technicianProfile.completedJobsCount technicianProfile.isAvailable createdAt'
        )
        .sort({ 'technicianProfile.rating': -1, createdAt: -1 })
        .skip(skip)
        .limit(pageSize),
    ]);

    return res.status(200).json({
      success: true,
      message: 'Lấy danh sách thợ thành công',
      data: {
        technicians: rawTechnicians,
        total,
        page: pageNumber,
        totalPages: Math.ceil(total / pageSize) || 1,
      },
    });
  } catch (error) {
    console.error('Lỗi khi lấy danh sách thợ:', error);
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi lấy danh sách thợ',
      error: error.message,
    });
  }
};

/**
 * @desc    Lấy chi tiết hồ sơ công khai của Thợ (Portfolio dành cho Khách hàng)
 * @route   GET /api/technicians/:id
 * @access  Public
 */
const getPublicTechnicianById = async (req, res) => {
  try {
    const { id } = req.params;

    const technician = await User.findOne({
      _id: id,
      role: 'technician',
      isActive: true,
      'technicianProfile.approvalStatus': 'approved',
    }).select(
      'fullName email phoneNumber avatar gender technicianProfile.skills technicianProfile.experienceYears technicianProfile.bio technicianProfile.certificates technicianProfile.rating technicianProfile.reviewCount technicianProfile.completedJobsCount technicianProfile.isAvailable createdAt'
    );

    if (!technician) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy thông tin thợ hoặc thợ chưa được phê duyệt',
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Lấy hồ sơ thợ thành công',
      data: technician,
    });
  } catch (error) {
    console.error('Lỗi khi lấy hồ sơ thợ:', error);
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi lấy chi tiết hồ sơ thợ',
      error: error.message,
    });
  }
};

/**
 * @desc    Thợ bật/tắt trạng thái nhận việc
 * @route   PUT /api/technicians/status/availability
 * @access  Private (Technician only)
 */
const toggleAvailability = async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    if (!user || user.role !== 'technician') {
      return res.status(403).json({
        success: false,
        message: 'Chỉ tài khoản Thợ mới có thể thay đổi trạng thái nhận việc',
      });
    }

    if (user.technicianProfile?.approvalStatus !== 'approved') {
      return res.status(400).json({
        success: false,
        message: 'Tài khoản chưa được duyệt KYC, không thể nhận việc',
      });
    }

    const { isAvailable } = req.body;
    user.technicianProfile.isAvailable =
      typeof isAvailable === 'boolean'
        ? isAvailable
        : !user.technicianProfile.isAvailable;

    await user.save();

    return res.status(200).json({
      success: true,
      message: user.technicianProfile.isAvailable
        ? 'Đã BẬT trạng thái sẵn sàng nhận việc'
        : 'Đã TẮT trạng thái nhận việc (Tạm nghỉ)',
      data: {
        isAvailable: user.technicianProfile.isAvailable,
      },
    });
  } catch (error) {
    console.error('Lỗi khi cập nhật trạng thái nhận việc:', error);
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi cập nhật trạng thái nhận việc',
      error: error.message,
    });
  }
};

/**
 * @desc    Cập nhật thông tin tay nghề, chuyên môn và chứng chỉ của Thợ
 * @route   PUT /api/technicians/skills
 * @access  Private (Technician only)
 */
const updateTechnicianSkills = async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    if (!user || user.role !== 'technician') {
      return res.status(403).json({
        success: false,
        message: 'Chỉ tài khoản Thợ mới có quyền cập nhật hồ sơ tay nghề',
      });
    }

    const { skills, experienceYears, bio, existingCertificates } = req.body;

    if (!user.technicianProfile) {
      user.technicianProfile = {
        skills: [],
        experienceYears: 0,
        bio: '',
        certificates: [],
      };
    }

    // 1. Cập nhật danh sách kỹ năng / chuyên môn
    if (skills !== undefined) {
      let parsedSkills = [];
      if (Array.isArray(skills)) {
        parsedSkills = skills.map((s) => String(s).trim()).filter((s) => s.length > 0);
      } else if (typeof skills === 'string') {
        try {
          const jsonParsed = JSON.parse(skills);
          if (Array.isArray(jsonParsed)) {
            parsedSkills = jsonParsed.map((s) => String(s).trim()).filter((s) => s.length > 0);
          } else {
            parsedSkills = skills
              .split(',')
              .map((s) => s.trim())
              .filter((s) => s.length > 0);
          }
        } catch (_) {
          parsedSkills = skills
            .split(',')
            .map((s) => s.trim())
            .filter((s) => s.length > 0);
        }
      }
      user.technicianProfile.skills = parsedSkills;
    }

    // 2. Cập nhật số năm kinh nghiệm
    if (experienceYears !== undefined) {
      const exp = Number(experienceYears);
      if (!isNaN(exp) && exp >= 0) {
        user.technicianProfile.experienceYears = exp;
      }
    }

    // 3. Cập nhật tiểu sử / bio
    if (bio !== undefined) {
      user.technicianProfile.bio = String(bio).trim();
    }

    // 4. Xử lý chứng chỉ: giữ lại chứng chỉ cũ nếu có existingCertificates
    let currentCerts = [...(user.technicianProfile.certificates || [])];
    if (existingCertificates !== undefined) {
      let keptCerts = [];
      if (Array.isArray(existingCertificates)) {
        keptCerts = existingCertificates.map((c) => String(c).trim()).filter((c) => c.length > 0);
      } else if (typeof existingCertificates === 'string') {
        try {
          const jsonParsed = JSON.parse(existingCertificates);
          if (Array.isArray(jsonParsed)) {
            keptCerts = jsonParsed.map((c) => String(c).trim()).filter((c) => c.length > 0);
          } else if (existingCertificates.trim().length > 0) {
            keptCerts = existingCertificates.split(',').map((c) => c.trim()).filter((c) => c.length > 0);
          }
        } catch (_) {
          if (existingCertificates.trim().length > 0) {
            keptCerts = existingCertificates.split(',').map((c) => c.trim()).filter((c) => c.length > 0);
          }
        }
      }
      currentCerts = keptCerts;
    }

    // Upload các file chứng chỉ mới tải lên (nếu có)
    const files = req.files || [];
    if (files.length > 0) {
      const uploadPromises = files.map((file) =>
        uploadStream(file.buffer, {
          folder: 'homefix/technicians/certificates',
        })
      );
      const results = await Promise.all(uploadPromises);
      results.forEach((item) => currentCerts.push(item.url));
    }

    user.technicianProfile.certificates = currentCerts;

    await user.save();

    return res.status(200).json({
      success: true,
      message: 'Cập nhật hồ sơ tay nghề và chứng chỉ thành công',
      data: user,
    });
  } catch (error) {
    console.error('Lỗi khi cập nhật hồ sơ tay nghề thợ:', error);
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi cập nhật hồ sơ tay nghề',
      error: error.message,
    });
  }
};

module.exports = {
  registerTechnician,
  getPublicTechnicians,
  getPublicTechnicianById,
  toggleAvailability,
  updateTechnicianSkills,
};
