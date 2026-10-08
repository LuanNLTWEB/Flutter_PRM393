const mongoose = require('mongoose');
const dns = require('dns');

// Xử lý lỗi querySrv ECONNREFUSED trên Windows bằng cách chỉ định DNS Google/Cloudflare
dns.setServers(['8.8.8.8', '1.1.1.1']);

const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGO_URI);
    console.log(`MongoDB Connected: ${conn.connection.host}`);
  } catch (error) {
    console.error(`Database connection error: ${error.message}`);
    process.exit(1);
  }
};

module.exports = connectDB;

