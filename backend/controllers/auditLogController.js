const AuditLog = require('../models/AuditLog');

/**
 * Tiện ích ghi nhật ký hoạt động nội bộ
 * @param {Object} params
 * @param {Object} params.actor - Đối tượng req.user của người thao tác (phải là staff hoặc admin)
 * @param {string} params.action - Mã hành động (vd: KYC_APPROVE, KYC_REJECT...)
 * @param {string} params.actionTitle - Tiêu đề dễ hiểu (vd: Phê duyệt hồ sơ thợ...)
 * @param {string} [params.targetType] - 'Technician' | 'User' | 'Complaint' | 'ServiceCategory' | 'Other'
 * @param {string|mongoose.Types.ObjectId} [params.targetId] - ID của đối tượng
 * @param {string} [params.targetName] - Tên đối tượng (vd: Họ tên thợ, Tên danh mục)
 * @param {string} [params.details] - Lý do, ghi chú biên bản hoặc chi tiết thay đổi
 */
const logAudit = async ({
  actor,
  action,
  actionTitle,
  targetType = 'Other',
  targetId = '',
  targetName = '',
  details = '',
}) => {
  try {
    if (!actor || !['admin', 'staff'].includes(actor.role)) {
      return null;
    }

    const log = await AuditLog.create({
      actorId: actor._id,
      actorName: actor.fullName || 'Nhân viên quản trị',
      actorEmail: actor.email || '',
      actorRole: actor.role,
      action,
      actionTitle,
      targetType,
      targetId: targetId ? targetId.toString() : '',
      targetName: targetName ? targetName.trim() : '',
      details: details ? details.trim() : '',
    });

    return log;
  } catch (error) {
    // Không ném lỗi ra ngoài để tránh ảnh hưởng đến luồng chính
    console.error('Lỗi khi lưu Audit Log:', error.message);
    return null;
  }
};

/**
 * @desc    Lấy danh sách nhật ký hoạt động (Audit Logs)
 * @route   GET /api/admin/audit-logs
 * @access  Private (Admin, Staff)
 */
const getAuditLogs = async (req, res) => {
  try {
    const { role, actionGroup, search, page = 1, limit = 50 } = req.query;

    const query = {};

    // 1. Lọc theo vai trò của người thao tác ('admin' hoặc 'staff')
    if (role && ['admin', 'staff'].includes(role)) {
      query.actorRole = role;
    }

    // 2. Lọc theo nhóm hành động kiểm duyệt
    if (actionGroup) {
      switch (actionGroup.toUpperCase()) {
        case 'KYC':
          query.action = { $in: ['KYC_APPROVE', 'KYC_REJECT'] };
          break;
        case 'USER':
          query.action = { $in: ['USER_LOCK', 'USER_UNLOCK', 'ROLE_UPDATE', 'STAFF_CREATE'] };
          break;
        case 'COMPLAINT':
          query.action = { $regex: /^COMPLAINT_/ };
          break;
        case 'CATEGORY':
          query.action = { $regex: /^CATEGORY_/ };
          break;
        default:
          break;
      }
    }

    // 3. Tìm kiếm theo tên người thực hiện, email hoặc tên đối tượng
    if (search && search.trim() !== '') {
      const searchRegex = new RegExp(search.trim(), 'i');
      query.$or = [
        { actorName: searchRegex },
        { actorEmail: searchRegex },
        { targetName: searchRegex },
        { actionTitle: searchRegex },
        { details: searchRegex },
      ];
    }

    const pageNumber = Math.max(1, parseInt(page, 10) || 1);
    const pageSize = Math.max(1, parseInt(limit, 10) || 50);
    const skip = (pageNumber - 1) * pageSize;

    const [total, logs] = await Promise.all([
      AuditLog.countDocuments(query),
      AuditLog.find(query)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(pageSize),
    ]);

    return res.status(200).json({
      success: true,
      message: 'Lấy danh sách nhật ký hoạt động thành công',
      data: {
        logs,
        total,
        page: pageNumber,
        totalPages: Math.ceil(total / pageSize) || 1,
      },
    });
  } catch (error) {
    console.error('Lỗi khi lấy nhật ký hoạt động:', error);
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi lấy nhật ký hoạt động',
      error: error.message,
    });
  }
};

/**
 * @desc    Lấy thống kê nhanh về các thao tác kiểm duyệt
 * @route   GET /api/admin/audit-logs/stats
 * @access  Private (Admin, Staff)
 */
const getAuditLogStats = async (req, res) => {
  try {
    const [total, adminCount, staffCount, kycCount, userCount, complaintCount, categoryCount] =
      await Promise.all([
        AuditLog.countDocuments(),
        AuditLog.countDocuments({ actorRole: 'admin' }),
        AuditLog.countDocuments({ actorRole: 'staff' }),
        AuditLog.countDocuments({ action: { $in: ['KYC_APPROVE', 'KYC_REJECT'] } }),
        AuditLog.countDocuments({ action: { $in: ['USER_LOCK', 'USER_UNLOCK', 'ROLE_UPDATE', 'STAFF_CREATE'] } }),
        AuditLog.countDocuments({ action: { $regex: /^COMPLAINT_/ } }),
        AuditLog.countDocuments({ action: { $regex: /^CATEGORY_/ } }),
      ]);

    return res.status(200).json({
      success: true,
      message: 'Lấy thống kê nhật ký hoạt động thành công',
      data: {
        total,
        adminCount,
        staffCount,
        kycCount,
        userCount,
        complaintCount,
        categoryCount,
      },
    });
  } catch (error) {
    console.error('Lỗi khi lấy thống kê nhật ký hoạt động:', error);
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi lấy thống kê nhật ký hoạt động',
      error: error.message,
    });
  }
};

module.exports = {
  logAudit,
  getAuditLogs,
  getAuditLogStats,
};
