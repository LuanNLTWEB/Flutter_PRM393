const test = require('node:test');
const assert = require('node:assert/strict');

const Notification = require('../models/Notification');
const Quotation = require('../models/Quotation');
const RepairRequest = require('../models/RepairRequest');

const originalNotificationCreate = Notification.create;
const originalQuotationFindOne = Quotation.findOne;
const originalRepairRequestFindById = RepairRequest.findById;

const queryResult = (value) => ({
  select() {
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
  status = 'IN_PROGRESS',
  completionImages = ['after-repair.jpg'],
} = {}) => ({
  _id: 'request1',
  customerId,
  assignedTechnicianId: technicianId,
  title: 'Sửa máy lạnh',
  status,
  completionImages: [...completionImages],
  completionQrTokenHash: null,
  completionQrGeneratedAt: null,
  completionQrExpiresAt: null,
  completionConfirmedAt: null,
  completionConfirmedBy: null,
  completedAt: null,
  save: async () => undefined,
});

const makeQuotation = () => ({
  _id: 'quotation1',
  requestId: 'request1',
  technicianId: 'tech1',
  status: 'ACCEPTED',
  labourCost: 300000,
  partsCost: 150000,
  total: 450000,
});

Notification.create = async () => ({ _id: 'notification1' });

const {
  generateCompletionQr,
  confirmCompletion,
} = require('../controllers/completionController');

test.after(() => {
  Notification.create = originalNotificationCreate;
  Quotation.findOne = originalQuotationFindOne;
  RepairRequest.findById = originalRepairRequestFindById;
});

test('UC-CFM-02: thợ được gán tạo QR chứa mã đơn và số tiền chốt', async () => {
  const request = makeRequest();
  RepairRequest.findById = () => queryResult(request);
  Quotation.findOne = () => queryResult(makeQuotation());

  const res = response();
  await generateCompletionQr(
    { params: { id: 'request1' }, user: { _id: 'tech1' } },
    res
  );

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.data.confirmationQr.requestId, 'request1');
  assert.equal(res.body.data.confirmationQr.amount, 450000);
  assert.ok(request.completionQrTokenHash);
  assert.ok(request.completionQrExpiresAt instanceof Date);

  const payload = new URL(res.body.data.confirmationQr.payload);
  assert.equal(payload.protocol, 'homefix:');
  assert.equal(payload.searchParams.get('requestId'), 'request1');
  assert.equal(payload.searchParams.get('amount'), '450000');
  assert.ok(payload.searchParams.get('token'));
});

test('UC-CFM-02: không tạo QR khi chưa có ảnh hoàn tất', async () => {
  const request = makeRequest({ completionImages: [] });
  RepairRequest.findById = () => queryResult(request);

  const res = response();
  await generateCompletionQr(
    { params: { id: 'request1' }, user: { _id: 'tech1' } },
    res
  );

  assert.equal(res.statusCode, 409);
  assert.equal(request.completionQrTokenHash, null);
});

test('UC-CFM-02: không cho thợ khác tạo QR', async () => {
  const request = makeRequest({ technicianId: 'tech2' });
  RepairRequest.findById = () => queryResult(request);
  Quotation.findOne = () => queryResult(makeQuotation());

  const res = response();
  await generateCompletionQr(
    { params: { id: 'request1' }, user: { _id: 'tech1' } },
    res
  );

  assert.equal(res.statusCode, 403);
});

test('UC-CFM-03: khách quét QR hợp lệ thì đơn chuyển COMPLETED', async () => {
  const request = makeRequest();
  RepairRequest.findById = () => queryResult(request);
  Quotation.findOne = () => queryResult(makeQuotation());

  const generateRes = response();
  await generateCompletionQr(
    { params: { id: 'request1' }, user: { _id: 'tech1' } },
    generateRes
  );
  const payload = new URL(generateRes.body.data.confirmationQr.payload);

  const confirmRes = response();
  await confirmCompletion(
    {
      params: { id: 'request1' },
      user: { _id: 'customer1' },
      body: {
        token: payload.searchParams.get('token'),
        amount: Number(payload.searchParams.get('amount')),
      },
    },
    confirmRes
  );

  assert.equal(confirmRes.statusCode, 200);
  assert.equal(request.status, 'COMPLETED');
  assert.equal(request.completionConfirmedBy, 'customer1');
  assert.ok(request.completedAt instanceof Date);
  assert.equal(request.completionQrTokenHash, null);
});

test('UC-CFM-03: khách khác không được nghiệm thu đơn', async () => {
  const request = makeRequest({ customerId: 'customer2' });
  RepairRequest.findById = () => queryResult(request);

  const res = response();
  await confirmCompletion(
    {
      params: { id: 'request1' },
      user: { _id: 'customer1' },
      body: { token: 'token', amount: 450000 },
    },
    res
  );

  assert.equal(res.statusCode, 403);
});

test('UC-CFM-03: QR cũ bị vô hiệu sau khi thợ tạo mã mới', async () => {
  const request = makeRequest();
  RepairRequest.findById = () => queryResult(request);
  Quotation.findOne = () => queryResult(makeQuotation());

  const firstRes = response();
  await generateCompletionQr(
    { params: { id: 'request1' }, user: { _id: 'tech1' } },
    firstRes
  );
  const firstPayload = new URL(firstRes.body.data.confirmationQr.payload);

  const secondRes = response();
  await generateCompletionQr(
    { params: { id: 'request1' }, user: { _id: 'tech1' } },
    secondRes
  );

  const confirmRes = response();
  await confirmCompletion(
    {
      params: { id: 'request1' },
      user: { _id: 'customer1' },
      body: {
        token: firstPayload.searchParams.get('token'),
        amount: 450000,
      },
    },
    confirmRes
  );

  assert.equal(confirmRes.statusCode, 400);
  assert.equal(request.status, 'IN_PROGRESS');
});

test('UC-CFM-03: từ chối QR có số tiền bị sửa', async () => {
  const request = makeRequest();
  RepairRequest.findById = () => queryResult(request);
  Quotation.findOne = () => queryResult(makeQuotation());

  const generateRes = response();
  await generateCompletionQr(
    { params: { id: 'request1' }, user: { _id: 'tech1' } },
    generateRes
  );
  const payload = new URL(generateRes.body.data.confirmationQr.payload);

  const confirmRes = response();
  await confirmCompletion(
    {
      params: { id: 'request1' },
      user: { _id: 'customer1' },
      body: {
        token: payload.searchParams.get('token'),
        amount: 1,
      },
    },
    confirmRes
  );

  assert.equal(confirmRes.statusCode, 400);
  assert.equal(request.status, 'IN_PROGRESS');
});
