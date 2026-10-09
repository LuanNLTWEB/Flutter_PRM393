const express = require('express');
const cors = require('cors');
require('dotenv').config();

const connectDB = require('./config/db');

const app = express();

// Database Connection
connectDB();

// Middlewares
app.use(cors());
app.use(express.json());

// Routes
const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const adminRoutes = require('./routes/adminRoutes');
const reviewRoutes = require('./routes/reviewRoutes');
const technicianRoutes = require('./routes/technicianRoutes');
const serviceCategoryRoutes = require('./routes/serviceCategoryRoutes');
const repairRequestRoutes = require('./routes/repairRequestRoutes');

// Health Check Route
app.get('/api/health', (req, res) => {
  res.status(200).json({
    status: 'OK',
    message: 'HomeFix API is running',
  });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/reviews', reviewRoutes);
app.use('/api/technicians', technicianRoutes);
app.use('/api/categories', serviceCategoryRoutes);
app.use('/api/requests', repairRequestRoutes);
app.use('/api/repair-requests', repairRequestRoutes);

// Global Error Handler cho Upload và các Middleware
app.use((err, req, res, next) => {
  if (err) {
    console.error('API Error:', err.message);
    return res.status(400).json({
      success: false,
      message: err.message || 'Lỗi khi xử lý dữ liệu tải lên',
      error: err.code || err.name || 'UPLOAD_ERROR',
    });
  }
  next();
});

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

