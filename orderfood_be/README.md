# OrderFood Backend - Technical Guide

Node.js/TypeScript backend for the OrderFood campus food ordering system. Uses Express, Prisma ORM, PostgreSQL, and a custom SDUI (Server-Driven UI) engine.

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
- **Vendor:** `vendor@orderfood.com` / `password123` (Restaurant: Campus Bites)
- **Student 1:** `rahul@student.com` / `password123`
- **Student 2:** `priya@student.com` / `password123`
- 6 menu items, 3 orders (2 delivered, 1 pending), and matching revenue entries

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
│   ├── middleware/                # Auth (JWT), validation (Zod), error handler
│   ├── repositories/             # Data access layer (Prisma queries)
│   ├── services/                 # Business logic
│   ├── controllers/              # Route handlers (thin, delegate to services)
│   ├── routes/                   # Express route definitions
│   ├── modules/
│   │   └── revenue/              # Isolated revenue module (own MVC stack)
│   ├── sdui/
│   │   ├── components/           # SDUI component type registry
│   │   ├── builders/             # Screen-specific SDUI builders
│   │   ├── registry.ts           # Screen builder registry
│   │   └── types.ts              # SDUI type definitions
│   ├── types/                    # Shared TypeScript interfaces
│   └── utils/                    # Currency helpers (paise/INR conversion)
├── prisma/
│   ├── schema.prisma             # Database schema (12 models)
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
| PATCH | `/orders/:id/status` | Update order status (triggers revenue on DELIVERED) |

### Student (`/api/student`)
| Method | Path | Description |
|--------|------|-------------|
| GET | `/menu/:vendorId` | SDUI menu for a vendor (supports polling) |
| POST | `/orders` | Place an order |
| GET | `/orders` | Order history |
| GET | `/orders/:id` | Order detail |

### Revenue (`/api/revenue`) -- Vendor only
| Method | Path | Description |
|--------|------|-------------|
| GET | `/today` | Today's revenue summary |
| GET | `/overall` | Lifetime revenue since signup |
| GET | `/summary?from=&to=` | Revenue for a date range |
| GET | `/entries?page=&limit=` | Paginated per-order revenue breakdown |

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

The most important integration test is in `tests/student.test.ts` under *"Order delivery triggers revenue"*. It verifies the full flow:

1. Student places an order
2. Vendor marks order as DELIVERED
3. Revenue module automatically records the entry
4. `/api/revenue/today` reflects the new revenue

---

## Architecture Notes

- **SOLID principles** -- Repository pattern, service layer, dependency injection via composition root (`container.ts`)
- **Revenue module is fully isolated** in `src/modules/revenue/` with its own controller, service, repository, routes, and types. Other modules interact with it only through `IRevenueService`. Future payment/commission features go here.
- **All monetary values** are stored as integers in **paise** (1 INR = 100 paise) to avoid floating-point issues. Conversion helpers are in `src/utils/currency.ts`.
- **SDUI** -- The server builds screen layouts as JSON using `ScreenBuilder`. The Flutter app parses and renders them. Screens can be redesigned from the backend without app updates.
