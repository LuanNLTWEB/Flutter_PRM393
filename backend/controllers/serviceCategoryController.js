const ServiceCategory = require('../models/ServiceCategory');

// Dữ liệu mẫu danh mục dịch vụ ban đầu nếu cơ sở dữ liệu chưa có
const DEFAULT_CATEGORIES = [
  {
    name: 'Sửa chữa điện',
    slug: 'sua-chua-dien',
    description: 'Xử lý chập điện, mất điện, lắp đặt thay thế ổ cắm, công tắc, bóng đèn, aptomat và dây dẫn an toàn.',
    icon: 'electric_bolt',
    color: '#D97706',
    basePrice: 150000,
    commonIssues: [
      'Chập cháy điện âm tường',
      'Aptomat nhảy liên tục',
      'Hỏng ổ cắm, công tắc',
      'Thay mới bóng đèn, đèn trần',
      'Lắp đặt thêm đường điện',
    ],
    sortOrder: 1,
  },
  {
    name: 'Sửa chữa nước',
    slug: 'sua-chua-nuoc',
    description: 'Sửa đường ống nước rò rỉ, thông tắc bồn cầu, thay vòi sen, van nước, máy bơm nước gia đình.',
    icon: 'water_drop',
    color: '#2563EB',
    basePrice: 150000,
    commonIssues: [
      'Rò rỉ ống nước ngầm',
      'Gãy van nước, hỏng vòi sen',
      'Tắc bồn rửa chén, bồn cầu',
      'Hỏng phao máy bơm nước',
      'Nước chảy yếu, mất nước',
    ],
    sortOrder: 2,
  },
  {
    name: 'Điện lạnh & Điều hòa',
    slug: 'dien-lanh-dieu-hoa',
    description: 'Bảo dưỡng, nạp gas, sửa máy lạnh không mát, tủ lạnh không đông đá, máy giặt không vắt.',
    icon: 'ac_unit',
    color: '#0891B2',
    basePrice: 200000,
    commonIssues: [
      'Điều hòa không mát, xì gas',
      'Chảy nước ở dàn lạnh',
      'Tủ lạnh mất lạnh, kêu to',
      'Máy giặt rung lắc, không xả nước',
      'Vệ sinh máy lạnh định kỳ',
    ],
    sortOrder: 3,
  },
  {
    name: 'Sửa Laptop & Máy tính',
    slug: 'sua-laptop-may-tinh',
    description: 'Sửa máy tính không lên nguồn, cài win, nâng cấp SSD/RAM, vệ sinh laptop, sửa bàn phím, màn hình.',
    icon: 'laptop_chromebook',
    color: '#7C3AED',
    basePrice: 180000,
    commonIssues: [
      'Máy tính bật không lên',
      'Màn hình xanh, máy chạy chậm',
      'Hỏng bàn phím, chai pin',
      'Vệ sinh tra keo tản nhiệt',
      'Cài lại hệ điều hành & phần mềm',
    ],
    sortOrder: 4,
  },
  {
    name: 'Bảo trì & Khóa cửa',
    slug: 'bao-tri-khoa-cua',
    description: 'Sửa khóa cửa kẹt, thay ổ khóa mới, sửa cửa nhôm kính, bản lề cửa gỗ và các lỗi kết cấu dân dụng.',
    icon: 'home_repair_service',
    color: '#EA580C',
    basePrice: 150000,
    commonIssues: [
      'Kẹt khóa cửa tay gạt/tay nắm tròn',
      'Cửa xệ cánh, kẹt ray trượt',
      'Bản lề rỉ sét, kêu cọt kẹt',
      'Thay mới tay nắm & ổ khóa',
      'Bắn silicon chống dột mái kính',
    ],
    sortOrder: 5,
  },
];

/**
 * @desc    Lấy danh sách tất cả các danh mục dịch vụ đang kích hoạt
 * @route   GET /api/categories
 * @access  Public
 */
const getCategories = async (req, res) => {
  try {
    let categories = await ServiceCategory.find({ isActive: true }).sort({ sortOrder: 1, createdAt: 1 });

    // Tự động gieo dữ liệu mẫu nếu bảng categories còn trống
    if (categories.length === 0) {
      await ServiceCategory.insertMany(DEFAULT_CATEGORIES);
      categories = await ServiceCategory.find({ isActive: true }).sort({ sortOrder: 1, createdAt: 1 });
    }

    return res.status(200).json({
      success: true,
      message: 'Lấy danh mục dịch vụ thành công',
      data: {
        total: categories.length,
        categories,
      },
    });
  } catch (error) {
    console.error('Lỗi khi lấy danh mục dịch vụ:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Không thể tải danh sách danh mục dịch vụ',
      error: error.message,
    });
  }
};

/**
 * @desc    Lấy chi tiết một danh mục dịch vụ theo slug hoặc id
 * @route   GET /api/categories/:identifier
 * @access  Public
 */
const getCategoryByIdentifier = async (req, res) => {
  try {
    const { identifier } = req.params;
    let category = await ServiceCategory.findOne({
      $or: [{ slug: identifier }, { _id: identifier.match(/^[0-9a-fA-F]{24}$/) ? identifier : null }],
      isActive: true,
    });

    if (!category) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy danh mục dịch vụ yêu cầu',
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Lấy chi tiết danh mục dịch vụ thành công',
      data: {
        category,
      },
    });
  } catch (error) {
    console.error('Lỗi khi lấy chi tiết danh mục dịch vụ:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Không thể tải chi tiết danh mục dịch vụ',
      error: error.message,
    });
  }
};

module.exports = {
  getCategories,
  getCategoryByIdentifier,
};
