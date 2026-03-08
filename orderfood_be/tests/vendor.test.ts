import request from 'supertest';
import { getApp, cleanDatabase, disconnectDatabase } from './setup';

const app = getApp();

let vendorToken: string;

beforeEach(async () => {
  await cleanDatabase();

  const reg = await request(app).post('/api/auth/register').send({
    email: 'vendor@test.com',
    password: 'password123',
    role: 'VENDOR',
    restaurantName: 'Vendor Test Kitchen',
  });

  vendorToken = reg.body.data.token;
});

afterAll(async () => {
  await disconnectDatabase();
});

describe('Vendor Menu API', () => {
  describe('POST /api/vendor/menu/items', () => {
    it('should create a menu item with price in rupees (stored as paise)', async () => {
      const res = await request(app)
        .post('/api/vendor/menu/items')
        .set('Authorization', `Bearer ${vendorToken}`)
        .send({
          name: 'Paneer Tikka',
          description: 'Grilled paneer cubes',
          price: 180,
          category: 'Starters',
        });

      expect(res.status).toBe(201);
      expect(res.body.data.name).toBe('Paneer Tikka');
      expect(res.body.data.priceInPaise).toBe(18000);
    });
  });

  describe('PATCH /api/vendor/menu/items/:id/availability', () => {
    it('should toggle availability', async () => {
      const create = await request(app)
        .post('/api/vendor/menu/items')
        .set('Authorization', `Bearer ${vendorToken}`)
        .send({ name: 'Toggle Test', price: 100, category: 'Test' });

      const itemId = create.body.data.id;
      expect(create.body.data.isAvailable).toBe(true);

      const toggle = await request(app)
        .patch(`/api/vendor/menu/items/${itemId}/availability`)
        .set('Authorization', `Bearer ${vendorToken}`);

      expect(toggle.body.data.isAvailable).toBe(false);
      expect(toggle.body.message).toBe('Marked as sold out');

      const toggleBack = await request(app)
        .patch(`/api/vendor/menu/items/${itemId}/availability`)
        .set('Authorization', `Bearer ${vendorToken}`);

      expect(toggleBack.body.data.isAvailable).toBe(true);
    });
  });

  describe('DELETE /api/vendor/menu/items/:id', () => {
    it('should delete a menu item', async () => {
      const create = await request(app)
        .post('/api/vendor/menu/items')
        .set('Authorization', `Bearer ${vendorToken}`)
        .send({ name: 'Delete Me', price: 50 });

      const res = await request(app)
        .delete(`/api/vendor/menu/items/${create.body.data.id}`)
        .set('Authorization', `Bearer ${vendorToken}`);

      expect(res.status).toBe(200);
      expect(res.body.message).toBe('Menu item deleted');
    });
  });

  describe('GET /api/vendor/menu (SDUI)', () => {
    it('should return SDUI screen with menu items', async () => {
      await request(app)
        .post('/api/vendor/menu/items')
        .set('Authorization', `Bearer ${vendorToken}`)
        .send({ name: 'Dosa', price: 80, category: 'South Indian' });

      const res = await request(app)
        .get('/api/vendor/menu')
        .set('Authorization', `Bearer ${vendorToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.screen).toBe('vendor_menu');
      expect(res.body.data.components).toBeDefined();
      expect(res.body.data.components.length).toBeGreaterThan(0);
    });
  });

  describe('GET /api/vendor/dashboard (SDUI)', () => {
    it('should return SDUI dashboard with revenue data', async () => {
      const res = await request(app)
        .get('/api/vendor/dashboard')
        .set('Authorization', `Bearer ${vendorToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.screen).toBe('vendor_dashboard');
      const statsRow = res.body.data.components.find((c: any) => c.type === 'statsRow');
      expect(statsRow).toBeDefined();
      expect(statsRow.children.length).toBe(3);
    });
  });
});
