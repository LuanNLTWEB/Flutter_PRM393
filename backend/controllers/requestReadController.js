const mongoose = require('mongoose');
const RepairRequest = require('../models/RepairRequest');
const ServiceCategory = require('../models/ServiceCategory');
const Quotation = require('../models/Quotation');

const OBJECT_ID_REGEX = /^[0-9a-fA-F]{24}$/;
const VALID_STATUS = ['OPEN', 'QUOTED', 'ACCEPTED', 'CANCELLED'];
const VALID_URGENCY = ['low', 'medium', 'high', 'emergency'];
const MAX_FEED_ITEMS = 200;

// Yêu cầu OPEN và QUOTED đều còn nhận báo giá (chỉ ACCEPTED/CANCELLED mới chặn thợ),
// nên feed mặc định lấy cả hai để nhiều thợ cùng báo giá và khách mới so sánh được (UC-QUO-07).
const DEFAULT_FEED_STATUSES = ['OPEN', 'QUOTED'];

const URGENCY_RANK = { emergency: 4, high: 3, medium: 2, low: 1 };

// Thông tin công khai của Khách hàng được trả về Thợ (không kèm SĐT/email)
const CUSTOMER_PUBLIC_FIELDS = 'fullName avatar';

const toRadians = (deg) => (deg * Math.PI) / 180;

// Khoảng cách 2 điểm theo km
const haversineKm = (lat1, lng1, lat2, lng2) => {
  const R = 6371;
  const dLat = toRadians(lat2 - lat1);
  const dLng = toRadians(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRadians(lat1)) * Math.cos(toRadians(lat2)) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(a));
};

// Ẩn số điện thoại & địa chỉ chi tiết của Khách trước khi Thợ được chốt
const maskForTechnician = (doc) => {
  const obj = typeof doc.toObject === 'function' ? doc.toObject() : { ...doc };
  obj.contactPhone = '';
  if (obj.location) {
    obj.location = {
      ...obj.location,
      address: '',
      latitude: null,
      longitude: null,
    };
  }
  return obj;
};

const populateRequest = (query) =>
  query
    .populate('serviceCategoryId', 'name slug icon color basePrice')
    .populate('customerId', CUSTOMER_PUBLIC_FIELDS);

/**
 * @desc    Thợ xem danh sách yêu cầu còn nhận báo giá quanh khu vực (UC-QUO-01)
 *          + lọc theo danh mục dịch vụ/mức độ khẩn cấp (UC-QUO-02)
 *          Mặc định trả về cả OPEN và QUOTED để nhiều thợ cùng báo giá (UC-QUO-07).
 *          Kèm `quotesCount` (số thợ đang báo giá) và `hasQuoted`.
 *          Sắp xếp: nếu có tọa độ thì theo khoảng cách, không thì theo mức độ khẩn cấp
 * @route   GET /api/requests/nearby?status=OPEN,QUOTED&categorySlug=&urgency=&lat=&lng=&radiusKm=&page=&limit=
 * @access  Private (technician)
 */
