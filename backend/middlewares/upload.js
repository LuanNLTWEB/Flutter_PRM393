const multer = require('multer');

// Lưu trữ file trong bộ nhớ RAM tạm thời để stream trực tiếp lên Cloudinary
const storage = multer.memoryStorage();

// Bộ lọc định dạng file: Chấp nhận ảnh hợp lệ theo MIME hoặc đuôi mở rộng file
const fileFilter = (req, file, cb) => {
  const allowedMimeTypes = [
    'image/jpeg',
    'image/jpg',
    'image/pjpeg',
    'image/png',
    'image/x-png',
    'image/webp',
    'image/heic',
    'image/heif',
    'application/octet-stream',
  ];

  const allowedExtensions = /\.(jpe?g|png|webp|heic|heif)$/i;
  const isExtensionValid = allowedExtensions.test(file.originalname);
  const isMimeValid =
    allowedMimeTypes.includes((file.mimetype || '').toLowerCase()) ||
    (file.mimetype || '').toLowerCase().startsWith('image/');

  if (isMimeValid || isExtensionValid) {
    cb(null, true);
  } else {
    cb(
      new Error(
        'Định dạng file không hợp lệ! Chỉ chấp nhận ảnh định dạng JPG, JPEG, PNG, WEBP.'
      ),
      false
    );
  }
};


// Giới hạn kích thước file tối đa 5MB
const limits = {
  fileSize: 5 * 1024 * 1024, // 5MB
};

const upload = multer({
  storage,
  fileFilter,
  limits,
});

module.exports = upload;
