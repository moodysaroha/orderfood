import { PrismaClient } from '@prisma/client';
import { UserRepository } from './repositories/user.repository';
import { VendorRepository } from './repositories/vendor.repository';
import { StudentRepository } from './repositories/student.repository';
import { MenuItemRepository } from './repositories/menu-item.repository';
import { OrderRepository } from './repositories/order.repository';
import { SduiLayoutRepository } from './repositories/sdui-layout.repository';
import { AuthService } from './services/auth.service';
import { AuthController } from './controllers/auth.controller';
import { SduiController } from './controllers/sdui.controller';
import { VendorController } from './controllers/vendor.controller';
import { StudentController } from './controllers/student.controller';
import { VendorService } from './services/vendor.service';
import { StudentService } from './services/student.service';
import { RevenueRepository, RevenueService, RevenueController } from './modules/revenue';
import { AdminRepository, AdminService, AdminController } from './modules/admin';

export interface Container {
  // Repositories
  userRepository: UserRepository;
  vendorRepository: VendorRepository;
  studentRepository: StudentRepository;
  menuItemRepository: MenuItemRepository;
  orderRepository: OrderRepository;
  sduiLayoutRepository: SduiLayoutRepository;

  // Services
  authService: AuthService;
  revenueService: RevenueService;
  vendorService: VendorService;
  studentService: StudentService;
  adminService: AdminService;

  // Controllers
  authController: AuthController;
  revenueController: RevenueController;
  sduiController: SduiController;
  vendorController: VendorController;
  studentController: StudentController;
  adminController: AdminController;
}

export function createContainer(prisma: PrismaClient): Container {
  // Repositories
  const userRepository = new UserRepository(prisma);
  const vendorRepository = new VendorRepository(prisma);
  const studentRepository = new StudentRepository(prisma);
  const menuItemRepository = new MenuItemRepository(prisma);
  const orderRepository = new OrderRepository(prisma);
  const sduiLayoutRepository = new SduiLayoutRepository(prisma);

  // Revenue module (isolated)
  const revenueRepository = new RevenueRepository(prisma);
  const revenueService = new RevenueService(revenueRepository);
  const revenueController = new RevenueController(revenueService);

  // Admin module (isolated)
  const adminRepository = new AdminRepository(prisma);
  const adminService = new AdminService(adminRepository);
  const adminController = new AdminController(adminService);

  // Services
  const authService = new AuthService(userRepository, vendorRepository, studentRepository);
  const vendorService = new VendorService(menuItemRepository, orderRepository, revenueService);
  const studentService = new StudentService(menuItemRepository, orderRepository, vendorRepository, revenueService);

  // Controllers
  const authController = new AuthController(authService);
  const sduiController = new SduiController(sduiLayoutRepository);
  const vendorController = new VendorController(vendorService, orderRepository, revenueService);
  const studentController = new StudentController(studentService, menuItemRepository, vendorRepository);

  return {
    userRepository,
    vendorRepository,
    studentRepository,
    menuItemRepository,
    orderRepository,
    sduiLayoutRepository,
    authService,
    revenueService,
    vendorService,
    studentService,
    adminService,
    authController,
    revenueController,
    sduiController,
    vendorController,
    studentController,
    adminController,
  };
}
