# OrderFood Backend - Technical Guide

Node.js/TypeScript backend for the OrderFood campus food ordering system. Uses Express, Prisma ORM, PostgreSQL, and a custom SDUI (Server-Driven UI) engine.

## Roles

| Role | Description |
|------|-------------|
| **VENDOR** | Restaurant owner - manages menu, views orders, tracks revenue |
| **STUDENT** | Customer - browses menu, places orders, tracks order status |
| **ADMIN** | Platform owner - views platform stats, manages all vendors/students/orders |

---

## Prerequisites

- **Node.js** >= 18.x
- **PostgreSQL** >= 14.x (local install or Docker)
- **npm** >= 9.x

---

## Setup

### 1. Install dependencies

```bash
cd orderfood_be
npm install
```

### 2. Configure environment

Copy `.env.example` to `.env` and update with your PostgreSQL credentials:

```bash
cp .env.example .env
```

| Variable | Default | Description |
|----------|---------|-------------|
| `DATABASE_URL` | `postgresql://postgres:admin@localhost:5433/orderfood?schema=public` | PostgreSQL connection string |
| `JWT_SECRET` | `dev-secret-key-change-in-production` | JWT signing key (change in prod) |
| `JWT_EXPIRES_IN` | `7d` | Token expiry duration |
| `PORT` | `3000` | Server port |
| `NODE_ENV` | `development` | Environment |
| `UPLOAD_DIR` | `./uploads` | Local image upload directory |
| `MAX_FILE_SIZE_MB` | `5` | Max image upload size |
| `CORS_ORIGIN` | `*` | Allowed CORS origin |
| `POLLING_INTERVAL_MS` | `15000` | SDUI polling interval sent to Flutter client |
| `FIREBASE_PROJECT_ID` | *(optional)* | Firebase project ID for push notifications |
| `FIREBASE_PRIVATE_KEY` | *(optional)* | Firebase service account private key |
| `FIREBASE_CLIENT_EMAIL` | *(optional)* | Firebase service account client email |

### 3. Run PostgreSQL with Docker (recommended)

From the `orderfood_be` directory:

```bash
docker compose up -d db
```

This starts a local PostgreSQL instance with:

- **Host/port**: `localhost:5433`
- **User**: `postgres`
- **Password**: `admin`
- **Database**: `orderfood`

Data is stored in the named Docker volume `orderfood_pg_data` so it persists across container restarts.

### 4. Generate Prisma client

This happens automatically during `npm install`, but if you ever change `prisma/schema.prisma`, regenerate manually:

```bash
npm run prisma:generate
```

### 5. Create database and run migrations

```bash
npx prisma migrate dev --name init
```

### 6. Seed test data

```bash
npm run prisma:seed
```

This creates:
- **Admin:** `admin@orderfood.com` / `password123` (Platform Admin)
- **Vendor:** `vendor@orderfood.com` / `password123` (Restaurant: Campus Bites)
- **Student 1:** `rahul@student.com` / `password123`
- **Student 2:** `priya@student.com` / `password123`
- 6 menu items, 3 orders (2 ready, 1 pending), and matching revenue entries

### 7. Start the dev server

```bash
npm run dev
```

Server runs at `http://localhost:3000`. Verify with `GET /health`.

---

## NPM Scripts

| Script | What it does |
|--------|-------------|
| `npm run dev` | Start dev server with hot reload (ts-node-dev) |
| `npm run build` | Compile TypeScript to `dist/` |
| `npm start` | Run compiled JS from `dist/` |
| `npm run prisma:generate` | Regenerate Prisma client after schema changes |
| `npm run prisma:migrate` | Create and apply new migration |
| `npm run prisma:seed` | Seed the database with test data |
| `npm test` | Run all test suites |
| `npm run test:watch` | Run tests in watch mode |

---

## Project Structure

