export interface PlatformStats {
  totalVendors: number;
  totalStudents: number;
  totalOrders: number;
  totalRevenueInPaise: number;
  ordersToday: number;
  revenueToday: number;
}

export interface PlatformStatsFormatted {
  totalVendors: number;
  totalStudents: number;
  totalOrders: number;
  totalRevenue: string;
  ordersToday: number;
  revenueToday: string;
}

export interface VendorWithStats {
  id: string;
  restaurantName: string;
  description: string | null;
  email: string;
  totalOrders: number;
  totalRevenue: number;
  createdAt: Date;
}

export interface StudentWithStats {
  id: string;
  name: string;
  email: string;
  totalOrders: number;
  totalSpent: number;
  createdAt: Date;
}

export interface OrderWithDetails {
  id: string;
  studentName: string;
  studentEmail: string;
  vendorName: string;
  status: string;
  totalAmountInPaise: number;
  itemCount: number;
  createdAt: Date;
}
