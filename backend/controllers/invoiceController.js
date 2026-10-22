const RepairRequest = require('../models/RepairRequest');
const Quotation = require('../models/Quotation');

/**
 * @desc    Lấy hóa đơn của các yêu cầu đã hoàn tất để Khách hàng lưu/xem offline
 * @route   GET /api/invoices/my
 * @access  Private (Customer)
 */
const getMyInvoices = async (req, res) => {
  try {
    const completedRequests = await RepairRequest.find({
      customerId: req.user._id,
      status: 'COMPLETED',
    })
      .populate('serviceCategoryId', 'name basePrice')
      .populate('assignedTechnicianId', 'fullName phoneNumber')
      .sort({ updatedAt: -1 });

    const requestIds = completedRequests.map((request) => request._id);
    const acceptedQuotations = requestIds.length
      ? await Quotation.find({
          requestId: { $in: requestIds },
          status: 'ACCEPTED',
        }).select('requestId labourCost partsCost total note')
      : [];

    const quotationByRequestId = new Map(
      acceptedQuotations.map((quotation) => [
        quotation.requestId.toString(),
        quotation,
      ])
    );

    const invoices = completedRequests.map((request) => {
      const quotation = quotationByRequestId.get(request._id.toString());
      const category = request.serviceCategoryId;
      const technician = request.assignedTechnicianId;

      // Đơn cũ có thể chưa có báo giá được chốt. Khi đó chỉ hiển thị giá sàn
      // đã lưu ở danh mục, không tự thêm chi phí linh kiện.
      const labourCost = Number(quotation?.labourCost ?? category?.basePrice ?? 0);
      const partsCost = Number(quotation?.partsCost ?? 0);
      const total = Number(quotation?.total ?? labourCost + partsCost);

      return {
        id: request._id,
        invoiceNumber: `HF-${request._id.toString().slice(-8).toUpperCase()}`,
        requestTitle: request.title,
        serviceCategoryName: category?.name || 'Dịch vụ sửa chữa',
        technicianName: technician?.fullName || 'Chưa cập nhật',
        technicianPhone: technician?.phoneNumber || '',
        address: request.location?.address || 'Chưa cập nhật địa chỉ',
        costs: {
          labourCost,
          partsCost,
          total,
        },
        quotationNote: quotation?.note || '',
        completedAt: request.updatedAt,
        issuedAt: request.updatedAt,
      };
    });

    return res.status(200).json({
      success: true,
      message: 'Lấy danh sách hóa đơn thành công',
      data: {
        invoices,
        total: invoices.length,
      },
    });
  } catch (error) {
    console.error('getMyInvoices error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Không thể lấy danh sách hóa đơn',
      error: error.message,
    });
  }
};

module.exports = { getMyInvoices };
