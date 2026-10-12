const test = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');

const RepairRequest = require('../models/RepairRequest');
const Quotation = require('../models/Quotation');
const cloudinaryConfig = require('../config/cloudinary');

const originalRequestFindById = RepairRequest.findById;
const originalQuotationFindOne = Quotation.findOne;
const originalUploadStream = cloudinaryConfig.uploadStream;
const originalDeleteImage = cloudinaryConfig.deleteImage;

// Controller code uses Mongoose query chains. This small thenable lets the
// tests exercise controller branches without opening a real database.
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
} = {}) => ({
  _id: 'request1',
  customerId,
  title: 'Sửa máy lạnh',
  status,
  completionImages: [...completionImages],
  assignedTechnicianId: technicianId,
  paymentMethod: null,
  paymentMethodSelectedAt: null,
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

// Patch the Cloudinary helper before loading the controller because it
// destructures uploadStream at module initialization time.
cloudinaryConfig.uploadStream = async (buffer) => ({
  url: `https://cloudinary.test/${buffer.toString()}`,
  publicId: `completion-${buffer.toString()}`,
});
cloudinaryConfig.deleteImage = async () => undefined;

const paymentController = require('../controllers/paymentController');
const repairRequestController = require('../controllers/repairRequestController');

test.after(() => {
  RepairRequest.findById = originalRequestFindById;
  Quotation.findOne = originalQuotationFindOne;
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

test('UC-PAY-02: từ chối payment method không hợp lệ', async () => {
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
      body: { paymentMethod: 'BANK_TRANSFER' },
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
      body: { paymentMethod: 'BANK_TRANSFER' },
    },
    res
  );

  assert.equal(res.statusCode, 409);
  assert.equal(request.paymentMethod, null);
});

test('UC-PAY-02: request id sai trả về 400', async () => {
  RepairRequest.findById = () => {
    throw new mongoose.Error.CastError('ObjectId', 'bad-id', '_id');
  };

  const res = response();
  await paymentController.getInvoice(
    { params: { id: 'bad-id' }, user: { _id: 'customer1' } },
    res
  );

  assert.equal(res.statusCode, 400);
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

test('UC-CFM-01: đơn cũ chưa có assignedTechnicianId vẫn xác thực qua quotation ACCEPTED', async () => {
  const request = makeRequest({ technicianId: null });
  RepairRequest.findById = () => queryResult(request);
  Quotation.findOne = () => queryResult({ _id: 'quotation1', status: 'ACCEPTED' });

  const res = response();
  await repairRequestController.uploadCompletionImages(
    {
      params: { id: 'request1' },
      user: { _id: 'tech1' },
      files: [{ buffer: Buffer.from('legacy') }],
    },
    res
  );

  assert.equal(res.statusCode, 200);
  assert.equal(request.assignedTechnicianId, 'tech1');
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

test('UC-CFM-01: từ chối upload khi đơn đã hủy hoặc không có file', async () => {
  const cancelled = makeRequest({ status: 'CANCELLED' });
  RepairRequest.findById = () => queryResult(cancelled);

  const cancelledRes = response();
  await repairRequestController.uploadCompletionImages(
    { params: { id: 'request1' }, user: { _id: 'tech1' }, files: [{ buffer: Buffer.from('one') }] },
    cancelledRes
  );
  assert.equal(cancelledRes.statusCode, 400);

  const noFileRes = response();
  await repairRequestController.uploadCompletionImages(
    { params: { id: 'request1' }, user: { _id: 'tech1' }, files: [] },
    noFileRes
  );
  assert.equal(noFileRes.statusCode, 400);
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

test('UC-CFM-01: một request không nhận quá 5 file trong một lần upload', async () => {
  const request = makeRequest();
  RepairRequest.findById = () => queryResult(request);

  const res = response();
  await repairRequestController.uploadCompletionImages(
    {
      params: { id: 'request1' },
      user: { _id: 'tech1' },
      files: Array.from({ length: 6 }, (_, index) => ({
        buffer: Buffer.from(String(index)),
      })),
    },
    res
  );

  assert.equal(res.statusCode, 400);
  assert.deepEqual(request.completionImages, []);
});
