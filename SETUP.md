# OrderFood - Cloud Setup Guide

Deploy OrderFood backend to **Render** (Node.js) + **Neon** (PostgreSQL) for free.

---

## Free Tier Limits

| Service | Free Tier |
|---------|-----------|
| **Neon** (Postgres) | 0.5 GB storage, 190 compute hours/month |
| **Render** (Node.js) | 750 hours/month, sleeps after 15 min inactivity |

> **Note:** Render free tier spins down after 15 minutes of inactivity. First request after sleep takes ~30 seconds.

---

## Step 1: Create Neon Database

1. Go to [neon.tech](https://neon.tech)
2. Sign up with GitHub or email
3. Click **"Create Project"**
4. Choose a project name (e.g., `orderfood`)
5. Select a region closest to you
6. Click **"Create Project"**
7. On the dashboard, copy the **Connection String**:
   ```
   postgresql://username:password@ep-cool-name-123456.us-east-2.aws.neon.tech/neondb?sslmode=require
   ```
   > Keep this safe - you'll need it for Render

---

## Step 2: Deploy to Render

### 2.1 Push Code to GitHub

Make sure your code is pushed to a GitHub repository.

### 2.2 Create Render Account

1. Go to [render.com](https://render.com)
2. Sign up with GitHub

### 2.3 Create Web Service

1. Click **"New +"** → **"Web Service"**
2. Connect your GitHub repository
3. Configure the service:

| Setting | Value |
|---------|-------|
| **Name** | `orderfood-api` |
| **Region** | Oregon (or closest to you) |
| **Root Directory** | `orderfood_be` |
| **Runtime** | Node |
| **Build Command** | `npm install && npm run build` |
| **Start Command** | `npm start` |
| **Instance Type** | Free |

### 2.4 Add Environment Variables

Scroll down to **"Environment Variables"** and add:

| Key | Value |
|-----|-------|
| `DATABASE_URL` | Your Neon connection string (from Step 1) |
| `JWT_SECRET` | Generate a strong random string (use a password generator, 32+ chars) |
| `JWT_EXPIRES_IN` | `7d` |
| `NODE_ENV` | `production` |
| `CORS_ORIGIN` | `*` |
| `POLLING_INTERVAL_MS` | `15000` |
| `UPLOAD_DIR` | `./uploads` |
| `MAX_FILE_SIZE_MB` | `5` |

### 2.5 Deploy

1. Click **"Create Web Service"**
2. Wait for the build to complete (takes 2-5 minutes)
3. Your API will be available at: `https://orderfood-api.onrender.com`

---

## Step 3: Initialize Database

After Render deploys successfully, initialize your Neon database with the schema and seed data.

### 3.1 Configure Local Environment

```bash
cd orderfood_be

# Copy cloud template
copy .env.cloud .env          # Windows
# cp .env.cloud .env           # Mac/Linux
```

### 3.2 Update .env with Neon URL

Edit `.env` and replace the `DATABASE_URL` with your Neon connection string:

```
DATABASE_URL="postgresql://username:password@ep-xxx.aws.neon.tech/neondb?sslmode=require"
```

### 3.3 Push Schema and Seed Data

```bash
npm install                   # Install dependencies
npm run prisma:generate       # Generate Prisma client
npm run db:push               # Push schema to Neon
npm run prisma:seed           # Add test data
```

---

## Step 4: Configure Flutter App

Edit `orderfood/lib/core/network/api_client.dart`:

```dart
class ApiConfig {
  static const bool useCloud = true;  // Enable cloud
  static const String cloudUrl = 'https://orderfood-api.onrender.com/api';  // Your Render URL
  static const String localUrl = 'http://10.0.2.2:3000/api';
  
  static String get baseUrl => useCloud ? cloudUrl : localUrl;
}
```

Then run the Flutter app:

```bash
cd orderfood
flutter pub get
flutter run
```

---

## Test Credentials

After seeding, use these accounts to test:

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@orderfood.com | password123 |
| Vendor | vendor@orderfood.com | password123 |
| Student | rahul@student.com | password123 |
| Student | priya@student.com | password123 |

---

## Verify Deployment

### Check API Health

```bash
curl https://orderfood-api.onrender.com/health
```

Should return:
```json
{"status":"ok"}
```

### Check Database Connection

```bash
curl https://orderfood-api.onrender.com/api/auth/me
```

Should return `401 Unauthorized` (expected - no token provided).

---

## Switching Between Local and Cloud

### Flutter App

Edit `api_client.dart`:

```dart
// For local development
static const bool useCloud = false;

// For cloud testing
static const bool useCloud = true;
```

### Backend (for local testing against cloud DB)

```bash
# Use cloud database
copy .env.cloud .env
npm run dev

# Use local database
copy .env.local .env
npm run dev
```

---

## Troubleshooting

### Build fails on Render

- Check that `Root Directory` is set to `orderfood_be`
- Verify all environment variables are set correctly
- Check build logs for specific errors

### Database connection timeout

- Ensure `?sslmode=require` is in your Neon connection string
- Check if you've exceeded Neon free tier compute hours

### API returns 500 errors

- Check Render logs: Dashboard → Your Service → Logs
- Verify `DATABASE_URL` is correct
- Run `npm run db:push` to ensure schema is synced

### First request is slow (~30s)

- This is normal for Render free tier
- The service spins down after 15 min inactivity
- First request "wakes up" the service

### "Invalid token" errors

- Ensure `JWT_SECRET` is the same across all environments
- Clear app storage and login again

---

## Environment Files Reference

| File | Purpose |
|------|---------|
| `.env` | Active configuration (git ignored) |
| `.env.local` | Template for local development |
| `.env.cloud` | Template for cloud deployment |

---

## Useful Commands

| Command | Description |
|---------|-------------|
| `npm run dev` | Start dev server locally |
| `npm run build` | Build for production |
| `npm start` | Run production build |
| `npm run db:push` | Push schema to database |
| `npm run prisma:seed` | Seed test data |
| `npm run prisma:generate` | Regenerate Prisma client |
