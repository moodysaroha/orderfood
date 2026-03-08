import request from 'supertest';
import { getApp, cleanDatabase, disconnectDatabase } from './setup';

const app = getApp();

let vendorToken: string;
let studentToken: string;
let vendorId: string;

beforeEach(async () => {
  await cleanDatabase();

  const vendorReg = await request(app).post('/api/auth/register').send({
    email: 'vendor@test.com',
    password: 'password123',
    role: 'VENDOR',
    restaurantName: 'Student Test Kitchen',
  });
  vendorToken = vendorReg.body.data.token;

  const vendorMe = await request(app)
    .get('/api/auth/me')
    .set('Authorization', `Bearer ${vendorToken}`);
  vendorId = vendorMe.body.data.vendor.id;

  const studentReg = await request(app).post('/api/auth/register').send({
    email: 'student@test.com',
    password: 'password123',
    role: 'STUDENT',
    name: 'Test Student',
  });
  studentToken = studentReg.body.data.token;
});

afterAll(async () => {
  await disconnectDatabase();
});

describe('Student API', () => {
  let menuItemId: string;

  beforeEach(async () => {
    const item = await request(app)
      .post('/api/vendor/menu/items')
      .set('Authorization', `Bearer ${vendorToken}`)
      .send({ name: 'Biryani', price: 200, category: 'Main' });

    menuItemId = item.body.data.id;
  });

  describe('GET /api/student/menu/:vendorId (SDUI)', () => {
    it('should return SDUI menu for a vendor', async () => {
      const res = await request(app)
        .get(`/api/student/menu/${vendorId}`)
        .set('Authorization', `Bearer ${studentToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.screen).toBe('student_menu');
      expect(res.body.data.pollingIntervalMs).toBeDefined();
    });
  });

  describe('POST /api/student/orders', () => {
    it('should place an order', async () => {
      const res = await request(app)
        .post('/api/student/orders')
        .set('Authorization', `Bearer ${studentToken}`)
        .send({
          vendorId,
          items: [{ menuItemId, quantity: 2 }],
        });

      expect(res.status).toBe(201);
      expect(res.body.data.totalAmountInPaise).toBe(40000);
      expect(res.body.data.items.length).toBe(1);
    });

    it('should reject order for unavailable item', async () => {
      await request(app)
        .patch(`/api/vendor/menu/items/${menuItemId}/availability`)
        .set('Authorization', `Bearer ${vendorToken}`);

      const res = await request(app)
        .post('/api/student/orders')
        .set('Authorization', `Bearer ${studentToken}`)
        .send({
          vendorId,
          items: [{ menuItemId, quantity: 1 }],
        });

      expect(res.status).toBe(400);
    });
  });

  describe('GET /api/student/orders', () => {
    it('should list student orders', async () => {
      await request(app)
        .post('/api/student/orders')
        .set('Authorization', `Bearer ${studentToken}`)
        .send({ vendorId, items: [{ menuItemId, quantity: 1 }] });

      const res = await request(app)
        .get('/api/student/orders')
        .set('Authorization', `Bearer ${studentToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.length).toBe(1);
    });
  });

  describe('Order delivery triggers revenue', () => {
    it('should record revenue when order is marked DELIVERED', async () => {
      const order = await request(app)
        .post('/api/student/orders')
        .set('Authorization', `Bearer ${studentToken}`)
        .send({ vendorId, items: [{ menuItemId, quantity: 1 }] });

      const orderId = order.body.data.id;

      await request(app)
        .patch(`/api/vendor/orders/${orderId}/status`)
        .set('Authorization', `Bearer ${vendorToken}`)
        .send({ status: 'DELIVERED' });

      const revenue = await request(app)
        .get('/api/revenue/today')
        .set('Authorization', `Bearer ${vendorToken}`);

      expect(revenue.body.data.totalOrderCount).toBe(1);
      expect(revenue.body.data.grossRevenueInPaise).toBe(20000);
    });
  });
});