// START UC-QUO-01 + UC-QUO-02
const getNearbyRequests = async (req, res) => {
  try {
    const {
      status = DEFAULT_FEED_STATUSES.join(','),
      categorySlug,
      urgency,
      lat,
      lng,
      radiusKm,
      page = 1,
      limit = 20,
    } = req.query;

    const statuses = String(status)
      .split(',')
      .map((s) => s.trim())
      .filter(Boolean);

    if (statuses.length === 0 || statuses.some((s) => !VALID_STATUS.includes(s))) {
      return res.status(400).json({
        success: false,
        message: 'Trạng thái yêu cầu không hợp lệ',
      });
    }

    const filter = { status: { $in: statuses } };

    // Lọc theo chuyên môn / danh mục dịch vụ (UC-QUO-02)
    if (categorySlug) {
      const category = await ServiceCategory.findOne({ slug: categorySlug });
      if (!category) {
        return res.status(404).json({
          success: false,
          message: 'Danh mục dịch vụ không tồn tại',
        });
      }
      filter.serviceCategoryId = category._id;
    }

    if (urgency) {
      if (!VALID_URGENCY.includes(urgency)) {
        return res.status(400).json({
          success: false,
          message: 'Mức độ khẩn cấp không hợp lệ',
        });
      }
      filter.urgency = urgency;
    }

    const originLat = lat !== undefined && lat !== '' ? parseFloat(lat) : null;
    const originLng = lng !== undefined && lng !== '' ? parseFloat(lng) : null;
    const radius =
      radiusKm !== undefined && radiusKm !== '' ? parseFloat(radiusKm) : null;

    const hasOrigin =
      originLat !== null &&
      originLng !== null &&
      Number.isFinite(originLat) &&
      Number.isFinite(originLng);

    let requests = await populateRequest(
      RepairRequest.find(filter).sort({ createdAt: -1 }).limit(MAX_FEED_ITEMS)
    ).lean();

    // Tính khoảng cách khi có tọa độ từ máy của Thợ
    if (hasOrigin) {
      requests = requests
        .map((item) => {
          const loc = item.location || {};
          let distanceKm = null;
          if (typeof loc.latitude === 'number' && typeof loc.longitude === 'number') {
            distanceKm = haversineKm(originLat, originLng, loc.latitude, loc.longitude);
          }
          return { ...item, distanceKm };
        })
        .filter((item) => radius === null || item.distanceKm === null || item.distanceKm <= radius)
        .sort((a, b) => {
          if (a.distanceKm === null && b.distanceKm === null) return 0;
          if (a.distanceKm === null) return 1;
          if (b.distanceKm === null) return -1;
          return a.distanceKm - b.distanceKm;
        });
    } else {
      // Chưa có tọa độ: ưu tiên yêu cầu khẩn cấp rồi mới đến mới nhất
      requests = requests.sort((a, b) => {
        const rankDiff =
          (URGENCY_RANK[b.urgency] || 0) - (URGENCY_RANK[a.urgency] || 0);
        if (rankDiff !== 0) return rankDiff;
        return new Date(b.createdAt) - new Date(a.createdAt);
      });
    }

    const pageNumber = Math.max(1, parseInt(page, 10) || 1);
    const pageSize = Math.max(1, Math.min(50, parseInt(limit, 10) || 20));
    const startIndex = (pageNumber - 1) * pageSize;
    const paged = requests.slice(startIndex, startIndex + pageSize);

    const requestIds = paged.map((item) => item._id);

    // Số thợ đang báo giá cho từng phiếu (chỉ đếm, không lộ giá hay thông tin thợ)
    let quoteCountMap = {};
    // Các phiếu mà chính thợ đang xem đã gửi báo giá rồi
    let myQuotedIds = new Set();

    if (requestIds.length > 0) {
      const [quoteCounts, myQuotes] = await Promise.all([
        Quotation.aggregate([
          { $match: { requestId: { $in: requestIds }, status: { $ne: 'RETRACTED' } } },
          { $group: { _id: '$requestId', count: { $sum: 1 } } },
        ]),
        Quotation.find({
          requestId: { $in: requestIds },
          technicianId: req.user._id,
          status: { $ne: 'RETRACTED' },
        })
          .select('requestId')
          .lean(),
      ]);

      quoteCounts.forEach((qc) => {
        quoteCountMap[qc._id.toString()] = qc.count;
      });
      myQuotedIds = new Set(myQuotes.map((q) => q.requestId.toString()));
    }

    // Che thông tin liên hệ của khách hàng cho Thợ
    const masked = paged.map((item) => {
      const id = item._id.toString();
      return {
        ...item,
        quotesCount: quoteCountMap[id] || 0,
        hasQuoted: myQuotedIds.has(id),
        contactPhone: '',
        location: item.location
          ? { ...item.location, address: '', latitude: null, longitude: null }
          : item.location,
      };
    });

    return res.status(200).json({
      success: true,
      message: 'Lấy danh sách yêu cầu gần đây thành công',
      data: {
        total: requests.length,
        page: pageNumber,
        totalPages: Math.max(1, Math.ceil(requests.length / pageSize)),
        hasLocation: hasOrigin,
        requests: masked,
      },
    });
  } catch (error) {
    console.error('getNearbyRequests error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi lấy danh sách yêu cầu',
      error: error.message,
    });
  }
};
// END UC-QUO-01 + UC-QUO-02

/**
 * @desc    Xem chi tiết 1 phiếu yêu cầu (UC-QUO-03)
 *          - Chủ yêu cầu: xem đầy đủ
 *          - Thợ: ẩn SĐT & địa chỉ cho tới khi nào thợ đó được chốt
 *          Kèm `quotesCount` và `hasQuoted`
 * @route   GET /api/requests/:id
 * @access  Private (user, technician, staff, admin)
 */
// START UC-QUO-03
const getRequestDetail = async (req, res) => {
  try {
    const { id } = req.params;

    if (!OBJECT_ID_REGEX.test(id)) {
      return res.status(400).json({
        success: false,
        message: 'Mã phiếu yêu cầu không hợp lệ',
      });
    }

    const request = await populateRequest(RepairRequest.findById(id)).lean();
    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy phiếu yêu cầu',
      });
    }

    const role = req.user.role;
    const isOwner =
      request.customerId && request.customerId._id
        ? request.customerId._id.toString() === req.user._id.toString()
        : request.customerId?.toString() === req.user._id.toString();

    let payload = request;

    if (role === 'technician') {
      // Thợ chỉ được thấy địa chỉ & SĐT khi mình là thợ đã được chốt.
      // Check theo quotation (không theo status đơn) để vẫn thấy địa chỉ
      // khi đơn đã tiến sang ON_THE_WAY / IN_PROGRESS / COMPLETED.
      const accepted = await Quotation.findOne({
        requestId: request._id,
        technicianId: req.user._id,
        status: 'ACCEPTED',
      })
        .select('_id')
        .lean();
      const hasWon = Boolean(accepted);

      if (!hasWon) {
        payload = maskForTechnician(request);
      }
    } else if (role === 'user' && !isOwner) {
      return res.status(403).json({
        success: false,
        message: 'Bạn không có quyền xem phiếu yêu cầu này',
      });
    }

    // Số thợ đang báo giá + cờ đánh dấu thợ đang xem đã gửi báo giá rồi (UC-QUO-07)
    const [quoteCount, myQuote] = await Promise.all([
      Quotation.countDocuments({
        requestId: request._id,
        status: { $ne: 'RETRACTED' },
      }),
      role === 'technician'
        ? Quotation.findOne({
            requestId: request._id,
            technicianId: req.user._id,
            status: { $ne: 'RETRACTED' },
          })
            .select('_id')
            .lean()
        : null,
    ]);

    payload = {
      ...payload,
      quotesCount: quoteCount,
      hasQuoted: Boolean(myQuote),
    };

    return res.status(200).json({
      success: true,
      message: 'Lấy chi tiết phiếu yêu cầu thành công',
      data: { repairRequest: payload },
    });
  } catch (error) {
    console.error('getRequestDetail error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Lỗi máy chủ khi lấy chi tiết phiếu yêu cầu',
      error: error.message,
    });
  }
};
// END UC-QUO-03

module.exports = {
  getNearbyRequests,
  getRequestDetail,
};
