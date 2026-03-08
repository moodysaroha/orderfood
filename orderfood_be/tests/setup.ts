import { PrismaClient } from '@prisma/client';
import { createApp } from '../src/app';
import { Express } from 'express';

let prisma: PrismaClient;
let app: Express;

export function getApp(): Express {
  if (!app) {
    const result = createApp();
    app = result.app;
  }
  return app;
}

export function getPrisma(): PrismaClient {
  if (!prisma) {
    prisma = new PrismaClient();
  }
  return prisma;
}

export async function cleanDatabase(): Promise<void> {
  const p = getPrisma();
  await p.orderItem.deleteMany();
  await p.revenueEntry.deleteMany();
  await p.revenueSummary.deleteMany();
  await p.order.deleteMany();
  await p.menuItem.deleteMany();
  await p.sduiLayout.deleteMany();
  await p.vendor.deleteMany();
  await p.student.deleteMany();
  await p.user.deleteMany();
}

export async function disconnectDatabase(): Promise<void> {
  if (prisma) {
    await prisma.$disconnect();
  }
}
