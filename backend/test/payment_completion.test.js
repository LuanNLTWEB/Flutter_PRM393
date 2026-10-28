const test = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');

const RepairRequest = require('../models/RepairRequest');
const Quotation = require('../models/Quotation');
const Notification = require('../models/Notification');
const cloudinaryConfig = require('../config/cloudinary');

const originalRequestFindById = RepairRequest.findById;
const originalQuotationFindOne = Quotation.findOne;
const originalNotificationCreate = Notification.create;
const originalUploadStream = cloudinaryConfig.uploadStream;
const originalDeleteImage = cloudinaryConfig.deleteImage;

const queryResult = (value) => ({
  populate() {
    return this;
  },
  then(resolve, reject) {
    return Promise.resolve(value).then(resolve, reject);
  },
});

const response = () => {
  const result = {
    statusCode: 200,
    body: null,
    status(code) {
      result.statusCode = code;
      return result;
    },
    json(body) {
      result.body = body;
      return result;
    },
  };
  return result;
};

const makeRequest = ({
  customerId = 'customer1',
  technicianId = 'tech1',
  status = 'ACCEPTED',
  completionImages = [],
  partsInvoiceImages = [],
  paymentStatus = 'UNPAID',
} = {}) => ({
  _id: 'request1',
  customerId,
  title: 'Sửa máy lạnh',
  status,
  completionImages: [...completionImages],
  partsInvoiceImages: [...partsInvoiceImages],
  assignedTechnicianId: technicianId,
  paymentMethod: null,
  paymentMethodSelectedAt: null,
  paymentStatus,
  paidAt: null,
  serviceCategoryId: { name: 'Điện lạnh' },
  save: async () => undefined,
});

const makeQuotation = () => ({
  _id: 'quotation1',
  technicianId: { _id: 'tech1', fullName: 'Thợ A', avatar: '' },
  labourCost: 300000,
  partsCost: 150000,
  total: 450000,
});

cloudinaryConfig.uploadStream = async (buffer) => ({
  url: `https://cloudinary.test/${buffer.toString()}`,
  publicId: `upload-${buffer.toString()}`,
});
cloudinaryConfig.deleteImage = async () => undefined;
Notification.create = async () => ({ _id: 'notif1' });

const paymentController = require('../controllers/paymentController');
const repairRequestController = require('../controllers/repairRequestController');

test.after(() => {
  RepairRequest.findById = originalRequestFindById;
  Quotation.findOne = originalQuotationFindOne;
  Notification.create = originalNotificationCreate;
  cloudinaryConfig.uploadStream = originalUploadStream;
  cloudinaryConfig.deleteImage = originalDeleteImage;
});

test('UC-PAY-01: customer xem được hóa đơn từ quotation ACCEPTED', async () => {
  const request = makeRequest({ completionImages: ['after-repair.jpg'] });
  RepairRequest.findById = () => queryResult(request);
  Quotation.findOne = () => queryResult(makeQuotation());

  const res = response();
  await paymentController.getInvoice(
    { params: { id: 'request1' }, user: { _id: 'customer1' } },
    res
  );

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.data.invoice.labourCost, 300000);
  assert.equal(res.body.data.invoice.partsCost, 150000);
  assert.equal(res.body.data.invoice.total, 450000);
});

test('UC-PAY-01: không cho customer khác xem hóa đơn', async () => {
  RepairRequest.findById = () => queryResult(makeRequest({ customerId: 'other' }));

  const res = response();
  await paymentController.getInvoice(
    { params: { id: 'request1' }, user: { _id: 'customer1' } },
    res
  );

  assert.equal(res.statusCode, 403);
  assert.equal(res.body.success, false);
});

test('UC-PAY-01: thợ được gán cũng xem được bảng kê chi phí', async () => {
  const request = makeRequest({ completionImages: ['after-repair.jpg'] });
  RepairRequest.findById = () => queryResult(request);
  Quotation.findOne = () => queryResult(makeQuotation());

  const res = response();
  await paymentController.getInvoice(
    { params: { id: 'request1' }, user: { _id: 'tech1' } },
    res
  );

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.data.invoice.total, 450000);
});

