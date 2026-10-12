const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middlewares/auth');
const {
  getInvoice,
  selectPaymentMethod,
} = require('../controllers/paymentController');

router.use(protect, authorize('user'));

router.get('/requests/:id/invoice', getInvoice);
router.put('/requests/:id/method', selectPaymentMethod);

module.exports = router;
