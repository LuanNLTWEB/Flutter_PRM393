const mongoose = require('mongoose');

const serviceCategorySchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Tên danh mục dịch vụ là bắt buộc'],
      trim: true,
      unique: true,
    },
    slug: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },
    description: {
      type: String,
      required: [true, 'Mô tả dịch vụ là bắt buộc'],
      trim: true,
    },
    icon: {
      type: String,
      default: 'home_repair_service',
    },
    color: {
      type: String,
      default: '#2563EB',
    },
    basePrice: {
      type: Number,
      default: 150000,
    },
    commonIssues: {
      type: [String],
      default: [],
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    sortOrder: {
      type: Number,
      default: 0,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('ServiceCategory', serviceCategorySchema);
