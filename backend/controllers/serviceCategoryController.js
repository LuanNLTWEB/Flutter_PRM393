const ServiceCategory = require('../models/ServiceCategory');
const RepairRequest = require('../models/RepairRequest');

// Hàm tạo slug từ tiếng Việt có dấu
const slugify = (text) => {
  if (!text) return '';
  return text
    .toString()
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[đĐ]/g, 'd')
    .replace(/[^a-z0-9\s-]/g, '')
    .trim()
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-');
};

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
    const { all } = req.query;
    const filter = (all === 'true' || all === '1') ? {} : { isActive: true };

    let categories = await ServiceCategory.find(filter).sort({ sortOrder: 1, createdAt: 1 });

    // Tự động gieo dữ liệu mẫu nếu bảng categories còn trống
    if (categories.length === 0) {
      await ServiceCategory.insertMany(DEFAULT_CATEGORIES);
      categories = await ServiceCategory.find(filter).sort({ sortOrder: 1, createdAt: 1 });
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

/**
 * @desc    Tìm kiếm danh mục dịch vụ theo từ khóa
 * @route   GET /api/categories/search?keyword=...
 * @access  Public
 */
const searchCategories = async (req, res) => {
  try {
    const { keyword = '' } = req.query;
    const trimmed = (keyword || '').trim();

    let query = { isActive: true };
    if (trimmed) {
      const regex = new RegExp(trimmed, 'i');
      query.$or = [
        { name: regex },
        { description: regex },
        { commonIssues: regex },
        { slug: regex },
      ];
    }

    const categories = await ServiceCategory.find(query).sort({ sortOrder: 1, createdAt: 1 });

    return res.status(200).json({
      success: true,
      message: `Tìm thấy ${categories.length} danh mục dịch vụ phù hợp`,
      data: {
        total: categories.length,
        keyword: trimmed,
        categories,
      },
    });
  } catch (error) {
    console.error('Lỗi khi tìm kiếm danh mục dịch vụ:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Không thể tìm kiếm danh mục dịch vụ',
      error: error.message,
    });
  }
};

/**
 * @desc    Lấy toàn bộ danh mục dịch vụ cho Staff/Admin quản trị (kèm số liệu thống kê)
 * @route   GET /api/categories/manage
 * @access  Private (Staff / Admin)
 */
const getAllCategoriesForManage = async (req, res) => {
  try {
    let categories = await ServiceCategory.find().sort({ sortOrder: 1, createdAt: -1 });

    if (categories.length === 0) {
      await ServiceCategory.insertMany(DEFAULT_CATEGORIES);
      categories = await ServiceCategory.find().sort({ sortOrder: 1, createdAt: -1 });
    }

    const total = categories.length;
    const activeCount = categories.filter((c) => c.isActive).length;
    const inactiveCount = total - activeCount;

    return res.status(200).json({
      success: true,
      message: 'Lấy danh sách quản trị danh mục thành công',
      data: {
        total,
        activeCount,
        inactiveCount,
        categories,
      },
    });
  } catch (error) {
    console.error('Lỗi khi lấy danh mục quản trị:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Không thể tải danh sách danh mục quản trị',
      error: error.message,
    });
  }
};

/**
 * @desc    Tạo mới một danh mục dịch vụ & giá sàn (UC-STF-02)
 * @route   POST /api/categories
 * @access  Private (Staff / Admin)
 */
const createCategory = async (req, res) => {
  try {
    const {
      name,
      slug,
      description,
      icon,
      color,
      basePrice,
      commonIssues,
      isActive,
      sortOrder,
    } = req.body;

    if (!name || !name.trim()) {
      return res.status(400).json({
        success: false,
        message: 'Tên nhóm dịch vụ sửa chữa là bắt buộc',
      });
    }

    if (!description || !description.trim()) {
      return res.status(400).json({
        success: false,
        message: 'Mô tả dịch vụ là bắt buộc',
      });
    }

    // Kiểm tra tên trùng lặp
    const existing = await ServiceCategory.findOne({
      name: { $regex: new RegExp(`^${name.trim()}$`, 'i') },
    });
    if (existing) {
      return res.status(400).json({
        success: false,
        message: `Danh mục "${name.trim()}" đã tồn tại trên hệ thống`,
      });
    }

    let finalSlug = slug && slug.trim() ? slugify(slug) : slugify(name);
    const slugExists = await ServiceCategory.findOne({ slug: finalSlug });
    if (slugExists) {
      finalSlug = `${finalSlug}-${Date.now().toString().slice(-4)}`;
    }

    let parsedIssues = [];
    if (Array.isArray(commonIssues)) {
      parsedIssues = commonIssues.map((s) => s.toString().trim()).filter(Boolean);
    } else if (typeof commonIssues === 'string' && commonIssues.trim()) {
      parsedIssues = commonIssues.split(',').map((s) => s.trim()).filter(Boolean);
    }

    const newCategory = await ServiceCategory.create({
      name: name.trim(),
      slug: finalSlug,
      description: description.trim(),
      icon: icon && icon.trim() ? icon.trim() : 'home_repair_service',
      color: color && color.trim() ? color.trim() : '#2563EB',
      basePrice: typeof basePrice === 'number' && basePrice >= 0 ? basePrice : Number(basePrice) || 150000,
      commonIssues: parsedIssues,
      isActive: typeof isActive === 'boolean' ? isActive : true,
      sortOrder: Number(sortOrder) || 0,
    });

    return res.status(201).json({
      success: true,
      message: 'Tạo danh mục dịch vụ mới thành công',
      data: {
        category: newCategory,
      },
    });
  } catch (error) {
    console.error('Lỗi khi tạo danh mục dịch vụ:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Không thể tạo danh mục dịch vụ',
      error: error.message,
    });
  }
};

