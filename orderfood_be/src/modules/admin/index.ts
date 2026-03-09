export { AdminService, type IAdminService } from './admin.service';
export { AdminRepository, type IAdminRepository } from './admin.repository';
export { AdminController } from './admin.controller';
export { createAdminRoutes } from './admin.routes';
export type {
  PlatformStats,
  PlatformStatsFormatted,
  VendorWithStats,
  StudentWithStats,
  OrderWithDetails,
  BulkVendorInput,
  BulkMenuItemInput,
  BulkUploadResult,
} from './admin.types';
