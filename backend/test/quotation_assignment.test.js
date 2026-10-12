const test = require('node:test');
const assert = require('node:assert/strict');

const RepairRequest = require('../models/RepairRequest');
const Quotation = require('../models/Quotation');
const quotationController = require('../controllers/quotationController');

const originalRequestFindById = RepairRequest.findById;
const originalQuotationFindById = Quotation.findById;
const originalQuotationUpdateMany = Quotation.updateMany;

const queryResult = (value) => ({
  populate() {
    return this;
  },
  lean() {
    return Promise.resolve(value);
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

test.after(() => {
  RepairRequest.findById = originalRequestFindById;
  Quotation.findById = originalQuotationFindById;
  Quotation.updateMany = originalQuotationUpdateMany;
});

test('UC-QUO-08: chốt báo giá phải gán technician cho repair request', async () => {
  const quotation = {
    _id: 'quotation1',
    requestId: 'request1',
    technicianId: 'tech1',
    status: 'SENT',
    resolvedAt: null,
    save: async () => undefined,
  };
  const request = {
    _id: 'request1',
    customerId: 'customer1',
    status: 'QUOTED',
    assignedTechnicianId: null,
    save: async () => undefined,
  };

  RepairRequest.findById = () => Promise.resolve(request);
  Quotation.findById = () => queryResult(quotation);
  Quotation.updateMany = async () => ({ modifiedCount: 0 });

  const res = response();
  await quotationController.acceptQuotation(
    {
      params: { id: 'quotation1' },
      user: { _id: 'customer1' },
    },
    res
  );

  assert.equal(res.statusCode, 200);
  assert.equal(request.status, 'ACCEPTED');
  assert.equal(request.assignedTechnicianId, 'tech1');
  assert.equal(quotation.status, 'ACCEPTED');
});
