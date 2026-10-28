const express = require('express');
const router = express.Router();
const { getMyInvoices } = require('../controllers/invoiceController');
const { protect, authorize } = require('../middlewares/auth');

// Hóa đơn là dữ liệu riêng tư của Khách hàng.
router.use(protect, authorize('user'));
router.get('/my', getMyInvoices);

module.exports = router;
