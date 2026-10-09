const express = require('express');
const router = express.Router();
const { register, login } = require('../controllers/authController');
const { registerTechnician } = require('../controllers/technicianController');
const upload = require('../middlewares/upload');

// POST /api/auth/register (Khách hàng)
router.post('/register', register);

// POST /api/auth/register-technician (Thợ kèm CCCD & Bằng cấp)
router.post(
  '/register-technician',
  upload.fields([
    { name: 'idCardFront', maxCount: 1 },
    { name: 'idCardBack', maxCount: 1 },
    { name: 'certificates', maxCount: 10 },
  ]),
  registerTechnician
);

// POST /api/auth/login
router.post('/login', login);

module.exports = router;

