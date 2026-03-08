import request from 'supertest';
import { getApp, cleanDatabase, disconnectDatabase } from './setup';

const app = getApp();

beforeEach(async () => {
  await cleanDatabase();
});

afterAll(async () => {
  await disconnectDatabase();
});

describe('Auth API', () => {
  describe('POST /api/auth/register', () => {
    it('should register a vendor', async () => {
      const res = await request(app).post('/api/auth/register').send({
        email: 'vendor@test.com',
        password: 'password123',
        role: 'VENDOR',
        restaurantName: 'Test Restaurant',
      });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.token).toBeDefined();
      expect(res.body.data.user.role).toBe('VENDOR');
    });

    it('should register a student', async () => {
      const res = await request(app).post('/api/auth/register').send({
        email: 'student@test.com',
        password: 'password123',
        role: 'STUDENT',
        name: 'Test Student',
      });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.user.role).toBe('STUDENT');
    });

    it('should reject duplicate email', async () => {
      await request(app).post('/api/auth/register').send({
        email: 'dup@test.com',
        password: 'password123',
        role: 'STUDENT',
        name: 'First',
      });

      const res = await request(app).post('/api/auth/register').send({
        email: 'dup@test.com',
        password: 'password123',
        role: 'STUDENT',
        name: 'Second',
      });

      expect(res.status).toBe(409);
    });

    it('should require restaurant name for vendor', async () => {
      const res = await request(app).post('/api/auth/register').send({
        email: 'v@test.com',
        password: 'password123',
        role: 'VENDOR',
      });

      expect(res.status).toBe(400);
    });
  });

  describe('POST /api/auth/login', () => {
    beforeEach(async () => {
      await request(app).post('/api/auth/register').send({
        email: 'login@test.com',
        password: 'password123',
        role: 'STUDENT',
        name: 'Login Test',
      });
    });

    it('should login with valid credentials', async () => {
      const res = await request(app).post('/api/auth/login').send({
        email: 'login@test.com',
        password: 'password123',
      });

      expect(res.status).toBe(200);
      expect(res.body.data.token).toBeDefined();
    });

    it('should reject invalid password', async () => {
      const res = await request(app).post('/api/auth/login').send({
        email: 'login@test.com',
        password: 'wrong',
      });

      expect(res.status).toBe(401);
    });
  });

  describe('GET /api/auth/me', () => {
    it('should return profile with valid token', async () => {
      const reg = await request(app).post('/api/auth/register').send({
        email: 'me@test.com',
        password: 'password123',
        role: 'STUDENT',
        name: 'Me Test',
      });

      const res = await request(app)
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${reg.body.data.token}`);

      expect(res.status).toBe(200);
      expect(res.body.data.email).toBe('me@test.com');
    });

    it('should reject without token', async () => {
      const res = await request(app).get('/api/auth/me');
      expect(res.status).toBe(401);
    });
  });
});