/**
 * @desc    Cập nhật thông tin danh mục, icon và giá sàn (UC-STF-02)
 * @route   PUT /api/categories/:id
 * @access  Private (Staff / Admin)
 */
const updateCategory = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      name,
      slug,
      description,
      icon,
      color,
      basePrice,
      commonIssues,
      isActive,
      sortOrder,
    } = req.body;

    const category = await ServiceCategory.findById(id);
    if (!category) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy danh mục dịch vụ yêu cầu',
      });
    }

    if (name && name.trim()) {
      const duplicate = await ServiceCategory.findOne({
        _id: { $ne: id },
        name: { $regex: new RegExp(`^${name.trim()}$`, 'i') },
      });
      if (duplicate) {
        return res.status(400).json({
          success: false,
          message: `Tên danh mục "${name.trim()}" đã được sử dụng`,
        });
      }
      category.name = name.trim();
      if (!slug) {
        category.slug = slugify(name);
      }
    }

    if (slug && slug.trim()) {
      category.slug = slugify(slug);
    }
    if (description !== undefined) category.description = description.trim();
    if (icon !== undefined) category.icon = icon.trim() || 'home_repair_service';
    if (color !== undefined) category.color = color.trim() || '#2563EB';
    if (basePrice !== undefined) {
      const num = Number(basePrice);
      if (!isNaN(num) && num >= 0) category.basePrice = num;
    }
    if (commonIssues !== undefined) {
      if (Array.isArray(commonIssues)) {
        category.commonIssues = commonIssues.map((s) => s.toString().trim()).filter(Boolean);
      } else if (typeof commonIssues === 'string') {
        category.commonIssues = commonIssues.split(',').map((s) => s.trim()).filter(Boolean);
      }
    }
    if (isActive !== undefined) category.isActive = Boolean(isActive);
    if (sortOrder !== undefined) category.sortOrder = Number(sortOrder) || 0;

    await category.save();

    return res.status(200).json({
      success: true,
      message: 'Cập nhật danh mục dịch vụ thành công',
      data: {
        category,
      },
    });
  } catch (error) {
    console.error('Lỗi khi cập nhật danh mục dịch vụ:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Không thể cập nhật danh mục dịch vụ',
      error: error.message,
    });
  }
};

/**
 * @desc    Bật/Tắt trạng thái hoạt động danh mục dịch vụ (Ẩn/Hiện)
 * @route   PUT /api/categories/:id/status
 * @access  Private (Staff / Admin)
 */
const toggleCategoryStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const category = await ServiceCategory.findById(id);
    if (!category) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy danh mục dịch vụ yêu cầu',
      });
    }

    category.isActive = !category.isActive;
    await category.save();

    return res.status(200).json({
      success: true,
      message: `Đã ${category.isActive ? 'kích hoạt' : 'tạm ẩn'} danh mục "${category.name}"`,
      data: {
        category,
      },
    });
  } catch (error) {
    console.error('Lỗi khi đổi trạng thái danh mục:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Không thể đổi trạng thái danh mục',
      error: error.message,
    });
  }
};

/**
 * @desc    Xóa danh mục dịch vụ (Tự động chuyển Tạm ẩn nếu đang có đơn yêu cầu)
 * @route   DELETE /api/categories/:id
 * @access  Private (Staff / Admin)
 */
const deleteCategory = async (req, res) => {
  try {
    const { id } = req.params;
    const category = await ServiceCategory.findById(id);
    if (!category) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy danh mục dịch vụ cần xóa',
      });
    }

    const linkedRequests = await RepairRequest.countDocuments({ serviceCategoryId: id });
    if (linkedRequests > 0) {
      category.isActive = false;
      await category.save();
      return res.status(200).json({
        success: true,
        message: `Danh mục đang được liên kết với ${linkedRequests} đơn yêu cầu nên đã được chuyển sang trạng thái "Tạm ẩn" để bảo toàn dữ liệu.`,
        data: {
          category,
          softDeleted: true,
        },
      });
    }

    await ServiceCategory.findByIdAndDelete(id);
    return res.status(200).json({
      success: true,
      message: `Đã xóa vĩnh viễn danh mục "${category.name}"`,
      data: {
        deletedId: id,
        softDeleted: false,
      },
    });
  } catch (error) {
    console.error('Lỗi khi xóa danh mục dịch vụ:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Không thể xóa danh mục dịch vụ',
      error: error.message,
    });
  }
};

module.exports = {
  getCategories,
  getCategoryByIdentifier,
  searchCategories,
  getAllCategoriesForManage,
  createCategory,
  updateCategory,
  toggleCategoryStatus,
  deleteCategory,
};
