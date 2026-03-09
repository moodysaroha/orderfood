# OrderFood - Campus Food Ordering App

## What is OrderFood?

OrderFood is a mobile app built for campus food vendors and students. It lets vendors manage their restaurant menu and track orders, while students can browse available food, place orders, and track their order status -- all from a single app.

The app uses **Server-Driven UI (SDUI)**, which means the app's screens and layouts are controlled from the server. This allows the development team to update what the app looks like, add new features, or rearrange screens **without requiring users to download an app update**.

---

## Who uses this app?

### 1. Restaurant Vendors

Vendors are campus food sellers who use the app to run their food business digitally.

**What vendors can do:**

- **View a Dashboard** showing real-time business stats:
  - Total orders received today
  - Revenue earned today (in INR)
  - Total lifetime revenue since joining
  - A list of recent orders
- **Manage their Menu:**
  - Add new food items with name, description, price, and category
  - Upload photos of each dish directly from the app
  - Mark items as "Sold Out" when stock runs out
  - Bring items "Back in Stock" with a single tap
  - Edit prices, descriptions, or remove items entirely
- **Manage Orders:**
  - See all incoming orders from students
  - Update order status step by step: Confirmed, Preparing, Ready
  - Cancel orders if needed
  - Revenue is recorded when order reaches Ready status

### 2. Students

Students are the customers who browse menus and order food.

**What students can do:**

- **Browse Multiple Restaurants:**
  - View all available campus restaurants
  - See each restaurant's menu item count
  - Tap to browse a specific restaurant's menu
- **Browse the Menu** of available campus vendors
  - See food items with photos, descriptions, and prices
  - Menu updates instantly when a vendor marks something as sold out (no refresh needed)
- **Place Orders:**
  - Select items and quantities
  - Place the order with a single tap
- **Pay with QR Code:**
  - Generate UPI QR code for any order
  - Scan QR code with any UPI app (GPay, PhonePe, Paytm, etc.)
  - Open UPI app directly from the payment screen
  - Payment status automatically updates
- **Track Orders:**
  - View order history with payment status
  - See current status of each order (Pending, Confirmed, Preparing, Ready)
  - Come to restaurant when order is Ready to pick up food

### 3. Admin (Platform Owner)

The admin dashboard gives the platform owner/developer full visibility into the system.

**What admins can do:**

- **View Platform Stats:**
  - Total vendors, students, and orders
  - Revenue today and total revenue
- **Manage Vendors:**
  - View all registered vendors with their stats
  - Delete vendors and their associated data
  - Bulk upload vendors with menu items via JSON
- **Manage Students:**
  - View all registered students with their order history
  - Delete students and their associated data
- **View All Orders:**
  - See all orders across all vendors
  - Filter orders by status

---

## How the Revenue System Works

All revenue tracking is based on **real order data** -- nothing is hardcoded or estimated.

- When a vendor marks an order as "Ready", the order total is automatically recorded as revenue
- The dashboard shows live numbers pulled from the database
- All prices are in **Indian Rupees (INR)**
- The system is designed to support **future payment features** like QR code payments and platform commission, without needing to change how orders or menus work

---

## Key Features Summary


| Feature                                  | Vendor | Student |
| ---------------------------------------- | ------ | ------- |
| Dashboard with live stats                | Yes    | --      |
| Menu management                          | Yes    | --      |
| Photo upload for dishes                  | Yes    | --      |
| Mark items sold out / in stock           | Yes    | --      |
| Browse multiple restaurants              | --     | Yes     |
| Browse menu                              | --     | Yes     |
| Place orders                             | --     | Yes     |
| QR Code payments (UPI)                   | --     | Yes     |
| Order history                            | Yes    | Yes     |
| Order status tracking                    | Yes    | Yes     |
| Payment status tracking                  | Yes    | Yes     |
| Logout from app                          | Yes    | Yes     |
| Light/Dark theme support                 | Yes    | Yes     |
| Revenue tracking (INR)                   | Yes    | --      |
| Server-driven UI (no app updates needed) | Yes    | Yes     |


---

## Currency

All prices and revenue figures are displayed in **Indian Rupees (INR)**. For example:

- Veg Thali: Rs 120
- Paneer Butter Masala: Rs 150
- Chicken Biryani: Rs 180

---

## Future Roadmap

The following features are planned for future releases:

- **Platform Commission** -- A percentage-based commission system for the platform owner
- **Push Notifications** -- Real-time alerts for order status changes
- **Order Analytics** -- Detailed analytics for vendors and admins

## Admin Credentials

After running the database seed, use these credentials to access the admin dashboard:

- **Email:** admin@orderfood.com
- **Password:** password123 