```
orderfood_be/
├── src/
│   ├── app.ts                    # Express app entry point
│   ├── container.ts              # Dependency injection (composition root)
│   ├── config/                   # Environment, database client
│   ├── middleware/               # Auth (JWT), validation (Zod), error handler
│   ├── repositories/             # Data access layer (Prisma queries)
│   ├── services/                 # Business logic
│   ├── controllers/              # Route handlers (thin, delegate to services)
│   ├── routes/                   # Express route definitions
│   ├── modules/
│   │   ├── revenue/              # Isolated revenue module (own MVC stack)
│   │   └── admin/                # Isolated admin module (platform management)
│   ├── sdui/
│   │   ├── components/           # SDUI component type registry
│   │   ├── builders/             # Screen-specific SDUI builders
│   │   ├── registry.ts           # Screen builder registry
│   │   └── types.ts              # SDUI type definitions
│   ├── types/                    # Shared TypeScript interfaces
│   └── utils/                    # Currency helpers (paise/INR conversion)
├── prisma/
│   ├── schema.prisma             # Database schema (13 models)
│   └── seed.ts                   # Seed script
├── tests/                        # Jest + Supertest integration tests
├── uploads/                      # Local image storage
└── package.json
```

---

## API Endpoints

All endpoints are prefixed with `/api`.

### Auth (`/api/auth`)
| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/register` | No | Register vendor or student |
| POST | `/login` | No | Login, returns JWT |
| GET | `/me` | Yes | Current user profile |

### Vendor (`/api/vendor`)
| Method | Path | Description |
|--------|------|-------------|
| GET | `/dashboard` | SDUI dashboard with live revenue stats |
| GET | `/menu` | SDUI menu management screen |
| POST | `/menu/items` | Create menu item (price in INR, stored as paise) |
| PUT | `/menu/items/:id` | Update menu item |
| PATCH | `/menu/items/:id/availability` | Toggle sold out / back in stock |
| POST | `/menu/items/:id/image` | Upload image (multipart/form-data) |
| DELETE | `/menu/items/:id` | Delete menu item |
| GET | `/orders` | List orders (filterable by status, date) |
| PATCH | `/orders/:id/status` | Update order status (triggers revenue on READY) |

### Student (`/api/student`)
| Method | Path | Description |
|--------|------|-------------|
| GET | `/vendors` | List all available vendors with menu counts |
| GET | `/menu/:vendorId` | SDUI menu for a vendor (supports polling) |
| POST | `/orders` | Place an order |
| GET | `/orders` | Order history (includes payment status) |
| GET | `/orders/:id` | Order detail |

### Revenue (`/api/revenue`) -- Vendor only
| Method | Path | Description |
|--------|------|-------------|
| GET | `/today` | Today's revenue summary |
| GET | `/overall` | Lifetime revenue since signup |
| GET | `/summary?from=&to=` | Revenue for a date range |
| GET | `/entries?page=&limit=` | Paginated per-order revenue breakdown |

### Admin (`/api/admin`) -- Admin only
| Method | Path | Description |
|--------|------|-------------|
| GET | `/dashboard` | SDUI admin dashboard with platform stats |
| GET | `/dashboard/vendors` | SDUI vendor management screen |
| GET | `/dashboard/students` | SDUI student management screen |
| GET | `/dashboard/orders` | SDUI all orders screen (filterable) |
| GET | `/stats` | Platform statistics (JSON) |
| GET | `/vendors` | List all vendors with stats |
| GET | `/students` | List all students with stats |
| GET | `/orders` | List all orders (filterable by status, vendorId) |
| DELETE | `/vendors/:vendorId` | Delete vendor and all associated data |
| DELETE | `/students/:studentId` | Delete student and all associated data |
| POST | `/vendors/bulk` | Bulk upload vendors with menu items (JSON) |

### Payment (`/api/payment`)
| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/` | STUDENT | Create payment for an order (returns QR code) |
| GET | `/:paymentId` | Yes | Get payment details |
| GET | `/order/:orderId` | Yes | Get payment by order ID |
| POST | `/:paymentId/confirm` | Yes | Confirm payment with transaction ID |
| GET | `/:paymentId/status` | Yes | Check payment status |

