import request from 'supertest';
import { getApp, getPrisma, cleanDatabase, disconnectDatabase } from '../setup';

const app = getApp();

let vendorToken: string;
let vendorId: string;

beforeEach(async () => {
  await cleanDatabase();

  const reg = await request(app).post('/api/auth/register').send({
    email: 'vendor@test.com',
    password: 'password123',
    role: 'VENDOR',
    restaurantName: 'Revenue Test Restaurant',
  });

  vendorToken = reg.body.data.token;

  const me = await request(app)
    .get('/api/auth/me')
    .set('Authorization', `Bearer ${vendorToken}`);

  vendorId = me.body.data.vendor.id;
});

afterAll(async () => {
  await disconnectDatabase();
});

describe('Revenue API', () => {
  describe('GET /api/revenue/today', () => {
    it('should return empty summary when no orders', async () => {
      const res = await request(app)
        .get('/api/revenue/today')
        .set('Authorization', `Bearer ${vendorToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.totalOrderCount).toBe(0);
      expect(res.body.data.netRevenueInPaise).toBe(0);
      expect(res.body.data.netRevenueFormatted).toBeDefined();
    });

    it('should return summary after revenue is recorded', async () => {
      const prisma = getPrisma();

      // Simulate a delivered order via direct DB (normally triggered by order flow)
      const student = await prisma.user.create({
        data: { email: 's@test.com', passwordHash: 'x', role: 'STUDENT' },
      });
      const studentRecord = await prisma.student.create({
        data: { userId: student.id, name: 'Test Student' },
      });

      const menuItem = await prisma.menuItem.create({
        data: { vendorId, name: 'Test Item', priceInPaise: 10000 },
      });

      const order = await prisma.order.create({
        data: {
          studentId: studentRecord.id,
          vendorId,
          status: 'DELIVERED',
          totalAmountInPaise: 10000,
          items: { create: [{ menuItemId: menuItem.id, quantity: 1, priceAtOrderInPaise: 10000 }] },
        },
      });

      await prisma.revenueEntry.create({
        data: {
          vendorId,
          orderId: order.id,
          grossAmountInPaise: 10000,
          commissionInPaise: 0,
          netAmountInPaise: 10000,
        },
      });

      const today = new Date();
      today.setHours(0, 0, 0, 0);
      await prisma.revenueSummary.create({
        data: {
          vendorId,
          date: today,
          totalOrderCount: 1,
          grossRevenueInPaise: 10000,
          totalCommissionInPaise: 0,
          netRevenueInPaise: 10000,
        },
      });

      const res = await request(app)
        .get('/api/revenue/today')
        .set('Authorization', `Bearer ${vendorToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.totalOrderCount).toBe(1);
      expect(res.body.data.grossRevenueInPaise).toBe(10000);
      expect(res.body.data.netRevenueInPaise).toBe(10000);
    });
  });

  describe('GET /api/revenue/overall', () => {
    it('should return lifetime revenue', async () => {
      const res = await request(app)
        .get('/api/revenue/overall')
        .set('Authorization', `Bearer ${vendorToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.totalOrderCount).toBe(0);
    });
  });

  describe('GET /api/revenue/entries', () => {
    it('should return paginated entries', async () => {
      const res = await request(app)
        .get('/api/revenue/entries?page=1&limit=10')
        .set('Authorization', `Bearer ${vendorToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.data).toEqual([]);
      expect(res.body.data.total).toBe(0);
      expect(res.body.data.page).toBe(1);
    });
  });

  it('should reject non-vendor access', async () => {
    const student = await request(app).post('/api/auth/register').send({
      email: 'student-rev@test.com',
      password: 'password123',
      role: 'STUDENT',
      name: 'Nope',
    });

    const res = await request(app)
      .get('/api/revenue/today')
      .set('Authorization', `Bearer ${student.body.data.token}`);

    expect(res.status).toBe(403);
  });
});
