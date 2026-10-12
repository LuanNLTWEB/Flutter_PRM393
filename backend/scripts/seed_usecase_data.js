require('dotenv').config();

const dns = require('dns');
const mongoose = require('mongoose');
const User = require('../models/User');
const ServiceCategory = require('../models/ServiceCategory');
const RepairRequest = require('../models/RepairRequest');
const Quotation = require('../models/Quotation');

const TEST_PASSWORD = 'Homefix@123';
const CUSTOMER_EMAIL = 'qa.customer@homefix.dev';
const TECHNICIAN_EMAIL = 'qa.technician@homefix.dev';
const CATEGORY_SLUG = 'qa-dien-lanh';
const COMPLETED_IMAGE_URL =
  'https://res.cloudinary.com/demo/image/upload/v1312461204/sample.jpg';

// Windows đôi khi không resolve được bản ghi SRV của MongoDB Atlas bằng DNS mặc định.
dns.setServers(['8.8.8.8', '1.1.1.1']);

const upsertUser = async ({
  email,
  fullName,
  phoneNumber,
  role,
  technicianProfile,
}) => {
  let user = await User.findOne({ email });

  if (!user) {
    user = new User({
      email,
      fullName,
      phoneNumber,
      password: TEST_PASSWORD,
      dateOfBirth: new Date('1995-01-01'),
      gender: 'other',
      role,
    });
  } else {
    user.fullName = fullName;
    user.phoneNumber = phoneNumber;
    user.password = TEST_PASSWORD;
    user.dateOfBirth = new Date('1995-01-01');
    user.gender = 'other';
    user.role = role;
    user.isActive = true;
    user.isDeleted = false;
    user.deletedAt = null;
  }

  if (technicianProfile) {
    user.technicianProfile = {
      ...user.technicianProfile?.toObject?.(),
      ...technicianProfile,
    };
  }

  await user.save();
  return user;
};

const upsertCategory = async () => {
  let category = await ServiceCategory.findOne({ slug: CATEGORY_SLUG });

  if (!category) {
    category = new ServiceCategory({ slug: CATEGORY_SLUG });
  }

  category.name = 'Điện lạnh (QA)';
  category.description = 'Dữ liệu mẫu để kiểm thử nghiệm thu và hóa đơn';
  category.icon = 'ac_unit';
  category.color = '#2563EB';
  category.basePrice = 150000;
  category.commonIssues = ['Máy lạnh không hoạt động', 'Tủ lạnh không làm lạnh'];
  category.isActive = true;
  category.sortOrder = 999;

  await category.save();
  return category;
};

const upsertRequest = async ({
  customer,
  technician,
  category,
  title,
  description,
  status,
  completionImages,
}) => {
  let request = await RepairRequest.findOne({
    customerId: customer._id,
    title,
  });

  if (!request) {
    request = new RepairRequest({
      customerId: customer._id,
      serviceCategoryId: category._id,
      title,
      description,
    });
  }

  request.serviceCategoryId = category._id;
  request.customerId = customer._id;
  request.title = title;
  request.description = description;
  request.images = [];
  request.completionImages = completionImages;
  request.urgency = 'high';
  request.location = {
    address: '123 Đường Nguyễn Huệ, Quận 1, TP. Hồ Chí Minh',
    latitude: 10.7769,
    longitude: 106.7009,
  };
  request.status = status;
  request.assignedTechnicianId = technician._id;
  request.paymentMethod = null;
  request.paymentMethodSelectedAt = null;
  request.contactPhone = customer.phoneNumber;
  request.customerNote = 'Dữ liệu QA cho UC-CFM-01 và UC-PAY-01';

  await request.save();
  return request;
};

const upsertAcceptedQuotation = async ({ request, technician, labourCost, partsCost }) => {
  let quotation = await Quotation.findOne({
    requestId: request._id,
    technicianId: technician._id,
  });

  if (!quotation) {
    quotation = new Quotation({
      requestId: request._id,
      technicianId: technician._id,
    });
  }

  quotation.labourCost = labourCost;
  quotation.partsCost = partsCost;
  quotation.total = labourCost + partsCost;
  quotation.note = 'Báo giá mẫu để kiểm thử hóa đơn';
  quotation.status = 'ACCEPTED';
  quotation.resolvedAt = new Date();

  await quotation.save();
  return quotation;
};

const main = async () => {
  if (!process.env.MONGO_URI) {
    throw new Error('Thiếu MONGO_URI trong backend/.env');
  }

  await mongoose.connect(process.env.MONGO_URI);

  const customer = await upsertUser({
    email: CUSTOMER_EMAIL,
    fullName: 'QA Customer',
    phoneNumber: '0909000001',
    role: 'user',
  });

  const technician = await upsertUser({
    email: TECHNICIAN_EMAIL,
    fullName: 'QA Technician',
    phoneNumber: '0909000002',
    role: 'technician',
    technicianProfile: {
      skills: ['Điện lạnh', 'Bảo trì thiết bị gia dụng'],
      experienceYears: 5,
      bio: 'Tài khoản Technician dùng cho kiểm thử use case.',
      approvalStatus: 'approved',
      approvedAt: new Date(),
      isAvailable: true,
    },
  });

  const category = await upsertCategory();

  const completionRequest = await upsertRequest({
    customer,
    technician,
    category,
    title: '[QA] Máy lạnh cần nghiệm thu ảnh',
    description:
      'Máy lạnh đã được sửa xong và cần thợ chụp ảnh thiết bị hoạt động bình thường.',
    status: 'ACCEPTED',
    completionImages: [],
  });

  const completionQuotation = await upsertAcceptedQuotation({
    request: completionRequest,
    technician,
    labourCost: 300000,
    partsCost: 150000,
  });

  const invoiceRequest = await upsertRequest({
    customer,
    technician,
    category,
    title: '[QA] Tủ lạnh đã sửa - xem hóa đơn',
    description:
      'Tủ lạnh đã hoạt động ổn định sau sửa chữa và sẵn sàng kiểm tra hóa đơn.',
    status: 'IN_PROGRESS',
    completionImages: [COMPLETED_IMAGE_URL],
  });

  const invoiceQuotation = await upsertAcceptedQuotation({
    request: invoiceRequest,
    technician,
    labourCost: 250000,
    partsCost: 800000,
  });

  console.log('\nSeed dữ liệu kiểm thử thành công.');
  console.log(`Customer:    ${CUSTOMER_EMAIL}`);
  console.log(`Technician:  ${TECHNICIAN_EMAIL}`);
  console.log(`Mật khẩu:    ${TEST_PASSWORD}`);
  console.log(`\nUC-CFM-01 - requestId: ${completionRequest._id}`);
  console.log(`              quotationId: ${completionQuotation._id}`);
  console.log(`              trạng thái: ${completionRequest.status}, chưa có ảnh hoàn tất`);
  console.log(`\nUC-PAY-01 - requestId: ${invoiceRequest._id}`);
  console.log(`              quotationId: ${invoiceQuotation._id}`);
  console.log(`              trạng thái: ${invoiceRequest.status}, đã có 1 ảnh hoàn tất`);
  console.log(`              tổng tiền: ${invoiceQuotation.total.toLocaleString('vi-VN')} VND`);
};

main()
  .catch((error) => {
    console.error('Seed dữ liệu thất bại:', error.message);
    process.exitCode = 1;
  })
  .finally(async () => {
    await mongoose.disconnect();
  });