### Notifications (`/api/notifications`)
| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/device/register` | Yes | Register device for push notifications |
| POST | `/device/unregister` | Yes | Unregister device from push notifications |
| GET | `/` | Yes | Get paginated notification history |
| GET | `/unread-count` | Yes | Get count of unread notifications |
| PATCH | `/:id/read` | Yes | Mark a notification as read |
| PATCH | `/read-all` | Yes | Mark all notifications as read |

### SDUI Admin (`/api/sdui`)
| Method | Path | Description |
|--------|------|-------------|
| GET | `/layouts` | List all stored layouts |
| PUT | `/layouts/:screenName` | Create or update a screen layout |
| GET | `/components` | List all registered SDUI component types |

### Static
| Path | Description |
|------|-------------|
| `GET /uploads/:filename` | Serve uploaded menu item images |
| `GET /health` | Health check |

---

## Testing

Tests require a running PostgreSQL database. Update `.env` with valid credentials before running.

```bash
npm test
```

### Test Suites

| File | What it tests |
|------|--------------|
| `tests/auth.test.ts` | **Auth flow:** vendor registration, student registration, duplicate email rejection, vendor requires restaurant name, login with valid/invalid credentials, `/me` endpoint with and without JWT |
| `tests/vendor.test.ts` | **Vendor features:** create menu item (verifies INR-to-paise conversion), toggle availability (sold out / back in stock), delete menu item, SDUI menu screen structure, SDUI dashboard with revenue stat cards |
| `tests/student.test.ts` | **Student features:** SDUI menu browsing for a vendor, place order (verifies total calculation), reject order for unavailable items, list student orders, **end-to-end revenue trigger** (order placed -> vendor marks DELIVERED -> revenue recorded) |
| `tests/revenue/revenue.test.ts` | **Revenue module:** empty today summary, summary after revenue recording, overall lifetime summary, paginated entries, rejects non-vendor access (403) |
| `tests/sdui.test.ts` | **SDUI admin:** list registered component types, empty layouts, create/update layout, health check endpoint |

### Key test: Revenue integration

The most important integration test is in `tests/student.test.ts` under *"Order ready triggers revenue"*. It verifies the full flow:

1. Student places an order
2. Vendor marks order as READY
3. Revenue module automatically records the entry
4. `/api/revenue/today` reflects the new revenue

---

## Order Status Flow

This is a **pickup-based** system (not delivery). Students come to the restaurant when their order is ready.

```
PENDING → CONFIRMED → PREPARING → READY → (student picks up)
                              ↘ CANCELLED
