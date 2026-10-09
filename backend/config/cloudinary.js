const cloudinary = require('cloudinary').v2;

// Cấu hình Cloudinary từ biến môi trường
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
  secure: true,
});

/**
 * Upload buffer trực tiếp lên Cloudinary bằng stream
 * @param {Buffer} buffer - Buffer của file ảnh từ multer memoryStorage
 * @param {Object} options - Các tùy chọn bổ sung (folder, public_id, transformation...)
 * @returns {Promise<{ url: string, publicId: string }>}
 */
const uploadStream = (buffer, options = {}) => {
  return new Promise((resolve, reject) => {
    const uploadOptions = {
      resource_type: 'image',
      folder: options.folder || 'homefix',
      ...options,
    };

    const stream = cloudinary.uploader.upload_stream(
      uploadOptions,
      (error, result) => {
        if (error) {
          return reject(error);
        }
        resolve({
          url: result.secure_url,
          publicId: result.public_id,
        });
      }
    );

    stream.end(buffer);
  });
};

/**
 * Xóa ảnh trên Cloudinary theo publicId
 * @param {string} publicId - Public ID của ảnh trên Cloudinary
 * @returns {Promise<any>}
 */
const deleteImage = async (publicId) => {
  if (!publicId) return null;
  return await cloudinary.uploader.destroy(publicId);
};

module.exports = {
  cloudinary,
  uploadStream,
  deleteImage,
};