test('UC-PAY-01: chưa có quotation ACCEPTED thì không tạo hóa đơn', async () => {
  RepairRequest.findById = () =>
    queryResult(makeRequest({ completionImages: ['after-repair.jpg'] }));
  Quotation.findOne = () => queryResult(null);

  const res = response();
  await paymentController.getInvoice(
    { params: { id: 'request1' }, user: { _id: 'customer1' } },
    res
  );

  assert.equal(res.statusCode, 404);
});

test('UC-PAY-01: chưa có ảnh nghiệm thu thì chưa cho xem hóa đơn', async () => {
  RepairRequest.findById = () => queryResult(makeRequest());
  Quotation.findOne = () => queryResult(makeQuotation());

  const res = response();
  await paymentController.getInvoice(
    { params: { id: 'request1' }, user: { _id: 'customer1' } },
    res
  );

  assert.equal(res.statusCode, 409);
});

test('UC-PAY-02: từ chối payment method không phải CASH (thuần tiền mặt)', async () => {
  const res = response();
  await paymentController.selectPaymentMethod(
    {
      params: { id: 'request1' },
      user: { _id: 'customer1' },
      body: { paymentMethod: 'CREDIT_CARD' },
    },
    res
  );

  assert.equal(res.statusCode, 400);
  assert.equal(res.body.success, false);
});

test('UC-PAY-02: lưu được CASH và trả lại hóa đơn đã cập nhật', async () => {
  const request = makeRequest({ completionImages: ['after-repair.jpg'] });
  RepairRequest.findById = () => queryResult(request);
  Quotation.findOne = () => queryResult(makeQuotation());

  const res = response();
  await paymentController.selectPaymentMethod(
    {
      params: { id: 'request1' },
      user: { _id: 'customer1' },
      body: { paymentMethod: 'CASH' },
    },
    res
  );

  assert.equal(res.statusCode, 200);
  assert.equal(request.paymentMethod, 'CASH');
  assert.ok(request.paymentMethodSelectedAt instanceof Date);
  assert.equal(res.body.data.invoice.paymentMethod, 'CASH');
});

test('UC-PAY-02: không cho chọn phương thức cho đơn đã hủy', async () => {
  const request = makeRequest({
    status: 'CANCELLED',
    completionImages: ['after-repair.jpg'],
  });
  RepairRequest.findById = () => queryResult(request);
  Quotation.findOne = () => queryResult(makeQuotation());

  const res = response();
  await paymentController.selectPaymentMethod(
    {
      params: { id: 'request1' },
      user: { _id: 'customer1' },
      body: { paymentMethod: 'CASH' },
    },
    res
  );

  assert.equal(res.statusCode, 400);
  assert.equal(request.paymentMethod, null);
});

test('UC-PAY-02: chưa có ảnh nghiệm thu thì chưa cho chọn phương thức', async () => {
  const request = makeRequest();
  RepairRequest.findById = () => queryResult(request);
  Quotation.findOne = () => queryResult(makeQuotation());

  const res = response();
  await paymentController.selectPaymentMethod(
    {
      params: { id: 'request1' },
      user: { _id: 'customer1' },
      body: { paymentMethod: 'CASH' },
    },
    res
  );

  assert.equal(res.statusCode, 409);
  assert.equal(request.paymentMethod, null);
});

test('UC-PAY-03: thợ upload ảnh hóa đơn linh kiện thành công', async () => {
  const request = makeRequest({ completionImages: ['after.jpg'] });
  RepairRequest.findById = () => queryResult(request);
  Quotation.findOne = () => queryResult(makeQuotation());

  const res = response();
  await paymentController.uploadPartsInvoiceImages(
    {
      params: { id: 'request1' },
      user: { _id: 'tech1' },
      files: [{ buffer: Buffer.from('bill-1') }],
    },
    res
  );

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.success, true);
  assert.deepEqual(request.partsInvoiceImages, ['https://cloudinary.test/bill-1']);
});