```

- **PENDING**: Order placed, waiting for vendor confirmation
- **CONFIRMED**: Vendor accepted the order
- **PREPARING**: Kitchen is preparing the food
- **READY**: Food is ready for pickup (revenue recorded at this point)
- **CANCELLED**: Order was cancelled

---

## Architecture Notes

- **SOLID principles** -- Repository pattern, service layer, dependency injection via composition root (`container.ts`)
- **Revenue module is fully isolated** in `src/modules/revenue/` with its own controller, service, repository, routes, and types. Other modules interact with it only through `IRevenueService`.
- **Admin module is fully isolated** in `src/modules/admin/` with its own controller, service, repository, routes, and types. Platform management stays contained here.
- **Payment module is fully isolated** in `src/modules/payment/` with its own controller, service, repository, routes, and types. QR code UPI payments are handled here.
- **Notification module is fully isolated** in `src/modules/notification/` with FCM integration, device token management, and notification history. Triggers are called from other services for order/stock/payment events.
- **All monetary values** are stored as integers in **paise** (1 INR = 100 paise) to avoid floating-point issues. Conversion helpers are in `src/utils/currency.ts`.
- **SDUI** -- The server builds screen layouts as JSON using `ScreenBuilder`. The Flutter app parses and renders them. Screens can be redesigned from the backend without app updates.

---

## Push Notifications Setup

The app supports real-time push notifications via Firebase Cloud Messaging (FCM).

### Backend Setup

1. **Create a Firebase project** at [Firebase Console](https://console.firebase.google.com/)
2. **Generate a service account key:**
   - Go to Project Settings > Service Accounts
   - Click "Generate New Private Key"
   - Download the JSON file
3. **Add credentials to `.env`:**
   ```
   FIREBASE_PROJECT_ID=your-project-id
   FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
   FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com
   ```

If no Firebase credentials are provided, the backend uses a mock FCM service that logs notifications to console (useful for development).

### Flutter App Setup

1. **Add Firebase to your Flutter project:**
   - Go to Firebase Console > Project Settings > Add App
   - Follow the setup wizard for Android/iOS
   - Download `google-services.json` (Android) or `GoogleService-Info.plist` (iOS)
2. **Place config files:**
   - Android: `orderfood/android/app/google-services.json`
   - iOS: `orderfood/ios/Runner/GoogleService-Info.plist`

### Notification Types

| Type | Recipient | Trigger |
|------|-----------|---------|
| `ORDER_PLACED` | Vendor | Student places new order |
| `ORDER_CONFIRMED` | Student | Vendor confirms order |
| `ORDER_PREPARING` | Student | Vendor starts preparing |
| `ORDER_READY` | Student | Order ready for pickup |
| `ORDER_CANCELLED` | Student | Order cancelled |
| `ITEM_OUT_OF_STOCK` | Students (recent) | Vendor marks item unavailable |
| `ITEM_BACK_IN_STOCK` | Students (recent) | Vendor marks item available again |
| `PAYMENT_RECEIVED` | Student + Vendor | Payment confirmed |
| `PAYMENT_FAILED` | Student | Payment expired/failed |

---

## Bulk Vendor Upload

Admins can upload multiple vendors with their menus in a single API call.

**Endpoint:** `POST /api/admin/vendors/bulk`

**Request Body:**

```json
{
  "vendors": [
    {
      "email": "vendor1@example.com",
      "password": "securePassword123",
      "restaurantName": "Campus Cafe",
      "description": "Fresh coffee and snacks",
      "menuItems": [
        {
          "name": "Espresso",
          "description": "Strong Italian coffee",
          "priceInRupees": 80,
          "category": "Beverages",
          "isAvailable": true
        },
        {
          "name": "Sandwich",
          "priceInRupees": 120,
          "category": "Snacks"
        }
      ]
    },
    {
      "email": "vendor2@example.com",
      "password": "anotherPassword456",
      "restaurantName": "Dosa Corner",
      "menuItems": [
        {
          "name": "Masala Dosa",
          "priceInRupees": 70,
          "category": "South Indian"
        }
      ]
    }
  ]
}
```

**Response:**

```json
{
  "success": true,
  "data": {
    "success": 2,
    "failed": 0,
    "errors": [],
    "vendors": [
      { "id": "uuid-1", "email": "vendor1@example.com", "restaurantName": "Campus Cafe" },
      { "id": "uuid-2", "email": "vendor2@example.com", "restaurantName": "Dosa Corner" }
    ]
  }
}
```

---

## Database Commands Reference

After modifying `prisma/schema.prisma`:

```bash
# 1. Generate new Prisma client (required after any schema change)
npm run prisma:generate

# 2. Create and apply migration (for structural changes)
npx prisma migrate dev --name describe_your_change

# 3. Re-seed if you want fresh test data
npm run prisma:seed
```

**For the ADMIN role addition specifically:**

```bash
# Since schema already has ADMIN role and Admin model, just run:
npm run prisma:generate          # Regenerate Prisma client
npx prisma migrate dev --name add_admin_role   # Create migration
npm run prisma:seed              # Seed includes admin user now
```
