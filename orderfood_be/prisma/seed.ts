import { PrismaClient, Role, OrderStatus } from '@prisma/client';
import bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding database...');

  await prisma.orderItem.deleteMany();
  await prisma.revenueEntry.deleteMany();
  await prisma.revenueSummary.deleteMany();
  await prisma.order.deleteMany();
  await prisma.menuItem.deleteMany();
  await prisma.sduiLayout.deleteMany();
  await prisma.vendor.deleteMany();
  await prisma.student.deleteMany();
  await prisma.user.deleteMany();

  const passwordHash = await bcrypt.hash('password123', 12);

  // Vendor user
  const vendorUser = await prisma.user.create({
    data: {
      email: 'vendor@orderfood.com',
      passwordHash,
      role: Role.VENDOR,
    },
  });

  const vendor = await prisma.vendor.create({
    data: {
      userId: vendorUser.id,
      restaurantName: 'Campus Bites',
      description: 'Fresh homestyle meals for students',
    },
  });

  // Student users
  const student1User = await prisma.user.create({
    data: { email: 'rahul@student.com', passwordHash, role: Role.STUDENT },
  });
  const student1 = await prisma.student.create({
    data: { userId: student1User.id, name: 'Rahul Sharma' },
  });

  const student2User = await prisma.user.create({
    data: { email: 'priya@student.com', passwordHash, role: Role.STUDENT },
  });
  const student2 = await prisma.student.create({
    data: { userId: student2User.id, name: 'Priya Patel' },
  });

  // Menu items (prices in paise)
  const menuItems = await Promise.all([
    prisma.menuItem.create({
      data: {
        vendorId: vendor.id, name: 'Veg Thali', description: 'Rice, dal, sabzi, roti, salad',
        priceInPaise: 12000, category: 'Thali', sortOrder: 1, isAvailable: true,
      },
    }),
    prisma.menuItem.create({
      data: {
        vendorId: vendor.id, name: 'Paneer Butter Masala', description: 'Creamy paneer curry with butter naan',
        priceInPaise: 15000, category: 'Main Course', sortOrder: 2, isAvailable: true,
      },
    }),
    prisma.menuItem.create({
      data: {
        vendorId: vendor.id, name: 'Chicken Biryani', description: 'Hyderabadi style dum biryani',
        priceInPaise: 18000, category: 'Main Course', sortOrder: 3, isAvailable: true,
      },
    }),
    prisma.menuItem.create({
      data: {
        vendorId: vendor.id, name: 'Masala Dosa', description: 'Crispy dosa with potato filling',
        priceInPaise: 8000, category: 'South Indian', sortOrder: 4, isAvailable: true,
      },
    }),
    prisma.menuItem.create({
      data: {
        vendorId: vendor.id, name: 'Cold Coffee', description: 'Chilled coffee with ice cream',
        priceInPaise: 6000, category: 'Beverages', sortOrder: 5, isAvailable: true,
      },
    }),
    prisma.menuItem.create({
      data: {
        vendorId: vendor.id, name: 'Samosa (2 pcs)', description: 'Crispy potato samosa with chutney',
        priceInPaise: 4000, category: 'Snacks', sortOrder: 6, isAvailable: false,
      },
    }),
  ]);

  // Sample orders
  const order1 = await prisma.order.create({
    data: {
      studentId: student1.id,
      vendorId: vendor.id,
      status: OrderStatus.DELIVERED,
      totalAmountInPaise: 27000,
      items: {
        create: [
          { menuItemId: menuItems[0].id, quantity: 1, priceAtOrderInPaise: 12000 },
          { menuItemId: menuItems[1].id, quantity: 1, priceAtOrderInPaise: 15000 },
        ],
      },
    },
  });

  const order2 = await prisma.order.create({
    data: {
      studentId: student2.id,
      vendorId: vendor.id,
      status: OrderStatus.DELIVERED,
      totalAmountInPaise: 24000,
      items: {
        create: [
          { menuItemId: menuItems[2].id, quantity: 1, priceAtOrderInPaise: 18000 },
          { menuItemId: menuItems[4].id, quantity: 1, priceAtOrderInPaise: 6000 },
        ],
      },
    },
  });

  const order3 = await prisma.order.create({
    data: {
      studentId: student1.id,
      vendorId: vendor.id,
      status: OrderStatus.PENDING,
      totalAmountInPaise: 8000,
      items: {
        create: [
          { menuItemId: menuItems[3].id, quantity: 1, priceAtOrderInPaise: 8000 },
        ],
      },
    },
  });

  // Revenue entries for delivered orders
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  await prisma.revenueEntry.create({
    data: {
      vendorId: vendor.id, orderId: order1.id,
      grossAmountInPaise: 27000, commissionInPaise: 0, netAmountInPaise: 27000,
    },
  });

  await prisma.revenueEntry.create({
    data: {
      vendorId: vendor.id, orderId: order2.id,
      grossAmountInPaise: 24000, commissionInPaise: 0, netAmountInPaise: 24000,
    },
  });

  await prisma.revenueSummary.create({
    data: {
      vendorId: vendor.id,
      date: today,
      totalOrderCount: 2,
      grossRevenueInPaise: 51000,
      totalCommissionInPaise: 0,
      netRevenueInPaise: 51000,
    },
  });

  console.log('Seed complete!');
  console.log(`  Vendor: vendor@orderfood.com / password123`);
  console.log(`  Student 1: rahul@student.com / password123`);
  console.log(`  Student 2: priya@student.com / password123`);
  console.log(`  Menu items: ${menuItems.length}`);
  console.log(`  Orders: 3 (2 delivered, 1 pending)`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