test('UC-PAY-03: không cho thợ khác tải hóa đơn linh kiện', async () => {
  const request = makeRequest({ technicianId: 'tech2', completionImages: ['after.jpg'] });
  RepairRequest.findById = () => queryResult(request);
  Quotation.findOne = () => queryResult(makeQuotation());

  const res = response();
  await paymentController.uploadPartsInvoiceImages(
    {
      params: { id: 'request1' },
      user: { _id: 'tech1' },
      files: [{ buffer: Buffer.from('bill-1') }],
    },
    res
  );

  assert.equal(res.statusCode, 403);
});

test('UC-PAY-04: thợ xác nhận đã nhận đủ tiền mặt thành công', async () => {
  const request = makeRequest({ completionImages: ['after.jpg'] });
  RepairRequest.findById = () => queryResult(request);
  Quotation.findOne = () => queryResult(makeQuotation());

  const res = response();
  await paymentController.confirmPaymentReceived(
    {
      params: { id: 'request1' },
      user: { _id: 'tech1', fullName: 'Thợ A' },
    },
    res
  );

  assert.equal(res.statusCode, 200);
  assert.equal(request.paymentStatus, 'PAID');
  assert.ok(request.paidAt instanceof Date);
  assert.equal(request.paymentMethod, 'CASH');
  assert.equal(res.body.data.invoice.paymentStatus, 'PAID');
});

test('UC-PAY-04: không cho thợ khác xác nhận nhận tiền', async () => {
  const request = makeRequest({ technicianId: 'tech2', completionImages: ['after.jpg'] });
  RepairRequest.findById = () => queryResult(request);
  Quotation.findOne = () => queryResult(makeQuotation());

  const res = response();
  await paymentController.confirmPaymentReceived(
    {
      params: { id: 'request1' },
      user: { _id: 'tech1' },
    },
    res
  );

  assert.equal(res.statusCode, 403);
  assert.equal(request.paymentStatus, 'UNPAID');
});

test('UC-CFM-01: upload ảnh thành công và chuyển ACCEPTED sang IN_PROGRESS', async () => {
  const request = makeRequest();
  RepairRequest.findById = () => queryResult(request);
  Quotation.findOne = () => queryResult({ _id: 'quotation1' });

  const res = response();
  await repairRequestController.uploadCompletionImages(
    {
      params: { id: 'request1' },
      user: { _id: 'tech1' },
      files: [{ buffer: Buffer.from('one') }, { buffer: Buffer.from('two') }],
    },
    res
  );

  assert.equal(res.statusCode, 200);
  assert.equal(request.status, 'IN_PROGRESS');
  assert.deepEqual(request.completionImages, [
    'https://cloudinary.test/one',
    'https://cloudinary.test/two',
  ]);
});

test('UC-CFM-01: không upload nếu không phải thợ được gán', async () => {
  const request = makeRequest({ technicianId: 'tech2' });
  RepairRequest.findById = () => queryResult(request);
  Quotation.findOne = () => queryResult(null);

  const res = response();
  await repairRequestController.uploadCompletionImages(
    {
      params: { id: 'request1' },
      user: { _id: 'tech1' },
      files: [{ buffer: Buffer.from('one') }],
    },
    res
  );

  assert.equal(res.statusCode, 403);
  assert.deepEqual(request.completionImages, []);
});

test('UC-CFM-01: không vượt quá 5 ảnh sau sửa', async () => {
  const request = makeRequest({ completionImages: ['1', '2', '3', '4', '5'] });
  RepairRequest.findById = () => queryResult(request);

  const res = response();
  await repairRequestController.uploadCompletionImages(
    {
      params: { id: 'request1' },
      user: { _id: 'tech1' },
      files: [{ buffer: Buffer.from('six') }],
    },
    res
  );

  assert.equal(res.statusCode, 400);
  assert.equal(request.completionImages.length, 5);
});
