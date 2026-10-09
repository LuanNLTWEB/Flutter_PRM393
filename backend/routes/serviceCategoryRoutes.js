const express = require('express');
const router = express.Router();
const {
  getCategories,
  getCategoryByIdentifier,
} = require('../controllers/serviceCategoryController');

// Lấy toàn bộ danh mục dịch vụ đang kích hoạt
router.get('/', getCategories);

// Lấy chi tiết một danh mục dịch vụ theo slug hoặc id
router.get('/:identifier', getCategoryByIdentifier);

module.exports = router;
