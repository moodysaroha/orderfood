# OrderFood - Technical Specification

A full-stack campus food ordering system with Server-Driven UI architecture.

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Technology Stack](#technology-stack)
3. [User Roles](#user-roles)
4. [Backend Architecture](#backend-architecture)
5. [Frontend Architecture](#frontend-architecture)
6. [Database Schema](#database-schema)
7. [API Reference](#api-reference)
8. [SDUI System](#sdui-system)
9. [Feature Map](#feature-map)
10. [File Reference](#file-reference)

---

## System Overview

OrderFood is a mobile-first food ordering platform for campus restaurants. It consists of:

- **Backend**: Node.js/TypeScript REST API with SDUI capabilities
- **Frontend**: Flutter Android app with SDUI rendering engine
- **Database**: PostgreSQL with Prisma ORM

### Key Architectural Decisions

| Decision | Rationale |
|----------|-----------|
| Server-Driven UI | Update app layouts without releasing new app versions |
| Paise-based currency | Avoid floating-point precision issues (1 INR = 100 paise) |
| Isolated modules | Revenue, Admin, Payment, Notification modules are self-contained for extensibility |
| JWT authentication | Stateless auth, mobile-friendly |
| Pickup-based flow | No delivery - students pick up orders when READY |
| UPI QR Payments | Native Indian payment method, works with all UPI apps |
| Multi-vendor support | Students can browse and order from multiple restaurants |
| Push notifications | Real-time alerts via Firebase Cloud Messaging (FCM) |

---

## Technology Stack

### Backend (`orderfood_be/`)

| Component | Technology | Purpose |
|-----------|-----------|---------|
| Runtime | Node.js 18+ | Server runtime |
| Language | TypeScript (strict) | Type safety |
| Framework | Express.js | HTTP server |
| ORM | Prisma | Database access |
| Database | PostgreSQL 14+ | Data persistence |
| Auth | JWT (jsonwebtoken) | Authentication |
| Password | bcrypt | Password hashing |
| Validation | Zod | Request validation |
| File Upload | Multer | Image uploads |
| Testing | Jest + Supertest | Integration tests |

### Frontend (`orderfood/`)

| Component | Technology | Purpose |
|-----------|-----------|---------|
| Framework | Flutter 3.x | Cross-platform UI |
| Language | Dart | App development |
| State Management | Riverpod | Dependency injection, state |
| HTTP Client | Dio | API communication |
| Secure Storage | flutter_secure_storage | Token persistence |
| Image Caching | cached_network_image | Efficient image loading |
| QR Code | qr_flutter | QR code generation |
| URL Launcher | url_launcher | Open UPI apps |
| Firebase Core | firebase_core | Firebase initialization |
| Push Notifications | firebase_messaging | FCM push notifications |
| Local Notifications | flutter_local_notifications | Foreground notification display |

---

## User Roles

### VENDOR
- Owns a restaurant
- Manages menu items (CRUD, images, availability)
- Views dashboard with revenue stats
- Manages incoming orders (status updates)
- Receives push notifications for new orders and payments
- Can logout from app

### STUDENT
- Browses multiple restaurants
- Browses restaurant menus
- Places orders
- Pays via UPI QR code
- Tracks order history, payment status
- Picks up food when order is READY
- Receives push notifications for order updates, stock changes
- Can logout from app

### ADMIN
- Platform owner/developer
- Views platform-wide statistics
- Manages all vendors (view, delete, bulk upload)
- Manages all students (view, delete)
- Views all orders across vendors
- Can logout from app

---

## Backend Architecture

### Design Patterns

| Pattern | Implementation | Location |
|---------|---------------|----------|
| Repository | Data access abstraction | `src/repositories/` |
| Service Layer | Business logic isolation | `src/services/` |
| Dependency Injection | Composition root | `src/container.ts` |
| Factory | SDUI component builders | `src/sdui/builders/` |
| Module | Isolated feature boundaries | `src/modules/` |

### Request Flow

```
HTTP Request
    ↓
Express Router (src/routes/)
    ↓
Middleware (auth, validation)
    ↓
Controller (src/controllers/)
    ↓
Service (src/services/)
    ↓
Repository (src/repositories/)
    ↓
Prisma Client
    ↓
PostgreSQL
```

### Module Boundaries

**Revenue Module** (`src/modules/revenue/`)
- Completely isolated with own routes, controller, service, repository
- Other modules call only through `IRevenueService` interface
- Designed for future payment gateway integration

**Admin Module** (`src/modules/admin/`)
- Completely isolated with own routes, controller, service, repository
- Platform-wide operations only
- Protected by ADMIN role middleware

---

## Frontend Architecture

### Architecture Pattern

Feature-first with clean architecture layers:

```
lib/
├── core/           # Shared infrastructure
├── features/       # Feature modules (auth, vendor, student, admin)
└── main.dart       # App entry point
```

### SDUI Rendering Flow

```
API Response (JSON)
    ↓
SduiScreenWidget (fetches, polls)
    ↓
SduiScreen.fromJson() (parsing)
    ↓
SduiWidgetFactory (component registry)
    ↓
Flutter Widgets (native rendering)
```

### State Management

- **Riverpod** for dependency injection
- **ApiClient** as singleton provider
- **StatefulWidget** for local screen state
- **SDUI polling** for real-time updates (configurable interval)

---

## Database Schema

### Enums

| Enum | Values |
|------|--------|
| Role | `VENDOR`, `STUDENT`, `ADMIN` |
| OrderStatus | `PENDING`, `CONFIRMED`, `PREPARING`, `READY`, `CANCELLED` |
| PaymentStatus | `PENDING`, `COMPLETED`, `FAILED`, `REFUNDED` |
| NotificationType | `ORDER_PLACED`, `ORDER_CONFIRMED`, `ORDER_PREPARING`, `ORDER_READY`, `ORDER_CANCELLED`, `ITEM_OUT_OF_STOCK`, `ITEM_BACK_IN_STOCK`, `PAYMENT_RECEIVED`, `PAYMENT_FAILED`, `GENERAL` |

### Models

| Model | Purpose | Key Fields |
|-------|---------|------------|
| User | Authentication | email, passwordHash, role |
| Vendor | Restaurant profile | userId, restaurantName, description |
| Student | Customer profile | userId, name |
| Admin | Platform admin profile | userId, name |
| MenuItem | Food items | vendorId, name, priceInPaise, isAvailable |
| Order | Customer orders | studentId, vendorId, status, paymentStatus, totalAmountInPaise |
| OrderItem | Line items | orderId, menuItemId, quantity, priceAtOrderInPaise |
| Payment | UPI payments | orderId, amountInPaise, status, qrCodeData, transactionId |
| RevenueEntry | Per-order revenue | vendorId, orderId, grossAmountInPaise, netAmountInPaise |
| RevenueSummary | Daily aggregates | vendorId, date, totalOrderCount, netRevenueInPaise |
| SduiLayout | Stored screen layouts | screenName, role, layoutJson |
| DeviceToken | FCM device tokens | userId, token, platform, isActive |
| Notification | Notification history | userId, type, title, body, data, isRead |

### Relationships

```
User 1:1 Vendor
User 1:1 Student
User 1:1 Admin
User 1:N DeviceToken
User 1:N Notification
Vendor 1:N MenuItem
Vendor 1:N Order
Vendor 1:N RevenueEntry
Vendor 1:N RevenueSummary
Student 1:N Order
Order 1:N OrderItem
Order 1:1 RevenueEntry
Order 1:1 Payment
MenuItem 1:N OrderItem
```

---

## API Reference

### Authentication Endpoints

| Endpoint | Method | Auth | Purpose |
|----------|--------|------|---------|
| `/api/auth/register` | POST | No | Register new user |
| `/api/auth/login` | POST | No | Login, get JWT |
| `/api/auth/me` | GET | Yes | Get current user |

### Vendor Endpoints

| Endpoint | Method | Auth | Purpose |
|----------|--------|------|---------|
| `/api/vendor/dashboard` | GET | VENDOR | SDUI dashboard |
| `/api/vendor/menu` | GET | VENDOR | SDUI menu screen |
| `/api/vendor/menu/items` | POST | VENDOR | Create menu item |
| `/api/vendor/menu/items/:id` | PUT | VENDOR | Update menu item |
| `/api/vendor/menu/items/:id/availability` | PATCH | VENDOR | Toggle availability |
| `/api/vendor/menu/items/:id/image` | POST | VENDOR | Upload image |
| `/api/vendor/menu/items/:id` | DELETE | VENDOR | Delete item |
| `/api/vendor/orders` | GET | VENDOR | List orders |
| `/api/vendor/orders/:id/status` | PATCH | VENDOR | Update status |

### Student Endpoints

| Endpoint | Method | Auth | Purpose |
|----------|--------|------|---------|
| `/api/student/vendors` | GET | Yes | List all vendors with menu counts |
| `/api/student/menu/:vendorId` | GET | Yes | SDUI menu for vendor |
| `/api/student/orders` | POST | STUDENT | Place order |
| `/api/student/orders` | GET | STUDENT | Order history (with payment status) |
| `/api/student/orders/:id` | GET | STUDENT | Order detail |

### Admin Endpoints

| Endpoint | Method | Auth | Purpose |
|----------|--------|------|---------|
| `/api/admin/dashboard` | GET | ADMIN | SDUI dashboard |
| `/api/admin/dashboard/vendors` | GET | ADMIN | SDUI vendors screen |
| `/api/admin/dashboard/students` | GET | ADMIN | SDUI students screen |
| `/api/admin/dashboard/orders` | GET | ADMIN | SDUI orders screen |
| `/api/admin/stats` | GET | ADMIN | Platform statistics |
| `/api/admin/vendors` | GET | ADMIN | All vendors |
| `/api/admin/students` | GET | ADMIN | All students |
| `/api/admin/orders` | GET | ADMIN | All orders |
| `/api/admin/vendors/:id` | DELETE | ADMIN | Delete vendor |
| `/api/admin/students/:id` | DELETE | ADMIN | Delete student |
| `/api/admin/vendors/bulk` | POST | ADMIN | Bulk upload vendors with menus |

### Payment Endpoints

| Endpoint | Method | Auth | Purpose |
|----------|--------|------|---------|
| `/api/payment` | POST | STUDENT | Create payment (returns QR code) |
| `/api/payment/:paymentId` | GET | Yes | Get payment details |
| `/api/payment/order/:orderId` | GET | Yes | Get payment by order ID |
| `/api/payment/:paymentId/confirm` | POST | Yes | Confirm payment with transaction ID |
| `/api/payment/:paymentId/status` | GET | Yes | Check payment status |

### Revenue Endpoints

| Endpoint | Method | Auth | Purpose |
|----------|--------|------|---------|
| `/api/revenue/today` | GET | VENDOR | Today's summary |
| `/api/revenue/overall` | GET | VENDOR | Lifetime summary |
| `/api/revenue/summary` | GET | VENDOR | Date range summary |
| `/api/revenue/entries` | GET | VENDOR | Paginated entries |

### Notification Endpoints

| Endpoint | Method | Auth | Purpose |
|----------|--------|------|---------|
| `/api/notifications/device/register` | POST | Yes | Register device for push notifications |
| `/api/notifications/device/unregister` | POST | Yes | Unregister device from push notifications |
| `/api/notifications` | GET | Yes | Get paginated notification history |
| `/api/notifications/unread-count` | GET | Yes | Get count of unread notifications |
| `/api/notifications/:id/read` | PATCH | Yes | Mark notification as read |
| `/api/notifications/read-all` | PATCH | Yes | Mark all notifications as read |

### SDUI Endpoints

| Endpoint | Method | Auth | Purpose |
|----------|--------|------|---------|
| `/api/sdui/layouts` | GET | No | List layouts |
| `/api/sdui/layouts/:screenName` | PUT | No | Update layout |
| `/api/sdui/components` | GET | No | List component types |

---

## SDUI System

### Component Types

| Category | Components |
|----------|-----------|
| Layout | `scaffold`, `column`, `row`, `container`, `card`, `divider`, `spacer` |
| Navigation | `appBar`, `bottomNav`, `tabBar` |
| Content | `text`, `image`, `icon`, `badge`, `avatar` |
| Dashboard | `statsRow`, `statCard`, `sectionHeader` |
| Lists | `list`, `listTile`, `orderTile`, `menuItemTile`, `menuItemCard` |
| Interactive | `button`, `iconButton`, `switchToggle`, `chip`, `fab` |
| Feedback | `emptyState`, `loading`, `errorDisplay` |

### Action Types

| Type | Purpose | Properties |
|------|---------|------------|
| `navigate` | In-app navigation | `route` |
| `api_call` | Backend API call | `method`, `url`, `confirmMessage` |
| `refresh` | Reload screen | - |
| `toggle` | Toggle state | - |

### Screen Builders

| Builder | Screen Name | Role | Purpose |
|---------|------------|------|---------|
| DashboardScreenBuilder | `vendor_dashboard` | VENDOR | Revenue stats, recent orders |
| VendorMenuScreenBuilder | `vendor_menu` | VENDOR | Menu management |
| StudentMenuScreenBuilder | `student_menu` | STUDENT | Browse & order |
| AdminDashboardScreenBuilder | `admin_dashboard` | ADMIN | Platform stats |
| AdminVendorsScreenBuilder | `admin_vendors` | ADMIN | Vendor management |
| AdminStudentsScreenBuilder | `admin_students` | ADMIN | Student management |
| AdminOrdersScreenBuilder | `admin_orders` | ADMIN | All orders |

---

## Feature Map

### Vendor Features

| Feature | Backend | Frontend |
|---------|---------|----------|
| Dashboard | `src/sdui/builders/dashboard.builder.ts` | `lib/features/vendor/dashboard/` |
| Menu Management | `src/routes/vendor.routes.ts`, `src/services/vendor.service.ts` | `lib/features/vendor/menu/` |
| Order Management | `src/routes/vendor.routes.ts` | `lib/features/vendor/orders/` |
| Image Upload | `src/routes/vendor.routes.ts` (Multer) | `lib/features/vendor/menu/` |
| Revenue Stats | `src/modules/revenue/` | Displayed in dashboard |
| Logout | N/A | `lib/features/vendor/dashboard/vendor_dashboard_screen.dart` |

### Student Features

| Feature | Backend | Frontend |
|---------|---------|----------|
| Browse Menu | `src/routes/student.routes.ts`, `src/sdui/builders/student-menu.builder.ts` | `lib/features/student/menu/` |
| Place Order | `src/services/student.service.ts` | `lib/features/student/menu/` |
| Order History | `src/routes/student.routes.ts` | `lib/features/student/orders/` |
| Logout | N/A | `lib/features/student/student_home_screen.dart` |

### Admin Features

| Feature | Backend | Frontend |
|---------|---------|----------|
| Platform Stats | `src/modules/admin/admin.service.ts` | `lib/features/admin/admin_dashboard_screen.dart` |
| Manage Vendors | `src/modules/admin/admin.controller.ts` | `lib/features/admin/admin_vendors_screen.dart` |
| Manage Students | `src/modules/admin/admin.controller.ts` | `lib/features/admin/admin_students_screen.dart` |
| View All Orders | `src/modules/admin/admin.controller.ts` | `lib/features/admin/admin_orders_screen.dart` |
| Logout | N/A | `lib/features/admin/admin_dashboard_screen.dart` |

### Cross-Cutting Features

| Feature | Backend | Frontend |
|---------|---------|----------|
| Authentication | `src/routes/auth.routes.ts`, `src/middleware/auth.middleware.ts` | `lib/features/auth/auth_screen.dart` |
| JWT Handling | `src/middleware/auth.middleware.ts` | `lib/core/network/api_client.dart` |
| Currency Formatting | `src/utils/currency.ts` | `lib/core/currency/currency_utils.dart` |
| Theme (Purple + Dark Mode) | N/A | `lib/core/theme/app_theme.dart` |
| SDUI Rendering | `src/sdui/` | `lib/core/sdui/` |

---

## File Reference

### Backend Files (`orderfood_be/`)

#### Entry & Configuration

| File | Purpose |
|------|---------|
| `src/app.ts` | Express app setup, middleware chain, route mounting |
| `src/container.ts` | Dependency injection composition root |
| `src/config/env.ts` | Environment variable loading |
| `src/config/database.ts` | Prisma client singleton |

#### Middleware

| File | Purpose |
|------|---------|
| `src/middleware/auth.middleware.ts` | JWT verification, `authenticate`, `requireRole` |
| `src/middleware/validation.middleware.ts` | Zod schema validation |
| `src/middleware/error.middleware.ts` | Global error handler, `AppError` class |
| `src/middleware/index.ts` | Barrel export |

#### Routes

| File | Purpose |
|------|---------|
| `src/routes/index.ts` | Main router, mounts all sub-routers |
| `src/routes/auth.routes.ts` | `/api/auth/*` endpoints |
| `src/routes/vendor.routes.ts` | `/api/vendor/*` endpoints, Multer setup |
| `src/routes/student.routes.ts` | `/api/student/*` endpoints |
| `src/routes/sdui.routes.ts` | `/api/sdui/*` endpoints |

#### Controllers

| File | Purpose |
|------|---------|
| `src/controllers/auth.controller.ts` | Register, login, profile |
| `src/controllers/vendor.controller.ts` | Menu CRUD, orders, SDUI screens |
| `src/controllers/student.controller.ts` | Browse menu, place orders |
| `src/controllers/sdui.controller.ts` | Layout management |

#### Services

| File | Purpose |
|------|---------|
| `src/services/auth.service.ts` | User registration, login validation |
| `src/services/vendor.service.ts` | Menu management, order status updates |
| `src/services/student.service.ts` | Order placement, cart calculation |

#### Repositories

| File | Purpose |
|------|---------|
| `src/repositories/user.repository.ts` | User data access |
| `src/repositories/vendor.repository.ts` | Vendor data access |
| `src/repositories/student.repository.ts` | Student data access |
| `src/repositories/menu-item.repository.ts` | MenuItem CRUD |
| `src/repositories/order.repository.ts` | Order queries, status updates |
| `src/repositories/sdui-layout.repository.ts` | SDUI layout storage |

#### Revenue Module

| File | Purpose |
|------|---------|
| `src/modules/revenue/index.ts` | Module barrel export |
| `src/modules/revenue/revenue.types.ts` | Type definitions |
| `src/modules/revenue/revenue.repository.ts` | Revenue data access |
| `src/modules/revenue/revenue.service.ts` | Revenue recording, aggregation |
| `src/modules/revenue/revenue.controller.ts` | Revenue API handlers |
| `src/modules/revenue/revenue.routes.ts` | `/api/revenue/*` routes |

#### Admin Module

| File | Purpose |
|------|---------|
| `src/modules/admin/index.ts` | Module barrel export |
| `src/modules/admin/admin.types.ts` | Platform stats types, bulk upload types |
| `src/modules/admin/admin.repository.ts` | Platform-wide queries, bulk vendor creation |
| `src/modules/admin/admin.service.ts` | Admin business logic |
| `src/modules/admin/admin.controller.ts` | Admin API + SDUI handlers |
| `src/modules/admin/admin.routes.ts` | `/api/admin/*` routes |

#### Payment Module

| File | Purpose |
|------|---------|
| `src/modules/payment/index.ts` | Module barrel export |
| `src/modules/payment/payment.types.ts` | Payment, QR code types |
| `src/modules/payment/payment.repository.ts` | Payment data access |
| `src/modules/payment/payment.service.ts` | QR generation, payment confirmation |
| `src/modules/payment/payment.controller.ts` | Payment API handlers |
| `src/modules/payment/payment.routes.ts` | `/api/payment/*` routes |

#### Notification Module

| File | Purpose |
|------|---------|
| `src/modules/notification/index.ts` | Module barrel export |
| `src/modules/notification/notification.types.ts` | Notification, device token types |
| `src/modules/notification/notification.repository.ts` | Notification + device data access |
| `src/modules/notification/notification.service.ts` | Send notifications, manage history |
| `src/modules/notification/notification.controller.ts` | Notification API handlers |
| `src/modules/notification/notification.routes.ts` | `/api/notifications/*` routes |
| `src/modules/notification/fcm.service.ts` | Firebase Cloud Messaging integration |

#### SDUI

| File | Purpose |
|------|---------|
| `src/sdui/types.ts` | SDUI type definitions |
| `src/sdui/registry.ts` | Screen builder registry |
| `src/sdui/components/index.ts` | Component type constants |
| `src/sdui/builders/screen.builder.ts` | Fluent screen builder |
| `src/sdui/builders/dashboard.builder.ts` | Vendor dashboard builder |
| `src/sdui/builders/vendor-menu.builder.ts` | Vendor menu builder |
| `src/sdui/builders/student-menu.builder.ts` | Student menu builder |
| `src/sdui/builders/admin-dashboard.builder.ts` | Admin screen builders |

#### Utilities

| File | Purpose |
|------|---------|
| `src/utils/currency.ts` | `rupeesToPaise`, `paiseToRupees`, `formatINR`, `formatPaiseToINR` |

#### Database

| File | Purpose |
|------|---------|
| `prisma/schema.prisma` | Database schema (14 models, 3 enums) |
| `prisma/seed.ts` | Test data seeding |

### Frontend Files (`orderfood/lib/`)

#### Entry

| File | Purpose |
|------|---------|
| `main.dart` | App entry, routing based on role, logout handling |

#### Core - Theme

| File | Purpose |
|------|---------|
| `core/theme/app_theme.dart` | Purple theme, light/dark mode definitions |

#### Core - Network

| File | Purpose |
|------|---------|
| `core/network/api_client.dart` | Dio setup, JWT interceptor, token storage |

#### Core - Currency

| File | Purpose |
|------|---------|
| `core/currency/currency_utils.dart` | `formatPaise`, `formatRupees` |

#### Core - SDUI

| File | Purpose |
|------|---------|
| `core/sdui/sdui_models.dart` | `SduiScreen`, `SduiComponent`, `SduiAction` |
| `core/sdui/sdui_screen_widget.dart` | Generic SDUI screen fetcher/renderer |
| `core/sdui/sdui_registry.dart` | `SduiWidgetFactory`, component registration |
| `core/sdui/widgets/sdui_widgets.dart` | Widget builder functions for all components |

#### Core - Notifications

| File | Purpose |
|------|---------|
| `core/notifications/notification_service.dart` | Firebase messaging setup, local notifications |
| `core/notifications/notification_provider.dart` | State management for notifications |
| `core/notifications/notification_bell.dart` | AppBar notification icon with badge |

#### Features - Notifications

| File | Purpose |
|------|---------|
| `features/notifications/notifications_screen.dart` | Notification history list UI |

#### Features - Auth

| File | Purpose |
|------|---------|
| `features/auth/auth_screen.dart` | Login/register UI, role selection |

#### Features - Vendor

| File | Purpose |
|------|---------|
| `features/vendor/vendor_home_screen.dart` | Bottom nav, screen container |
| `features/vendor/dashboard/vendor_dashboard_screen.dart` | SDUI dashboard, logout button |
| `features/vendor/menu/vendor_menu_screen.dart` | SDUI menu management |
| `features/vendor/orders/vendor_orders_screen.dart` | Order list, status updates |

#### Features - Student

| File | Purpose |
|------|---------|
| `features/student/student_home_screen.dart` | Bottom nav, vendor list (API), logout |
| `features/student/menu/student_menu_screen.dart` | SDUI menu browsing |
| `features/student/orders/student_orders_screen.dart` | Order history, payment status |
| `features/student/payment/qr_payment_screen.dart` | QR code payment, UPI deep link |

#### Features - Admin

| File | Purpose |
|------|---------|
| `features/admin/admin_home_screen.dart` | Bottom nav with 4 tabs |
| `features/admin/admin_dashboard_screen.dart` | SDUI platform stats, logout |
| `features/admin/admin_vendors_screen.dart` | Vendor list, delete |
| `features/admin/admin_students_screen.dart` | Student list, delete |
| `features/admin/admin_orders_screen.dart` | All orders, status filter |

---

## Getting Started

### Backend Setup

```bash
cd orderfood_be
npm install
cp .env.example .env          # Configure DATABASE_URL
docker compose up -d db       # Start PostgreSQL
npm run prisma:generate       # Generate Prisma client
npx prisma migrate dev        # Apply migrations
npm run prisma:seed           # Seed test data
npm run dev                   # Start server at :3000
```

### Frontend Setup

```bash
cd orderfood
flutter pub get
# Update API base URL in lib/core/network/api_client.dart if needed
flutter run
```

### Test Credentials

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@orderfood.com | password123 |
| Vendor | vendor@orderfood.com | password123 |
| Student | rahul@student.com | password123 |
| Student | priya@student.com | password123 |

---

## Order Flow

```
Student places order
        ↓
    [PENDING]
        ↓
Vendor confirms
        ↓
   [CONFIRMED]
        ↓
Vendor starts prep
        ↓
   [PREPARING]
        ↓
Vendor marks ready
        ↓
     [READY]  ← Revenue recorded here
        ↓
Student picks up food
```

---

## Revenue Recording

1. Student places order → Order created with status PENDING
2. Vendor updates status through CONFIRMED → PREPARING → READY
3. When status becomes READY:
   - `VendorService.updateOrderStatus()` calls `revenueService.recordRevenue()`
   - `RevenueEntry` created with gross = net (no commission yet)
   - Daily `RevenueSummary` upserted
4. Dashboard SDUI fetches live stats from revenue module

---

## Payment Flow

```
Student places order
        ↓
    [ORDER CREATED - PAYMENT PENDING]
        ↓
Student initiates payment
        ↓
    [QR CODE GENERATED]
        ↓
Student scans with UPI app (GPay, PhonePe, Paytm)
        ↓
    [PAYMENT COMPLETED]
        ↓
Payment status updates (polling or manual confirm)
```

---

## Future Extension Points

| Feature | Where to Add |
|---------|-------------|
| Commission System | `RevenueEntry.commissionInPaise` column ready, update `recordRevenue()` in revenue module |
| Push Notifications | New module at `src/modules/notifications/` |
| Analytics | New module at `src/modules/analytics/`, admin dashboard integration |
| Payment Refunds | Extend `src/modules/payment/payment.service.ts` |

---

*Last updated: March 2026*
