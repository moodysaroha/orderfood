import request from 'supertest';
import { getApp, cleanDatabase, disconnectDatabase } from './setup';

const app = getApp();

beforeEach(async () => {
  await cleanDatabase();
});

afterAll(async () => {
  await disconnectDatabase();
});

describe('SDUI Admin API', () => {
  describe('GET /api/sdui/components', () => {
    it('should list all registered component types', async () => {
      const res = await request(app).get('/api/sdui/components');

      expect(res.status).toBe(200);
      expect(res.body.data.length).toBeGreaterThan(0);

      const types = res.body.data.map((c: any) => c.type);
      expect(types).toContain('statCard');
      expect(types).toContain('menuItemTile');
      expect(types).toContain('orderTile');
      expect(types).toContain('button');
    });
  });

  describe('GET /api/sdui/layouts', () => {
    it('should return empty layouts initially', async () => {
      const res = await request(app).get('/api/sdui/layouts');

      expect(res.status).toBe(200);
      expect(res.body.data.layouts).toEqual([]);
      expect(res.body.data.registeredScreens).toBeDefined();
    });
  });

  describe('PUT /api/sdui/layouts/:screenName', () => {
    it('should create/update a layout', async () => {
      const layoutJson = {
        components: [
          { type: 'text', props: { value: 'Custom layout' } },
        ],
      };

      const res = await request(app)
        .put('/api/sdui/layouts/custom_screen')
        .send({ layoutJson, role: 'VENDOR' });

      expect(res.status).toBe(200);
      expect(res.body.data.screenName).toBe('custom_screen');
      expect(res.body.data.layoutJson).toEqual(layoutJson);
    });
  });
});

describe('Health Check', () => {
  it('should return healthy status', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
  });
});
